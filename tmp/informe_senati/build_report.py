from copy import deepcopy
from pathlib import Path
from zipfile import ZipFile
from io import BytesIO
import hashlib
import json
import math
import textwrap

from lxml import etree as E
from PIL import Image, ImageDraw, ImageFont
from docx import Document
from docx.shared import Inches

from report_content import *

ROOT = Path(r'C:/idaw4/Flutter/Entregable')
WORK = Path(__file__).resolve().parent
OUT = ROOT/'docs/informe'
FIG = OUT/'figuras'
FIG.mkdir(exist_ok=True)
SOURCE = Path(r'C:/Users/user/Downloads/PAWD-403_FORMATOALUMNOTRABAJOFINAL.docx')
FINAL = OUT/'PAWD-403_INFORME_FINAL_ENFOQUE.docx'
SOURCE_HASH = '912e3d8e2e372e36171bd728f68c67ff6256774b6c991e7f3f23e7c46111731b'
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == SOURCE_HASH

NS = {'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
      'r':'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
      'wp':'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
      'a':'http://schemas.openxmlformats.org/drawingml/2006/main',
      'pic':'http://schemas.openxmlformats.org/drawingml/2006/picture',
      'w14':'http://schemas.microsoft.com/office/word/2010/wordml',
      'v':'urn:schemas-microsoft-com:vml'}
def q(tag):
    pre, local = tag.split(':')
    return '{'+NS[pre]+'}'+local
def node(tag, **attrs):
    x=E.Element(q(tag))
    for k,v in attrs.items():
        x.set(q('w:'+k),str(v))
    return x

with ZipFile(SOURCE) as z:
    original = {i.filename:z.read(i.filename) for i in z.infolist()}
    zipinfos = z.infolist()
root=E.fromstring(original['word/document.xml'])
body=root.find('w:body',NS)
ps=body.findall('w:p',NS)
tables=body.findall('w:tbl',NS)
rels=E.fromstring(original['word/_rels/document.xml.rels'])
settings=E.fromstring(original['word/settings.xml'])
types=E.fromstring(original['[Content_Types].xml'])
added={}
picture_id=5000
para_id=0x72000000

def eltext(x):
    return ''.join(x.xpath('.//w:t/text()',namespaces=NS))

def font(name='Arial', size=10, bold=False, color='000000'):
    rpr=node('w:rPr')
    rf=node('w:rFonts'); rf.set(q('w:ascii'),name);rf.set(q('w:hAnsi'),name);rf.set(q('w:cs'),name);rpr.append(rf)
    rpr.append(node('w:sz',val=round(size*2)));rpr.append(node('w:szCs',val=round(size*2)))
    rpr.append(node('w:color',val=color))
    if bold: rpr.append(node('w:b'))
    rpr.append(node('w:lang',val='es-PE'))
    return rpr

def paragraph(text='', *, bold=False, size=10, align='left', after=100, before=0, keep=False, style=None):
    p=node('w:p')
    pr=node('w:pPr')
    if style: pr.append(node('w:pStyle',val=style))
    pr.append(node('w:jc',val=align))
    pr.append(node('w:spacing',before=before,after=after,line=240,lineRule='auto'))
    if keep: pr.append(node('w:keepNext'))
    p.append(pr)
    r=node('w:r'); r.append(font(size=size,bold=bold))
    for i,line in enumerate(text.split('\n')):
        if i: r.append(node('w:br'))
        t=node('w:t');t.set('{http://www.w3.org/XML/1998/namespace}space','preserve');t.text=line;r.append(t)
    p.append(r)
    return p

def replace_cell(cell, texts, *, bold=False,size=10,align='left',after=35):
    for child in list(cell):
        if child.tag != q('w:tcPr'): cell.remove(child)
    if isinstance(texts,str): texts=[texts]
    for t in texts: cell.append(paragraph(t,bold=bold,size=size,align=align,after=after))
    pr=cell.find('w:tcPr',NS)
    if pr is None: pr=node('w:tcPr');cell.insert(0,pr)
    old=pr.find('w:vAlign',NS)
    if old is None: old=node('w:vAlign');pr.append(old)
    old.set(q('w:val'),'center')

