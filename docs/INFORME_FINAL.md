# Desarrollo de la aplicación móvil Enfoque

Proyecto final SENATI

Estudiante: [Nombres y apellidos]

Instructor: [Nombre del instructor]

Curso: Aplicaciones para Dispositivos Móviles

Programa y sede: [Completar]

Fecha de presentación: [Completar]

Fecha de verificación técnica: 14 de noviembre de 2026

## 1 Introducción

Enfoque organiza tareas personales, académicas y laborales desde una aplicación Flutter. El proyecto aborda el registro de actividades, su clasificación y la consulta del avance con una cuenta individual. Firebase Authentication identifica a cada usuario y Cloud Firestore almacena sus datos y distribuye los cambios a otras sesiones.

La implementación se encuentra en la carpeta Entregable. Incluye acceso por correo, gestión de tareas y categorías, calendario, estadísticas, personalización y programación local de recordatorios. La conexión a producción depende de un proyecto Firebase del estudiante. Para comprobar la integración sin credenciales de nube se utiliza Firebase Emulator Suite. Los resultados disponibles y las verificaciones pendientes se distinguen en este informe y en PRUEBAS.md.

## 2 Descripción del problema

Una persona que combina estudio y trabajo suele distribuir sus actividades entre notas, mensajes y recordatorios aislados. Esto dificulta reconocer vencimientos, retomar tareas pendientes y mantener la misma información en dos dispositivos. La empresa del caso práctico requiere una herramienta móvil con una vista clara del día, edición rápida y sincronización por usuario.

El alcance elegido es la organización individual. No incluye asignación de tareas a equipos, conversación entre usuarios ni gestión empresarial de proyectos. Esta delimitación permite concentrar el desarrollo en persistencia, reglas de acceso y una interfaz defendible para un proyecto académico.

## 3 Objetivos

El objetivo general es desarrollar y verificar una aplicación móvil que permita administrar tareas personales mediante Flutter y Firebase, con sincronización y una experiencia coherente en Android e iOS.

Los objetivos específicos son implementar operaciones de creación, consulta, edición, eliminación y cambio de estado; organizar tareas por categorías y fechas; proteger los datos por identidad; calcular indicadores sobre información real; conservar preferencias; programar y cancelar recordatorios locales; y dejar pruebas y documentación reproducibles.

## 4 Requisitos funcionales y no funcionales

| Código | Requisito | Implementación |
|---|---|---|
| RF01 | Registro, acceso, recuperación y salida | Firebase Authentication y AuthScreen |
| RF02 | CRUD de tareas y estado | FirestoreTaskRepository y TaskEditor |
| RF03 | Búsqueda, filtros y orden | selectTasks y TasksScreen |
| RF04 | Categorías iniciales y personalizadas | Colección categories, archivado y restauración |
| RF05 | Tareas por fecha | Inicio y calendario mensual |
| RF06 | Indicadores de seguimiento | TaskStats con valores de Firestore |
| RF07 | Preferencias y perfil | Preferences, SharedPreferences y Firebase Auth |
| RF08 | Sincronización por cuenta | Streams con metadatos de caché |
| RF09 | Recordatorios | LocalReminders en Android e iOS |

La aplicación debe utilizar textos en español, conservar una jerarquía legible y ofrecer estados de carga, error y ausencia de datos. La información de una cuenta no debe ser accesible por otra. Se requiere código organizado, null safety y comprobaciones automatizadas. La compatibilidad iOS se contempla en el proyecto nativo, pero su validación requiere un Mac.

La persistencia de tareas sin conexión depende de la caché del SDK de Firestore en Android/iOS; no se incorpora una segunda base local de tareas. Los formularios esperan confirmación de escritura y no declaran guardado en el servidor si la conexión sigue pendiente. La interfaz advierte que puede cerrarse mientras Firestore conserva el cambio local.

## 5 Justificación de tecnologías

Flutter y Dart permiten compartir presentación y lógica para Android e iOS. Se emplean widgets Material con localización española y controles convencionales de calendario, hora, formularios y navegación. Firebase Authentication evita almacenar contraseñas en la aplicación. Firestore aporta documentos por usuario, suscripción a cambios y caché de datos.

El manejo de estado usa ChangeNotifier y ListenableBuilder, incluidos en Flutter. TaskController concentra suscripciones, errores y coordinación de recordatorios; Preferences conserva la personalización. Esta solución evita dependencias adicionales para un volumen académico de decenas de tareas y puede explicarse sin un framework de estado externo.

