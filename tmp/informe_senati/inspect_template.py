from zipfile import ZipFile
from lxml import etree as E
from pathlib import Path
import json
import hashlib

p = Path(__file__).resolve().parent
source = Path(r'C:/Users/user/Downloads/PAWD-403_FORMATOALUMNOTRABAJOFINAL.docx')
with ZipFile(source) as z:
    root = E.fromstring(z.read('word/document.xml'))
    ns = {'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
    body = root.find('w:body', ns)
    rows = []
    pi = ti = 0
    for k, x in enumerate(body):
        tag = E.QName(x).localname
        text = ' | '.join(x.xpath('.//w:t/text()', namespaces=ns))
        rows.append(f'BODY {k}: {tag} P{pi if tag == "p" else ""} T{ti if tag == "tbl" else ""} {text[:260]}')
        pi += tag == 'p'
        ti += tag == 'tbl'
    (p/'body_inventory.txt').write_text('\n'.join(rows), encoding='utf-8')
    inventory = {i.filename:{'size':i.file_size,'sha256':hashlib.sha256(z.read(i.filename)).hexdigest()} for i in z.infolist()}
    (p/'package_inventory.json').write_text(json.dumps(inventory, indent=2), encoding='utf-8')
    boxes = root.xpath('//w:txbxContent', namespaces=ns)
    (p/'boxes_inventory.txt').write_text('\n\n'.join('BOX '+str(i)+' '+E.tostring(x,pretty_print=True).decode() for i,x in enumerate(boxes)),encoding='utf-8')
    (p/'template_document.xml').write_bytes(E.tostring(root,pretty_print=True,encoding='UTF-8'))
    print('Source SHA256:',hashlib.sha256(source.read_bytes()).hexdigest())
    print('Text boxes:',len(boxes),'Content controls:',len(root.xpath('//w:sdt',namespaces=ns)))
    print('Fields:',root.xpath('//w:instrText/text()',namespaces=ns))