def tc(table, row, col=0):
    return table.findall('w:tr',NS)[row].findall('w:tc',NS)[col]

def row_height(row, twips):
    pr=row.find('w:trPr',NS)
    if pr is None: pr=node('w:trPr');row.insert(0,pr)
    h=pr.find('w:trHeight',NS)
    if h is None: h=node('w:trHeight');pr.append(h)
    h.set(q('w:val'),str(twips));h.set(q('w:hRule'),'atLeast')

def fresh_ids(x):
    global picture_id,para_id
    mapping={}
    for z in x.iter():
        if z.tag==q('wp:docPr') or z.tag==q('pic:cNvPr'):
            picture_id+=1;z.set('id',str(picture_id));z.set('name',f'Enfoque {picture_id}')
        if q('w14:paraId') in z.attrib:
            para_id+=1;z.set(q('w14:paraId'),f'{para_id:08X}')
        for a,v in list(z.attrib.items()):
            if v.startswith('_x0000_s'):
                if v not in mapping:
                    picture_id+=1;mapping[v]=f'_x0000_s{picture_id}'
                z.set(a,mapping[v])
    return x

def banner(label):
    x=fresh_ids(deepcopy(ps[110]))
    for box in x.xpath('.//w:txbxContent',namespaces=NS):
        first=box.find('w:p',NS)
        for child in list(first):
            if child.tag != q('w:pPr'):first.remove(child)
        run=node('w:r');run.append(font(size=16,bold=True,color='FFFFFF'))
        text=node('w:t');text.text=label;run.append(text);first.append(run)
    return x

def break_page():
    p=paragraph('',after=0)
    p.find('w:r',NS).append(node('w:br',type='page'))
    return p

def picture(path,width=6.0):
    global picture_id
    path=Path(path)
    helper=Document()
    helper.add_paragraph().add_run().add_picture(str(path),width=Inches(width))
    p=E.fromstring(E.tostring(helper.paragraphs[-1]._p))
    ppr=p.find('w:pPr',NS)
    if ppr is None: ppr=node('w:pPr');p.insert(0,ppr)
    ppr.append(node('w:jc',val='center'));ppr.append(node('w:spacing',after=50))
    embed=p.xpath('.//a:blip',namespaces=NS)[0]
    relationship=f'rIdEnfoque{len(added)+100}'
    media=f'word/media/enfoque_{len(added)+100}{path.suffix.lower()}'
    added[media]=path.read_bytes()
    rel=E.SubElement(rels,'{http://schemas.openxmlformats.org/package/2006/relationships}Relationship')
    rel.set('Id',relationship);rel.set('Type',NS['r']+'/image');rel.set('Target',media.removeprefix('word/'))
    embed.set(q('r:embed'),relationship)
    fresh_ids(p)
    for docpr in p.xpath('.//wp:docPr',namespaces=NS):docpr.set('descr',path.stem.replace('_',' '))
    ext=path.suffix.lower().lstrip('.')
    if not any(t.get('Extension')==ext for t in types):
        d=E.SubElement(types,'{http://schemas.openxmlformats.org/package/2006/content-types}Default')
        d.set('Extension',ext);d.set('ContentType','image/jpeg' if ext in ('jpg','jpeg') else 'image/png')
    return p

# Draw reproducible technical diagrams, using no generative image service.
FONTS=Path('C:/Windows/Fonts')
def ft(size=42,bold=False):
    return ImageFont.truetype(str(FONTS/('arialbd.ttf' if bold else 'arial.ttf')),size)
BLUE='#173B8B';PALE='#E8EFF9';INK='#17283D';GREY='#6B7789'
def canvas(title):
    im=Image.new('RGB',(1800,920),'white');d=ImageDraw.Draw(im)
    d.text((36,18),title,font=ft(44,True),fill=BLUE)
    return im,d
def wrap_pixels(d,text,maxwidth,font):
    lines=[]
    for source_line in text.split('\n'):
        current=''
        for word in source_line.split():
            nxt=(current+' '+word).strip()
            if current and d.textlength(nxt,font=font)>maxwidth:lines.append(current);current=word
            else:current=nxt
        lines.append(current)
    return lines