flutter_local_notifications 22.0.0 se eligió después de comprobar que la versión 23 exigía Android SDK 37 y fallaba con el SDK 36 del entorno. timezone calcula fechas locales y flutter_timezone obtiene la zona del dispositivo. shared_preferences guarda preferencias simples. Las versiones resueltas se conservan en pubspec.lock; package-lock.json fija las herramientas de pruebas Firebase.

## 6 Arquitectura

El código se organiza por funcionalidades dentro de lib/features. El modelo Task y las funciones de filtrado están en domain/task.dart. El contrato TaskRepository permite probar la lógica con dobles controlados; la ejecución normal utiliza exclusivamente FirestoreTaskRepository. La capa core agrupa tema, inicialización Firebase, preferencias, traducción de errores y programación nativa.

main.dart inicializa servicios y presenta EnfoqueApp. app.dart organiza el tema y la navegación; SessionGate conserva la suscripción de autenticación independientemente de los cambios de apariencia. Cada pantalla recibe el controlador o los servicios que necesita. Las suscripciones se cancelan al cerrar el espacio de trabajo y las operaciones asíncronas comprueban si el widget sigue montado antes de actualizarlo. Las preferencias idénticas no vuelven a disparar reconstrucciones, para evitar ciclos entre la interfaz y los snapshots de Firestore.

Los diagramas reproducibles de arquitectura, datos, creación, sincronización, recordatorios y navegación se encuentran en DIAGRAMAS.md. El repositorio no introduce servicios remotos ficticios ni listas locales de tareas en la aplicación.

## 7 Diseño de base de datos

La raíz es users/{uid}. El documento guarda createdAt y tiene tres subcolecciones:

| Ruta | Campos principales |
|---|---|
| tasks/{taskId} | title, description, categoryId, dueAt, priority, completed, reminder, createdAt, updatedAt |
| categories/{categoryId} | name, archived, updatedAt |
| preferences/interface | dark, accent, notifications |

Las fechas programadas se almacenan con Timestamp. createdAt y updatedAt se establecen con marcas de servidor para evitar depender del reloj del teléfono en la auditoría. dueAt puede ser nulo; reminder requiere una fecha. El formulario limita títulos a 120 caracteres y descripciones a 2000. La prioridad admite 0, 1 y 2.

Las reglas comprueban request.auth.uid y el uid de la ruta, validan campos y rechazan propiedades desconocidas. El tiempo de creación no puede alterarse después. Las categorías no se borran físicamente: se archivan y las tareas conservan el identificador, lo que evita perder asociaciones durante cambios concurrentes o trabajo sin conexión.

La política de edición concurrente sigue la última escritura recibida por Firestore para los campos modificados. El cambio rápido de estado actualiza solo completed y updatedAt. El formulario actualiza sus campos completos y puede reemplazar cambios concurrentes de otra sesión. No se implementa historial de versiones ni fusión de texto. Las consultas leen documentos de la cuenta y filtran en Dart; no requieren índices compuestos en esta versión.

## 8 Integración entre Flutter y Firebase

bootstrap.dart recibe la configuración mediante parámetros de compilación. Sin FIREBASE_PROJECT_ID, y si no se solicitan emuladores, muestra una guía de conexión. Con USE_EMULATORS=true configura Auth y Firestore contra servicios locales demo-enfoque. En producción se usan los valores públicos de la aplicación registrada en Firebase Console.

FirestoreTaskRepository.watchTasks escucha snapshots con includeMetadataChanges. Cada evento actualiza TaskController y la lista visible. La interfaz distingue Conectando, Datos en caché, Cambios por sincronizar y Sincronizado. Estos estados describen metadatos del SDK; no garantizan por sí solos que el acceso a Internet esté disponible.

Las categorías iniciales Personal, Estudios, Trabajo y Hogar se crean con IDs deterministas dentro de una transacción. Si dos sesiones inicializan la misma cuenta, solo una crea los valores de inicio. La configuración de producción y la prueba manual entre A y B se detallan en CONFIGURACION_FIREBASE.md.

## 9 Diseño y descripción de interfaces

La dirección visual utiliza un fondo cálido, Manrope, un acento bosque y separadores discretos entre tareas. Las fotografías se limitan a la bienvenida para que el trabajo diario priorice lectura e interacción. Se revisaron los patrones Hoy y Próximas de Todoist y Things como referencia de organización, sin reproducir su identidad.

