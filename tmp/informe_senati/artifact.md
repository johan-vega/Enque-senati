# Contrato de uso de la plantilla SENATI

Referencia conservada: C:/Users/user/Downloads/PAWD-403_FORMATOALUMNOTRABAJOFINAL.docx
SHA-256: 912e3d8e2e372e36171bd728f68c67ff6256774b6c991e7f3f23e7c46111731b
Vista de referencia: plantilla_referencia.pdf y template-reference-render/page-1.png a page-10.png. Diez páginas inspeccionadas, tres secciones.
Inventario completo de partes y relaciones: package_inventory.json. Estructura: template_document.xml y body_inventory.txt. Estilos: template-style-evidence.json.

## Geometría y elementos preservados

Todas las secciones A4 vertical, 11906 x 16838 twips, una columna. Sección 1: márgenes top/left 1134, right/bottom 851; header/footer 709. Sección 2: top 1418, left/right 1134, bottom 851; header/footer 709. Sección 3: top/left 1418, right 1701, bottom 249; header/footer 709. Mantener los tres sectPr y sus propiedades. Primera página distinta en sección 1.
Conservar portada, contraportada, imágenes SENATI/RDA, cabeceras, pie con flecha y campos PAGE. No modificar los archivos de cabeceras/pies, estilos, tema ni numeración. Word repagina para el PDF; settings/updateFields se habilita para apertura del DOCX.
Títulos originales en bandas azules redondeadas con sombra, texto Arial blanco de 16 pt; conservarlos como dibujos editables existentes. Texto de formularios y tablas Arial 10 pt; preguntas/etiquetas y encabezados conservan negrita y alineaciones de origen. Anexos reutilizan la banda y párrafos Arial 10/12 de la plantilla. No aplicar un estilo visual nuevo.

## Patrones de página y espacios editables

1. Portada institucional: conservar byte a byte sus elementos.
2. Datos del estudiante: tabla T0, valores en celdas vacías. Nombre, ID, CFP, carrera y semestre quedan señalados para completar si el usuario no proporciona datos. Curso y tema se completan con el caso.
   Problema: cuadros de texto 2 y 3 (Choice/Fallback duplicados), contenidos vacíos de P46. Llenar ambos con texto equivalente de aproximadamente 150 palabras, sin cambiar tamaño ni anclaje.
   Solución/evidencias: cuadros 4 y 5 de P49, hasta unas 150 palabras, sin alterar anclajes.
3. Preguntas: tabla T1 con cinco pares de filas. En filas pares conservar etiqueta Pregunta NN y llenar segunda celda con pregunta completa; en filas impares llenar respuesta en celda combinada. Arial 10/11, conservar columnas y bordes; alturas son mínimas y permiten crecer. Si no cabe, permitir página adicional sin achicar tipografía.
4. Planificación: T2 cronograma con seis etapas y seis actividades. P62 sirve para aclarar que es secuencia reconstruida del 14/11/2026 y no una medición de horas. T3/T4/T5 recursos: cuatro filas por tabla, anclajes flotantes y encabezados conservados; descripciones concisas para no superponer tablas.
5. Propuesta: T6 flotante con celda narrativa. Sustituir párrafos vacíos por propuesta resumida, objetivos, arquitectura, datos, funciones, pruebas y pendientes; no exceder su página. Detalle se amplía en anexos.
6. Ejecutar: T7 conserva dos columnas y cabecera. Usar hasta 18 filas de operaciones con norma/control asociado y eliminar las filas sobrantes vacías. Evitar una tabla excesiva o filas partidas.
7. Dibujo: T8 flotante, celda superior para dos diagramas de arquitectura y Firestore. Conservar cajetín inferior, logo y título; texto de escala pasa a Sin escala. Encabezado de dibujo P105 conservado.
8. Controlar: T9 incluye 20 controles de casilla (w:sdt envuelve celdas). Conservar estructura/IDs; solo marcar w14:checked y su glifo. Marcar como pendiente/no cumplido el cumplimiento integral debido a Figma editable y validaciones de producción pendientes; explicar al pie. No atribuir aprobaciones inexistentes.
9. Valorar: T10 conservar criterios y máximos; celdas de autocalificación reservadas al estudiante, con Pendiente. No inventar nota del instructor.
10. Contraportada institucional: conservar P112-P121 y sectPr final. Insertar anexos ANTES de P112, con saltos de página y bandas derivadas de P110. Se permite aumentar páginas; no se agregan secciones ni cambia la geometría.

## Anexos permitidos

Páginas adicionales para implementación/modelo, Firebase/reglas/configuración, diagramas de creación/sincronización y avisos/navegación, cuatro pares de referencias UI, captura Android, captura web del tema corregido, resultados/límites, conclusiones y referencias. Párrafos y tablas reutilizan estilos y columnas de origen; imágenes en línea con leyendas. Referencias UI claramente identificadas como renders de widgets con datos de prueba. Capturas reales Android/web identificadas por entorno; no afirmar iOS compilado, Figma creado o entrega en segundo plano validada.

## Fidelidad de paquete y controles

Editar mediante patch de ZIP: word/document.xml, word/_rels/document.xml.rels si se agregan imágenes, [Content_Types].xml solo si falta un tipo, y word/settings.xml/updateFields. Agregar únicamente imágenes nuevas. Todas las otras partes inventariadas son preserve-only y deben coincidir en SHA-256; relaciones existentes no se eliminan ni cambian. Preservar 20 controles, 18 cuadros de texto originales, sus dibujos, marcas y numeración. Clones de bandas requieren IDs de dibujo y VML únicos.
Verificar referencia original inalterada, todos los vínculos de imágenes válidos, tres secciones iguales a origen, 20 controles, contenido completo y todas las páginas revisadas visualmente tras la exportación Word y rasterización con render_docx.py. En Windows sin LibreOffice empaquetado, usar PDF exportado por Word como entrada del convertidor de la copia adaptadora local del renderizador; nunca invocar un LibreOffice de escritorio.