def box(d,xy,text,bold=True,size=40):
    x,y,w,h=xy;d.rounded_rectangle((x,y,x+w,y+h),radius=16,fill=PALE,outline=BLUE,width=3)
    f=ft(size,bold);lines=wrap_pixels(d,text,w-38,f);lineh=size+10
    yy=y+(h-lineh*len(lines))/2
    for line in lines:
        xx=x+(w-d.textlength(line,font=f))/2;d.text((xx,yy),line,font=f,fill=INK);yy+=lineh
def arrow(d,a,b,label=None):
    d.line([a,b],fill=BLUE,width=5)
    ang=math.atan2(b[1]-a[1],b[0]-a[0]);z=17
    head=[b,(b[0]-z*math.cos(ang-.5),b[1]-z*math.sin(ang-.5)),(b[0]-z*math.cos(ang+.5),b[1]-z*math.sin(ang+.5))]
    d.polygon(head,fill=BLUE)
    if label:
        f=ft(33);x=(a[0]+b[0])/2-d.textlength(label,font=f)/2;y=(a[1]+b[1])/2-44
        d.rectangle((x-9,y-3,x+d.textlength(label,font=f)+9,y+38),fill='white');d.text((x,y),label,font=f,fill=INK)
def note(d,text,y=830):
    for i,line in enumerate(wrap_pixels(d,text,1720,ft(34))):d.text((38,y+i*41),line,font=ft(34),fill=GREY)
def save(im,name):
    target=FIG/f'{name}.png';im.save(target,optimize=True);return target

im,d=canvas('Arquitectura de Enfoque')
nodes=[(40,140,480,180),(660,140,480,180),(1280,140,480,180),(40,500,480,180),(660,500,480,180),(1280,500,480,180)]
for xy,t in zip(nodes,['Pantallas Flutter\nInteracción y navegación','TaskController\nEstado y streams','FirestoreTaskRepository\nCRUD por uid','SessionGate + Auth\nIdentidad de la cuenta','Preferences\nTema y persistencia local','Cloud Firestore\nDatos y reglas por usuario']):box(d,xy,t)
for a,b in [((520,230),(660,230)),((1140,230),(1280,230)),((1520,320),(1520,500)),((280,500),(280,320)),((900,500),(900,320)),((1140,590),(1280,590))]:arrow(d,a,b)
note(d,'Recordatorios: TaskController coordina LocalReminders, zona horaria y solicitudes nativas Android / iOS.')
architecture=save(im,'arquitectura')

im,d=canvas('Estructura de Cloud Firestore')
box(d,(630,100,540,140),'users/{uid}\ncreatedAt',size=40)
cols=[(30,345,550,430),(625,345,550,430),(1220,345,550,430)]
for xy,t in zip(cols,['tasks/{taskId}\nTítulo y descripción\nCategoría y fecha\nPrioridad y estado\nRecordatorio\ncreatedAt / updatedAt','categories/{categoryId}\nname\narchived\nupdatedAt\n\nArchivado conserva vínculos','preferences/interface\ndark\naccent\nnotifications\n\nUn documento por cuenta']):box(d,xy,t,bold=False,size=38)
for x in [305,900,1495]:arrow(d,(900,240),(x,345))
note(d,'Acceso permitido únicamente si request.auth.uid coincide con el uid de la ruta. Fechas con Timestamp.')
database=save(im,'firestore')

im,d=canvas('Flujo de creación de tareas')
seq=[((40,160,500,180),'Abrir Nueva tarea'),((650,160,500,180),'Completar título\ny campos opcionales'),((1260,160,500,180),'Validar título, fecha\ny recordatorio'),((1260,520,500,180),'Escribir en Firestore\nSnapshot local pendiente'),((650,520,500,180),'Recibir confirmación\ndel servidor'),((40,520,500,180),'Mostrar Cambios guardados\ny cerrar formulario')]
for xy,t in seq:box(d,xy,t)
for a,b in [((540,250),(650,250)),((1150,250),(1260,250)),((1510,340),(1510,520)),((1260,610),(1150,610)),((650,610),(540,610))]:arrow(d,a,b)
note(d,'Si hay datos inválidos se conserva el formulario. Sin conexión, la escritura puede seguir pendiente de confirmación.')
create_flow=save(im,'crear_tarea')