La bienvenida combina una fotografía local de Unsplash con identidad tipográfica y campos de acceso. Inicio muestra saludo, fecha, resumen y grupos por día. Mis tareas reúne filtros, búsqueda y orden. Crear/editar usa una hoja modal desplazable que responde al teclado. Categorías explica el archivado. Calendario identifica días con tareas y muestra el día seleccionado. Avance calcula completadas, pendientes, vencidas y cumplimiento. Configuración reúne perfil, temas, acento, notificaciones y cierre de sesión.

Las ocho referencias exportables de docs/prototipo se renderizan desde los widgets con datos de prueba. Están identificadas como referencias de diseño y no deben presentarse como capturas de una integración funcionando. El acceso web se observó funcionando con Firebase Emulator Suite durante esta sesión. Las capturas Android disponibles se describen en PRUEBAS.md y se ubican en evidencias.

![Referencia de bienvenida generada por los widgets](prototipo/bienvenida.png)

![Referencia de inicio con datos explícitos de prueba](prototipo/inicio.png)

Estas figuras muestran composición y tipografía; sus tareas son casos de prueba. No se creó un archivo Figma editable. La guía de reconstrucción de componentes y flujos se incluye en prototipo/README.md.

![Captura real de Android con Firebase Emulator Suite y una tarea desechable del test](evidencias/android-inicio.png)

La captura anterior procede del Pixel 6 virtual durante la integración aprobada. La etiqueta EMULADOR identifica el entorno; la tarea fue creada expresamente por la prueba y no pertenece a una cuenta de producción.

## 10 Implementación de funciones principales

El formulario valida título, longitudes y coherencia del recordatorio. Puede guardar tareas sin fecha y sin categoría. La edición conserva el ID; el cambio rápido de estado no obliga a abrir un formulario. La eliminación muestra una confirmación con el nombre de la tarea y advierte que no puede deshacerse.

selectTasks permite combinar búsqueda y categoría con un filtro temporal. Hoy incluye pendientes de la fecha local actual; Próximas comienza mañana; Vencidas identifica pendientes cuyo instante programado ya pasó. Todas incluye completadas y tareas sin fecha. El orden usa fecha, prioridad o título y resuelve empates por ID.

TaskStats cuenta total, completadas y vencidas; pendientes es total menos completadas. Cumplimiento es completadas dividido por total y vale cero si no hay tareas. Las vencidas son parte de las pendientes, no una tercera población que deba sumarse. No se inventan porcentajes ni se equipara cumplimiento con horas de trabajo.

## 11 Recordatorios y notificaciones

La tarea sincroniza su bandera reminder y su fecha. Cada dispositivo obtiene su zona IANA y convierte el instante a TZDateTime antes de llamar al plugin nativo. Un plan selecciona las primeras 60 tareas futuras, pendientes y con recordatorio activo. Se deja margen respecto al límite de solicitudes pendientes de iOS.

La reconciliación cancela las solicitudes anteriores y programa un ID por tarea del nuevo plan. Una firma evita repetir el mismo trabajo y una cola impide que dos reconciliaciones se intercalen. Completar, borrar o desactivar preferencias modifica ese plan. Cerrar sesión cancela los avisos locales.

En Android se usa programación inexacta permitida en reposo, sin permisos de alarmas exactas. Por ello el sistema puede demorar la entrega. En iOS se configura el delegado UNUserNotificationCenter y se solicitan permisos al activar las notificaciones. En web se informa que la entrega solo está disponible en Android/iOS.

No hay FCM ni funciones de servidor que despierten la aplicación. Si una tarea cambia remotamente con otro dispositivo cerrado, ese dispositivo conserva su programación anterior hasta recibir datos al abrirse. No se declara verificada la entrega en segundo plano, con la app cerrada o después de un reinicio.

## 12 Plan y resultados de pruebas

La suite de Flutter contiene 18 pruebas de dominio, controlador y widgets. Todas pasaron en la ejecución registrada. Cubren validación, filtros, estadísticas, planeamiento de recordatorios, errores de red, CRUD del controlador, persistencia de preferencias, cambio de tema y composición de las pantallas.