im,d=canvas('Sincronización entre dos sesiones')
for x,t in [(80,'Dispositivo A'),(680,'Firestore + reglas'),(1280,'Dispositivo B')]:
    box(d,(x,110,440,120),t)
    d.line((x+220,230,x+220,810),fill='#B7C6DB',width=4)
arrow(d,(300,315),(900,315),'Crear o editar')
arrow(d,(900,430),(300,430),'Confirmar escritura')
arrow(d,(900,525),(1500,525),'Snapshot actualizado')
arrow(d,(1500,635),(900,635),'Cambiar estado')
arrow(d,(900,735),(300,735),'Snapshot actualizado')
note(d,'Con una interrupción de red, A conserva cambios en caché y los envía al reconectar. Se probó en emuladores.')
sync_flow=save(im,'sincronizacion')

im,d=canvas('Flujo de recordatorios locales')
seq=[((40,150,500,180),'Recibir tareas o\npreferencias actualizadas'),((650,150,500,180),'Filtrar futuras, pendientes\ny con aviso activado'),((1260,150,500,180),'Ordenar y tomar\nlas primeras 60'),((1260,520,500,180),'Comparar la firma\ndel plan anterior'),((650,520,500,180),'Si cambió: cancelar\nsolicitudes anteriores'),((40,520,500,180),'Convertir a zona local\ny programar avisos')]
for xy,t in seq:box(d,xy,t)
for a,b in [((540,240),(650,240)),((1150,240),(1260,240)),((1510,330),(1510,520)),((1260,610),(1150,610)),((650,610),(540,610))]:arrow(d,a,b)
note(d,'Completar, borrar, desactivar o salir cancela el plan correspondiente. Sin cambios se conserva. No hay servidor FCM.')
reminder_flow=save(im,'recordatorios')

im,d=canvas('Navegación de la aplicación')
box(d,(40,100,500,150),'Bienvenida y acceso')
box(d,(650,100,500,150),'Inicio y barra inferior')
box(d,(1260,100,500,150),'Configuración')
arrow(d,(540,175),(650,175),'Sesión')
arrow(d,(1150,175),(1260,175))
for x,t in [(40,'Mis tareas'),(650,'Calendario'),(1260,'Avance')]:
    box(d,(x,440,500,150),t)
    arrow(d,(900,250),(x+250,440))
box(d,(40,710,1110,130),'Hoja Crear / editar tarea')
box(d,(1260,710,500,130),'Categorías')
arrow(d,(290,590),(290,710));arrow(d,(900,590),(900,710))
d.line([(1510,250),(1780,250),(1780,775)],fill=BLUE,width=5)
arrow(d,(1780,775),(1760,775))
navigation=save(im,'navegacion')

# Fill source slots without round-tripping the retained package through Word.
values=[(0,1,STUDENT['name']),(0,3,STUDENT['id']),(1,1,STUDENT['cfp']),
        (2,1,STUDENT['career']),(2,3,STUDENT['semester']),(3,1,COURSE),(4,1,TOPIC)]
for row,col,text in values:replace_cell(tc(tables[0],row,col),text)

boxes=root.xpath('//w:txbxContent',namespaces=NS)
for idx,content in [(2,PROBLEM),(3,PROBLEM),(4,SOLUTION),(5,SOLUTION)]:
    boxroot=boxes[idx]
    for child in list(boxroot):boxroot.remove(child)
    for text in content:boxroot.append(paragraph(text,size=10,after=100,align='both'))

for i,(question,answer) in enumerate(QUESTIONS):
    replace_cell(tc(tables[1],2*i,1),question,size=10,bold=True)
    replace_cell(tc(tables[1],2*i+1,0),answer,size=10,after=35,align='both')
    row_height(tables[1].findall('w:tr',NS)[2*i+1],980)

# Start the complete guide-question block together on its own page.
ps[52].find('w:pPr',NS).append(node('w:pageBreakBefore'))

for i in range(6):replace_cell(tc(tables[2],1,i+2),f'E{i+1}',bold=True,align='center',after=0)
activities=['Análisis del caso y entorno','Diseño y arquitectura','Firebase y gestión de tareas','Calendario, temas y avisos','Pruebas y correcciones','Informe, diagramas y APK']
for i,activity in enumerate(activities):
    row=i+2;replace_cell(tc(tables[2],row,0),str(i+1),align='center');replace_cell(tc(tables[2],row,1),activity)
    for j in range(6):replace_cell(tc(tables[2],row,j+2),'X' if i==j else '',align='center')
new_note=paragraph('Secuencia de las actividades realizadas el 14/11/2026. E1-E6 son etapas; no representan horas medidas.',size=9,after=0)
ps[62].getparent().replace(ps[62],new_note)

resources=[
    [('PC Windows con Android SDK 36','1 utilizado'),('Emulador Android Pixel 6','1 utilizado'),('Mac con Xcode (pendiente)','1 requerido'),('Teléfono físico (pendiente)','1 requerido')],
    [('Flutter, Dart y Android SDK','1 conjunto'),('Firebase CLI y Emulator Suite','1 conjunto'),('Editor de código y navegador','1 conjunto'),('Word y Python para el informe','1 conjunto')],
    [('Código y archivos de configuración','1 proyecto'),('Fotografía Unsplash y licencia','1 fotografía'),('Manrope y licencia OFL','1 familia'),('Pruebas, capturas y documentación','1 paquete')],
]
for table,items in zip(tables[3:6],resources):
    for r,(desc,qty) in enumerate(items,2):
        replace_cell(tc(table,r,0),desc,size=10,after=0);replace_cell(tc(table,r,1),qty,size=10,align='center',after=0)

propcell=tc(tables[6],1,0)
replace_cell(propcell,[],size=10)
propcell.find('w:tcPr/w:vAlign',NS).set(q('w:val'),'top')
for heading,text in PROPOSAL:
    propcell.append(paragraph(heading,bold=True,size=10,after=35,before=80,keep=True))
    propcell.append(paragraph(text,size=10,after=80,align='both'))
row_height(tables[6].findall('w:tr',NS)[1],11400)

rows=tables[7].findall('w:tr',NS)
for i,(operation,standard) in enumerate(OPERATIONS,1):
    replace_cell(tc(tables[7],i,0),operation,size=10,after=30)
    replace_cell(tc(tables[7],i,1),standard,size=10,after=30)
    pr=rows[i].find('w:trPr',NS)
    if pr is not None:pr.append(node('w:cantSplit'))
for row in rows[len(OPERATIONS)+1:]:tables[7].remove(row)

diagramcell=tc(tables[8],0,0)
replace_cell(diagramcell,[],size=10)
diagramcell.append(paragraph('Arquitectura y organización de datos',bold=True,size=11,after=80))
diagramcell.append(picture(architecture,width=6.0))
diagramcell.append(paragraph('La identidad delimita el repositorio. Los controladores coordinan la presentación, Firestore y los avisos.',size=10,after=150))
diagramcell.append(picture(database,width=6.0))
diagramcell.append(paragraph('Las categorías se archivan. Los tiempos de creación y actualización provienen del servidor.',size=10,after=30))
replace_cell(tc(tables[8],1,1),'Enfoque - gestión de tareas',align='center',size=10)
replace_cell(tc(tables[8],2,1),STUDENT['name'],align='center',size=10)
replace_cell(tc(tables[8],2,2),'Sin escala',align='center',size=10)

sdts=tables[9].xpath('.//w:sdt',namespaces=NS)
assert len(sdts)==20
for item in range(10):
    complies = item not in (1,)
    for col in range(2):
        sdt=sdts[2*item+col]
        checked=(col==0)==complies
        state=sdt.find('.//w14:checked',NS)
        state.set(q('w14:val'),'1' if checked else '0')
        texts=sdt.xpath('.//w:t',namespaces=NS)
        if texts:texts[0].text='☒' if checked else '☐'