La prueba de presentación utiliza 360 × 800, 50 tareas y texto ampliado al 130 %, tanto en claro como en oscuro. No detectó excepciones de desbordamiento. La exportación de referencias a 390 × 844 permite inspeccionar las interfaces. Esto es una comprobación de layout, no una evaluación con personas.

Firebase Emulator Suite ejecutó siete escenarios que pasaron: CRUD del propietario; aislamiento frente a otro usuario; denegación de anónimos; validación de tipos y auditoría; archivado seguro; preferencias; y registro/acceso con dos sesiones reales del SDK JavaScript. El último escenario escucha cambios, interrumpe la red de un cliente, observa una escritura pendiente y comprueba la sincronización tras reconectar.

El APK Android debug compiló correctamente después de ajustar la versión del plugin. La integración Android aprobó registro, sincronización entre dos instancias FlutterFire, edición, cambio de estado, eliminación, consultas de solicitudes nativas de notificación, cierre mediante la interfaz y nuevo acceso. El registro conserva el resultado del escenario completo, separando compilación, instalación y ejecución. El análisis final no informó observaciones. PRUEBAS.md conserva la matriz y los registros. iOS no se compiló porque el entorno es Windows. La entrega real de notificaciones queda sujeta a la matriz manual.

## 13 Auditoría y correcciones

La revisión técnica eliminó avisos de estilo y un import innecesario; corrigió la incompatibilidad de SDK del paquete de notificaciones; y separó configuración ausente de un fallo de autenticación. La revisión de pruebas corrigió el desplazamiento previo a pulsar Guardar y cargó la tipografía y los iconos para producir referencias legibles.

La revisión funcional incorporó archivado de categorías, preservación del estado archivado al renombrar, cancelación de recordatorios y estados explícitos de sincronización. La revisión visual comprobó fotografía, formularios, pantallas vacías, modo oscuro, texto ampliado y listas largas. AUDITORIA_FINAL.md conserva hallazgos y límites; no se presenta como una auditoría humana.

## 14 Limitaciones

La entrega no dispone de un proyecto Firebase de producción ni credenciales del estudiante. Requiere activar el proveedor de correo, crear Firestore y publicar reglas en la cuenta elegida. No se probó iOS en macOS ni se publicaron versiones en tiendas. La firma Android de distribución y el icono final de lanzador quedan para una publicación posterior.

No se efectuaron entrevistas, encuestas ni pruebas directas con usuarios. Las pruebas de presentación no reemplazan VoiceOver, TalkBack ni una evaluación física de tamaños táctiles. La lista se procesa por completo en memoria de presentación; un producto con miles de tareas necesitaría paginación y consultas de servidor. Los recordatorios no reciben actualizaciones remotas con clientes cerrados.

El informe también se entrega en `docs/informe/PAWD-403_INFORME_FINAL_ENFOQUE.docx`, completado sobre la plantilla oficial PAWD-403 del estudiante y contrastado con el caso práctico proporcionado. Sus 22 páginas se exportaron con Microsoft Word y se revisaron visualmente. Incluye diagramas, referencias de interfaz, capturas reales, pruebas y limitaciones verificadas; los datos personales y la autocalificación quedan para completar por el estudiante.

## 15 Conclusiones

La aplicación implementa un flujo individual completo de gestión de tareas con Flutter, autenticación Firebase y repositorios Firestore. Las pruebas disponibles demuestran comportamiento de dominio y presentación y, mediante servicios emulados, aislamiento y sincronización entre sesiones. La compilación Android confirma que el proyecto resuelve sus dependencias nativas en este entorno.

El archivado de categorías evita pérdida accidental de asociaciones y la separación de metadatos de caché evita presentar un cambio pendiente como sincronizado. Las estadísticas se calculan a partir de tareas y la personalización conserva los valores al reconstruir las preferencias. La validación de iOS, los permisos y la entrega de avisos deben completarse antes de considerar el producto listo para distribución.

## 16 Recomendaciones

Conectar un proyecto Firebase propio de prueba y ejecutar el guion con dos teléfonos. Validar entrega de notificaciones con distintos estados del sistema, completar pruebas de accesibilidad y revisar la app con estudiantes y trabajadores. Registrar los hallazgos antes de ampliar funciones. Para una publicación, configurar firma, iconos, política de privacidad, límites de uso y seguimiento de errores con consentimiento.

## 17 Respuestas a las preguntas guía

### Pregunta 1 Funcionamiento en Android e iOS