control_note=paragraph('Cumplimiento integral pendiente: archivo Figma/Adobe XD editable, nube de producción, validación iOS y recepción real de avisos. El cronograma documenta la secuencia realizada, sin tiempos medidos.',size=9,after=0)
body.insert(body.index(ps[109]),control_note)
for row in range(1,6):replace_cell(tables[10].findall('w:tr',NS)[row].findall('w:tc',NS)[-1],'Pendiente',align='center',size=10)

# Annexes use the retained section geometry and the source banner component.
annex=[]
def page(label):
    annex.extend([break_page(),banner(label),paragraph('',after=60)])
def heading(text):annex.append(paragraph(text,bold=True,size=11,before=100,after=60,keep=True))
def prose(text):annex.append(paragraph(text,size=10,after=130,align='both'))

for label,sections in ANNEX_TEXT:
    page(label)
    for h,t in sections:
        heading(h)
        if h=='Ejecución local':annex.append(paragraph(t,size=10,after=130))
        else:prose(t)

for label,figs in [
    ('9. FLUJOS DE TAREAS',[(create_flow,'Creación y validación de una tarea.'),(sync_flow,'Actualización A/B mediante streams de Firestore.')]),
    ('10. AVISOS Y NAVEGACIÓN',[(reminder_flow,'Reconciliación de solicitudes locales; la entrega requiere permisos y validación física.'),(navigation,'Cinco destinos principales, editor modal y gestión de categorías.')]),
]:
    page(label)
    for path,caption in figs:
        annex.append(picture(path,width=6.0));annex.append(paragraph(caption,size=10,after=180))

def pair_table(images):
    # Reuse two-column source grid and borders; a fresh cell body contains each figure.
    t=deepcopy(tables[3]);pr=t.find('w:tblPr',NS)
    floating=pr.find('w:tblpPr',NS)
    if floating is not None:pr.remove(floating)
    # Gallery is a pair of figures, so remove its tabular frame and title rows.
    borders=pr.find('w:tblBorders',NS)
    if borders is not None:pr.remove(borders)
    borders=node('w:tblBorders')
    for side in ['top','left','bottom','right','insideH','insideV']:borders.append(node('w:'+side,val='nil'))
    pr.append(borders)
    for row in list(t.findall('w:tr',NS)):t.remove(row)
    grid=t.find('w:tblGrid',NS)
    for c in list(grid):grid.remove(c)
    for _ in range(2):grid.append(node('w:gridCol',w=4300))
    tr=node('w:tr');t.append(tr)
    for path,title,description in images:
        c=node('w:tc');cp=node('w:tcPr');cp.append(node('w:tcW',w=4300,type='dxa'));c.append(cp)
        c.append(paragraph(title,bold=True,size=11,align='center',after=110))
        c.append(picture(path,width=2.5))
        c.append(paragraph(description,size=10,after=80))
        tr.append(c)
    return t

gallery=[
    ('11. DISEÑO DE INTERFAZ I',[('bienvenida','Bienvenida','Acceso y registro con fotografía local.'),('inicio','Inicio','Fecha, resumen y tareas agrupadas por día.')]),
    ('12. DISEÑO DE INTERFAZ II',[('tareas','Mis tareas','Búsqueda, filtros, orden y estado.'),('crear','Crear y editar','Campos validados y recordatorio opcional.')]),
    ('13. DISEÑO DE INTERFAZ III',[('categorias','Categorías','Archivado y restauración sin borrar tareas.'),('calendario','Calendario','Selección de día e indicadores de tareas.')]),
    ('14. DISEÑO DE INTERFAZ IV',[('estadisticas','Avance','Indicadores derivados de datos de prueba.'),('configuracion','Configuración','Perfil, apariencia y notificaciones.')]),
]
for label,pair in gallery:
    page(label)
    prose('Referencias exportables renderizadas desde los widgets a 390 x 844, con datos explícitos de prueba. No son capturas de un teléfono conectado ni un archivo editable de Figma. La guía de reconstrucción está en docs/prototipo/README.md.')
    annex.append(pair_table([(ROOT/'docs/prototipo'/f'{name}.png',title,desc) for name,title,desc in pair]))

page('15. EVIDENCIA ANDROID')
prose('Captura real del Pixel 6 virtual conectado a Firebase Emulator Suite. La tarea “Revisar la entrega final” fue creada por la prueba y no pertenece a una cuenta de producción. La etiqueta EMULADOR identifica el entorno.')
annex.append(picture(ROOT/'docs/evidencias/android-inicio.png',width=2.5))
prose('La integración verificó registro, dos instancias FlutterFire, edición, cambio de estado, eliminación, cierre desde Configuración y nuevo acceso. El plugin nativo devolvió una solicitud pendiente al programar y cero al completar o quitar la tarea. Esto no demuestra que el sistema entregue el aviso con la aplicación cerrada.')

page('16. CORRECCIÓN DEL TEMA')
prose('Captura real de la versión web con Firebase local después de corregir el bloqueo del modo oscuro. Se comprobó oscuro → claro → oscuro y la navegación entre Ajustes y Tareas, conservando la tarea existente. No se observaron errores de consola durante esa comprobación.')
annex.append(picture(ROOT/'docs/evidencias/web-tema-corregido.jpg',width=6.0))
heading('Causa y solución')
prose('Al cambiar el tema se recreaba el stream de Authentication dentro de la reconstrucción de MaterialApp. Workspace se desmontaba, volvía a suscribir preferencias y el primer snapshot reiniciaba el ciclo. SessionGate conserva el stream en su State; la vista de sesión se conserva como child del ListenableBuilder. Preferences omite eventos con los mismos valores.')
heading('Regresión incorporada')
prose('Dos pruebas adicionales verifican actualizaciones idénticas sin reconstrucción y seis cambios de tema/acento con una sola suscripción, una sola creación del espacio de trabajo y conservación del borrador. La suite final registra 18 pruebas aprobadas y el análisis no presenta observaciones. El APK se recompiló; la integración Android anterior no se volvió a ejecutar para este ajuste.')

page('17. RESULTADOS Y LÍMITES')
results=[
    ('Dependencias, formato y análisis','Aprobado','pub get, dart format y flutter analyze sin observaciones.'),
    ('Unitarias y widgets Flutter','18 aprobadas','Validación, CRUD, filtros, temas, avisos, errores y layout.'),
    ('Firebase Emulator Suite','7 aprobados','Reglas, categorías, Auth, A/B y reconexión.'),
    ('Integración Android virtual','1 escenario aprobado','CRUD sincronizado y solicitudes nativas; cuenta +2 incluye tearDownAll.'),
    ('APK de aplicación normal','Compilado','dist/enfoque-emuladores-debug.apk, entrada lib/main.dart.'),
    ('iOS y teléfonos físicos','No ejecutado','Requiere Mac, Xcode, firma y dispositivos.'),
    ('Entrega de notificaciones','Validación manual','Permisos, pantalla bloqueada, app cerrada y reinicio.'),
    ('Prototipo editable Figma/XD','Pendiente','Referencias PNG y guía disponibles; no se creó el archivo editable.'),
]
def data_table(headers, rows, widths):
    t=node('w:tbl');pr=node('w:tblPr');pr.append(node('w:tblW',w=sum(widths),type='dxa'));pr.append(node('w:tblLayout',type='fixed'))
    b=node('w:tblBorders')
    for side in ['top','left','bottom','right','insideH','insideV']:b.append(node('w:'+side,val='single',sz=4,color='D9D9D9'))
    pr.append(b);t.append(pr);grid=node('w:tblGrid')
    for width in widths:grid.append(node('w:gridCol',w=width))
    t.append(grid)
    for ri,record in enumerate([headers]+rows):
        tr=node('w:tr');rp=node('w:trPr');rp.append(node('w:cantSplit'))
        if ri==0:rp.append(node('w:tblHeader'))
        tr.append(rp)
        for width,text in zip(widths,record):
            c=node('w:tc');cp=node('w:tcPr');cp.append(node('w:tcW',w=width,type='dxa'));cp.append(node('w:vAlign',val='center'))
            margins=node('w:tcMar')
            for side in ['top','bottom','left','right']:margins.append(node('w:'+side,w=90,type='dxa'))
            cp.append(margins)
            if ri==0:cp.append(node('w:shd',fill='C8D9EE'))
            c.append(cp);c.append(paragraph(str(text),bold=ri==0,size=10,after=20));tr.append(c)
        t.append(tr)
    return t