Compartiría modelos, repositorios y widgets Flutter, manteniendo configuración nativa para permisos y notificaciones. La implementación usa localización española, SafeArea, listas desplazables y campos que respetan el espacio del teclado. Se comprobó la composición con texto ampliado y ambos temas y se compiló Android. Para iOS es necesario ejecutar las mismas pruebas en un Mac, revisar el objetivo 15.0, firmar con un Team y validar un dispositivo real. Tener una carpeta ios no demuestra compatibilidad ya probada; se mantiene explícita esa diferencia.

### Pregunta 2 Recordatorios y notificaciones en Flutter

Usaría flutter_local_notifications para registrar solicitudes nativas y timezone con flutter_timezone para convertir fechas. Esta solución está implementada en LocalReminders. Al activar las notificaciones se solicita permiso; el plan excluye tareas completadas, vencidas o sin aviso, toma 60 futuras y se serializa para evitar duplicados. Los cambios de tarea y preferencias recalculan el plan; completar, borrar o salir cancela. Android utiliza avisos inexactos y puede retrasarlos. FCM sería una ampliación para actualizaciones remotas con infraestructura de servidor y pruebas específicas, no una función que se presupone implementada.

### Pregunta 3 Estructura de base de datos y sincronización

Utilizaría users/{uid}/tasks/{taskId}, categories/{categoryId} y preferences/interface, como en el repositorio. Las rutas separan datos por identidad y facilitan reglas basadas en uid. Los snapshots transmiten modificaciones a otras sesiones. Las fechas de servidor auditan cambios y la caché permite encolar escrituras. La política de concurrencia documentada es última escritura por campo; no se promete resolución automática de todas las ediciones. El archivado de categorías conserva vínculos sin requerir una transacción masiva sobre todas las tareas.

### Pregunta 4 Widgets principales y secundarios

Scaffold y NavigationBar organizan las cinco vistas. ListView permite recorrer tareas, filtros y formularios; IndexedStack conserva el estado al cambiar de destino. Form, TextFormField y DropdownButtonFormField validan datos, mientras showDatePicker y showTimePicker usan controles reconocibles. Checkbox permite completar; PopupMenuButton ofrece edición y eliminación; AlertDialog protege el borrado; ChoiceChip representa filtros; LinearProgressIndicator muestra avance y carga. Los componentes propios TaskRow, TaskList y SectionHeading mantienen consistencia sin convertir todos los elementos en tarjetas.

### Pregunta 5 Usabilidad sin pruebas directas con usuarios

Aplicaría inspección heurística y recorrido cognitivo con escenarios concretos: crear “Terminar exposición”, cambiar su fecha, encontrarla con filtros y completarla. Compararía número de pasos, claridad de etiquetas, visibilidad de estado, prevención de errores y recuperación. En esta entrega se ejecutó una revisión de widgets y layout, no entrevistas ni observación de personas. Como siguiente paso pediría retroalimentación a un docente mediante un APK y un guion de tareas, usaría una revisión entre pares con hallazgos registrados y, con consentimiento, un formulario breve de claridad y dificultad. No se atribuyen opiniones a usuarios que no participaron.

## 18 Fuentes técnicas

Consultadas el 14 de noviembre de 2026:

- Flutter, documentación: https://docs.flutter.dev/
- Firebase en Flutter: https://firebase.google.com/docs/flutter/setup
- Cloud Firestore, inicio: https://firebase.google.com/docs/firestore/quickstart?platform=flutter
- Persistencia y concurrencia: https://firebase.google.com/docs/firestore/manage-data/enable-offline
- Transacciones: https://firebase.google.com/docs/firestore/manage-data/transactions
- Reglas: https://firebase.google.com/docs/firestore/security/get-started
- Firebase Emulator Suite: https://firebase.google.com/docs/emulator-suite
- Notificaciones, versión implementada: https://pub.dev/packages/flutter_local_notifications/versions/22.0.0
- Zona horaria del dispositivo: https://pub.dev/packages/flutter_timezone
- SharedPreferences: https://pub.dev/packages/shared_preferences
- Unsplash License: https://unsplash.com/license
- Manrope y licencia: https://github.com/google/fonts/tree/main/ofl/manrope
- Referencias de interacción: https://www.todoist.com/help/todoist/get-started/plan-your-day-with-the-today-view-UVUXaiSs y https://culturedcode.com/things/support/articles/4001304/