annex.append(data_table(['Comprobación','Resultado','Evidencia y alcance'],results,[2400,1800,4400]))
heading('Registros que sustentan el informe')
prose('docs/evidencias conserva flutter-tests.txt, flutter-analyze.txt, firebase-tests.txt, android-integration.txt y android-build.txt. El fallo inicial de GMT se conserva por separado. Las pruebas de Firebase usan cuentas desechables; el doble de repositorio solo aparece en test/. No se presentan los servicios emulados como una nube de producción.')
heading('Guion manual entre A y B')
prose('Abrir dos sesiones con la misma cuenta; crear una tarea en A; comprobar que aparece en B; editar título en B; completar en A y comprobar el estado en B. Desconectar A, modificar y observar pendiente; reconectar y verificar actualización. Repetir en dos teléfonos y con otra cuenta para comprobar aislamiento. El guion completo está en docs/CONFIGURACION_FIREBASE.md.')

page('18. CONCLUSIONES Y FUENTES')
for h,t in FINAL_NOTES:heading(h);prose(t)
heading('Fuentes y recursos')
for ref in REFERENCES:annex.append(paragraph(ref,size=9,after=65))
annex.append(paragraph('Fecha de documentación y comprobaciones: 14 de noviembre de 2026. La fotografía de bienvenida y Manrope se distribuyen localmente con procedencia en docs/RECURSOS_VISUALES.md; la licencia OFL está en assets/fonts/OFL.txt.',size=9,after=0))

insertion=body.index(ps[112])
for offset,x in enumerate(annex):body.insert(insertion+offset,x)

update=settings.find('w:updateFields',NS)
if update is None:update=node('w:updateFields');settings.append(update)
update.set(q('w:val'),'true')

def serialize(x):return E.tostring(x,encoding='UTF-8',xml_declaration=True,standalone=True)
changed={'word/document.xml':serialize(root),'word/_rels/document.xml.rels':serialize(rels),'word/settings.xml':serialize(settings)}
newtypes=serialize(types)
# Preserve content types byte-for-byte when all image formats were already declared.
if E.tostring(E.fromstring(original['[Content_Types].xml'])) != E.tostring(types):changed['[Content_Types].xml']=newtypes
with ZipFile(FINAL,'w') as z:
    for info in zipinfos:z.writestr(info,changed.get(info.filename,original[info.filename]))
    for name,blob in added.items():z.writestr(name,blob,compress_type=8)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
with ZipFile(FINAL) as z:
    preserved=[n for n in original if n not in changed]
    assert all(z.read(n)==original[n] for n in preserved)
    rr=E.fromstring(z.read('word/document.xml'))
    assert len(rr.xpath('//w:sectPr',namespaces=NS))==3
    assert len(rr.xpath('//w:sdt',namespaces=NS))==20
    assert len(rr.xpath('//w:txbxContent',namespaces=NS))>=18
    before=E.fromstring(original['word/document.xml'])
    assert [E.tostring(x) for x in before.xpath('//w:sectPr',namespaces=NS)] == [E.tostring(x) for x in rr.xpath('//w:sectPr',namespaces=NS)]
    (WORK/'package_fidelity.json').write_text(json.dumps({'source_sha256':SOURCE_HASH,'output':str(FINAL),'unchanged_parts':preserved,'changed_parts':list(changed),'added_images':list(added),'sections':3,'content_controls':20},indent=2),encoding='utf-8')
print(FINAL)
print('Images added:',len(added),'Preserved parts:',len(preserved),'bytes:',FINAL.stat().st_size)
