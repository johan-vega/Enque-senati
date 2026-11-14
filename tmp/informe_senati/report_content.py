STUDENT = {
    'name': '[Apellidos y nombres]', 'id': '[ID]',
    'cfp': '[Dirección Zonal / CFP]', 'career': '[Carrera]', 'semester': '[N.º]',
}
COURSE = 'Aplicaciones para Dispositivos Móviles'
TOPIC = 'Enfoque: aplicación móvil para gestión de tareas'

PROBLEM = [
    'El caso PAWD-403 plantea que una empresa tecnológica necesita ayudar a las personas a organizar sus actividades diarias. La dispersión de pendientes entre notas, mensajes y agendas dificulta reconocer vencimientos, actualizar el avance y mantener la misma información en varios dispositivos.',
    'Se requiere registrar, editar, eliminar, categorizar y consultar tareas; sincronizar los cambios por cuenta; personalizar la interfaz y configurar recordatorios. Una lista que solo guarde información local no resolvería la sincronización solicitada.',
    'El alcance implementado es la gestión individual de tareas personales, académicas y laborales. No se incluye asignación de actividades a equipos. Android se compiló y se probó en un dispositivo virtual; la verificación de iOS y la entrega real de avisos con la aplicación cerrada requieren pruebas adicionales.',
]
SOLUTION = [
    'Se desarrolló Enfoque en Flutter y Dart dentro de Entregable. Firebase Authentication identifica al usuario y Cloud Firestore almacena tareas, categorías y preferencias en rutas privadas por uid. Los streams actualizan la interfaz cuando cambia la información.',
    'Incluye acceso y recuperación de contraseña, CRUD, filtros, búsqueda, calendario, estadísticas, tema claro/oscuro y recordatorios locales Android/iOS. Se conservan evidencias de 18 pruebas Flutter, siete escenarios Firebase y una integración Android aprobada; el análisis no presenta observaciones.',
    'Se entregan código fuente, reglas, APK de depuración, diagramas, capturas reales y referencias de interfaz exportables. El archivo editable Figma/Adobe XD, la configuración de nube del estudiante y las validaciones físicas pendientes se identifican expresamente.',
]
QUESTIONS = [
    ('¿Qué estrategias utilizarías para garantizar que la aplicación funcione correctamente en múltiples dispositivos y plataformas (iOS, Android)?',
     'Compartiría modelos, repositorios y widgets Flutter, con configuración nativa por plataforma. Enfoque usa SafeArea, formularios desplazables, localización española y temas legibles. Se comprobó el layout a 360 píxeles, texto al 130 % y 50 tareas; Android compiló y pasó integración. iOS conserva objetivo 15.0, pero requiere Mac, Xcode, firma y pruebas reales antes de declarar compatibilidad validada.'),
    ('¿Cómo implementarías la funcionalidad de recordatorios y notificaciones en Flutter para asegurar que los usuarios no olviden tareas importantes?',
     'Implementé LocalReminders con flutter_local_notifications, timezone y flutter_timezone. Cada dispositivo programa hasta 60 tareas futuras pendientes y cancela avisos al completar, eliminar, desactivar o salir. Android usa programación inexacta; iOS solicita permisos nativos. La integración comprobó solicitudes pendientes y cancelación. La recepción con pantalla bloqueada o aplicación cerrada sigue pendiente; no se implementó un servidor FCM.'),
    ('¿Qué estructura de base de datos utilizarías para almacenar las tareas de los usuarios y asegurar la sincronización en tiempo real entre dispositivos?',
     'Utilicé users/{uid}/tasks/{taskId}, categories/{categoryId} y preferences/interface. Las reglas limitan lectura y escritura al propietario. Las tareas incluyen fecha, estado, prioridad, categoría, aviso y marcas de servidor. Los snapshots sincronizan cambios y muestran caché o escrituras pendientes. La concurrencia sigue la última escritura por campo. Dos sesiones y la reconexión se verificaron con Firebase Emulator Suite.'),
    ('¿Qué widgets principales y secundarios de Flutter utilizarías para crear una interfaz intuitiva y atractiva para la gestión de tareas?',
     'Scaffold y NavigationBar organizan cinco destinos; IndexedStack conserva su estado. ListView, Form, TextFormField y DropdownButtonFormField permiten recorrer y validar datos. Checkbox completa tareas; ChoiceChip filtra; PopupMenuButton edita o elimina; AlertDialog confirma el borrado. showDatePicker y showTimePicker programan fechas. TaskRow, TaskList y SectionHeading reutilizan composición y LinearProgressIndicator muestra avance calculado.'),
    ('¿Cómo asegurarías que la aplicación sea fácil de usar, incluso sin realizar pruebas directas con usuarios, y qué métodos alternativos sugerirías para obtener retroalimentación sobre la experiencia de usuario?',
     'Aplicaría inspección heurística y recorrido cognitivo: crear una exposición, cambiar su fecha, buscarla y completarla. Revisaría etiquetas, pasos, contraste, teclado, errores y recuperación. Se inspeccionaron renders y se ejecutaron pruebas de widgets; no se realizaron entrevistas. Como siguiente paso propongo revisión entre pares y del instructor con un guion de tareas y un formulario breve de claridad y dificultad.'),
]

PROPOSAL = [
    ('Finalidad y alcance', 'Enfoque reúne tareas personales, académicas y laborales en una cuenta. El objetivo es facilitar el registro, la consulta por fecha y el seguimiento del estado, conservando datos coherentes entre sesiones. El uso es individual; la colaboración entre equipos queda fuera del alcance actual.'),
    ('Funciones desarrolladas', 'Se implementaron registro, inicio y cierre de sesión, recuperación de contraseña, CRUD de tareas, descripción opcional, categorías, fecha/hora, prioridad, estado y recordatorio. Mis tareas combina búsqueda, cinco filtros y tres órdenes. Inicio agrupa hoy, próximas y vencidas. Calendario permite seleccionar días; Avance calcula completadas, pendientes, vencidas y porcentaje de cumplimiento con los datos almacenados.'),
    ('Organización del código', 'La estructura separa core, domain, data y features. TaskController consume streams de TaskRepository; la aplicación utiliza FirestoreTaskRepository. ChangeNotifier y ListenableBuilder gestionan el estado sin incorporar otro framework. SessionGate mantiene la suscripción de Authentication estable durante cambios de tema. Preferences conserva tema, acento y avisos mediante SharedPreferences y Firestore.'),
    ('Datos e integración', 'La estructura users/{uid} contiene tasks, categories y preferences. Los documentos usan Timestamp y marcas de servidor. Las reglas validan propietario, campos, tipos y longitudes; createdAt es inmutable. Las categorías se archivan y se pueden restaurar para no perder asociaciones. La inicialización es transaccional, con IDs deterministas. El cliente muestra estados de caché y cambios pendientes.'),
    ('Recordatorios y diseño', 'Los avisos son locales por dispositivo. La reconciliación serializada excluye tareas completadas o vencidas, limita el plan a 60 y evita duplicados mediante una firma. La interfaz usa Manrope, fondos cálidos, un acento y separadores. Una fotografía local de Unsplash complementa la bienvenida. Hay ocho referencias UI y una variante oscura, con guía para reconstruir el prototipo en Figma.'),
    ('Validación y correcciones', 'Se registran 18 pruebas Flutter aprobadas, siete escenarios Firebase aprobados y un escenario Android completo aprobado. Se corrigieron la incompatibilidad del plugin de avisos con SDK 36, el alias GMT y un ciclo de reconstrucción al cambiar el tema. El último ajuste se comprobó en web y con dos pruebas de regresión; no se repitió la integración Android después de ese ajuste.'),
    ('Condiciones de entrega', 'El APK final se recompiló y usa Firebase local para emulador Android. Para producción se necesita un proyecto propio, activar correo/contraseña y desplegar reglas. Permanecen pendientes iOS en Mac, entrega de notificaciones en segundo plano, dos teléfonos físicos y el archivo editable Figma/Adobe XD. Los anexos presentan diagramas, evidencias y pasos de ejecución.'),
]

OPERATIONS = [
    ('01. Revisar el caso y la carpeta Entregable.', 'Conservar los ejercicios y archivos existentes.'),
    ('02. Verificar Flutter, Dart y Android SDK.', 'Dependencias compatibles; usar el Dart de Flutter.'),
    ('03. Definir alcance individual y flujo de pantallas.', 'Etiquetas claras y prevención de errores.'),
    ('04. Crear estructura core, domain, data y features.', 'Responsabilidades separadas y null safety.'),
    ('05. Implementar registro, acceso y recuperación.', 'Firebase Auth; no almacenar contraseñas propias.'),
    ('06. Definir documentos y reglas por uid.', 'Aislamiento de cuentas y esquema validado.'),
    ('07. Implementar CRUD y cambio de estado.', 'Título válido; confirmar el borrado.'),
    ('08. Crear categorías y archivado reversible.', 'Conservar referencias de tareas asociadas.'),
    ('09. Incorporar búsqueda, filtros y calendario.', 'Fechas locales y estados vacíos comprensibles.'),
    ('10. Calcular indicadores a partir de las tareas.', 'No inventar porcentajes ni estadísticas.'),
    ('11. Guardar tema, acento y preferencias.', 'Persistencia y valores idénticos sin reconstrucción.'),
    ('12. Programar y cancelar recordatorios locales.', 'Permisos, zona horaria y límite de 60 solicitudes.'),
    ('13. Probar reglas, dos sesiones y reconexión.', 'Emuladores locales; no usar datos personales.'),
    ('14. Ejecutar formato, análisis y pruebas Flutter.', 'Registrar resultados reales y corregir errores.'),
    ('15. Compilar e integrar Android virtual.', 'Separar solicitudes nativas de entrega real.'),
    ('16. Corregir el ciclo del modo oscuro.', 'Mantener una sola suscripción de sesión.'),
    ('17. Exportar referencias, capturas y diagramas.', 'Licencias trazables; no simular capturas reales.'),
    ('18. Documentar y preparar la sustentación.', 'Pausas y orden del puesto; priorizar entrega digital.'),
]

ANNEX_TEXT = [
    ('7. IMPLEMENTACIÓN TÉCNICA', [
        ('Arquitectura del proyecto', 'main.dart inicializa preferencias y Firebase. EnfoqueApp aplica el tema; SessionGate conserva el stream de autenticación y presenta Workspace por uid. Las funcionalidades se distribuyen en auth, tasks, dashboard y settings. La lógica de filtrado y estadísticas está en domain/task.dart; la persistencia real está en data/task_repository.dart.'),
        ('Estado y repositorio', 'TaskController escucha tareas y categorías, conserva carga/errores/metadatos y coordina recordatorios. TaskRepository permite usar dobles únicamente en pruebas; la aplicación no utiliza una lista simulada como fuente principal. Las suscripciones se cancelan al salir. Se eligió ChangeNotifier por su disponibilidad en Flutter y por un alcance académico de decenas de tareas.'),
        ('Validaciones e interacción', 'El título es obligatorio y admite hasta 120 caracteres; la descripción admite hasta 2000. Categoría y fecha son opcionales. Un recordatorio nuevo exige fecha futura y tarea pendiente. La edición conserva el ID; la casilla actualiza estado sin abrir el editor. El borrado solicita confirmación. Los formularios contemplan teclado y desplazamiento.'),
        ('Consultas y estadísticas', 'Todas incluye tareas completadas y sin fecha; Hoy incluye pendientes de la fecha actual; Próximas empieza mañana; Vencidas compara el instante programado. La búsqueda consulta título y descripción sin distinguir mayúsculas. El orden usa fecha, prioridad o título. Cumplimiento = completadas / total; si no hay tareas es cero. Las vencidas forman parte de las pendientes.'),
        ('Persistencia y concurrencia', 'Firestore conserva caché en Android/iOS y sincroniza escrituras al reconectar. En web se usa la caché de memoria predeterminada. El indicador de caché no equivale a una medición de Internet. El formulario espera confirmación del servidor. La política de concurrencia es última escritura por campo; no hay fusión de texto ni historial de versiones. Para miles de tareas se necesita paginación y consultas de servidor.'),
    ]),
    ('8. FIREBASE Y CONFIGURACIÓN', [
        ('Modelo y propiedad de los datos', 'Cada cuenta se identifica por uid. users/{uid} guarda createdAt. tasks/{taskId} contiene title, description, categoryId, dueAt, priority, completed, reminder, createdAt y updatedAt. categories/{categoryId} contiene name, archived y updatedAt. preferences/interface contiene dark, accent y notifications. dueAt es Timestamp o nulo; prioridad admite 0, 1 y 2.'),
        ('Reglas y auditoría', 'firestore.rules exige request.auth.uid igual al uid de la ruta. Valida campos permitidos, longitudes y tipos; las marcas de actualización usan request.time y createdAt no cambia después de crear. El borrado físico de categorías está prohibido; se archivan. Las pruebas rechazan accesos ajenos, anónimos, propiedades extra y auditoría falsificada. No se requieren índices compuestos para las consultas actuales.'),
        ('Inicialización y sincronización', 'bootstrap.dart recibe FirebaseOptions mediante dart-define. Sin configuración muestra una guía; con USE_EMULATORS=true conecta demo-enfoque a Auth 9099 y Firestore 8080. Los snapshots incluyen metadatos de caché y escrituras pendientes. Las categorías Personal, Estudios, Trabajo y Hogar se inicializan en una transacción con IDs deterministas para evitar duplicados entre dispositivos.'),
        ('Configuración de producción pendiente', 'Registrar Android e iOS en Firebase, activar correo/contraseña y crear Firestore en modo producción. Copiar config/firebase.example.json a firebase.local.json y completar los identificadores públicos de la plataforma. Desplegar reglas e índices en el proyecto del estudiante. El archivo local, claves privadas y firma se excluyen de Git. No se utilizó una cuenta de servicio en el cliente.'),
        ('Ejecución local', 'En Entregable ejecutar npm ci y npm run emulators; en otra terminal, flutter run -d chrome --dart-define=USE_EMULATORS=true. Para Android virtual añadir --dart-define=EMULATOR_HOST=10.0.2.2. La información de emuladores es temporal si no se exporta. No usar contraseñas personales ni exponer sus puertos a Internet.'),
    ]),
]

FINAL_NOTES = [
    ('Resultado y alcance', 'Enfoque implementa la gestión individual de tareas y su sincronización por cuenta con Flutter y Firebase. La evidencia demuestra CRUD, aislamiento y reconexión con servicios emulados, además de compilación e integración Android. La solución requiere configurar Firebase de producción y completar validaciones físicas antes de publicarse.'),
    ('Recordatorios y plataformas', 'El plugin programa solicitudes nativas en Android/iOS. Android utiliza inexactAllowWhileIdle y el sistema puede demorar el aviso. iOS tiene objetivo 15.0 y un plan de hasta 60 solicitudes. No hay servidor FCM: cambios remotos con un cliente cerrado no actualizan sus avisos hasta que vuelva a abrirse. La recepción con pantalla bloqueada, app cerrada y reinicio no se declaró aprobada.'),
    ('Calidad y revisión', 'Se revisaron las ocho pantallas a 390 x 844 y el modo oscuro; las pruebas recorren 360 x 800, texto al 130 % y 50 tareas. Esto no reemplaza TalkBack, VoiceOver ni estudios de usabilidad. El borrado está protegido y las categorías conservan sus referencias. El informe no atribuye opiniones a usuarios ni una auditoría humana independiente.'),
    ('Seguridad salud y ambiente', 'Se proponen orden de cables y equipos, postura cómoda, pausas regulares y ventilación del puesto; no se realizó una inspección física de SST. Se priorizan entrega digital, reutilización de equipos y pruebas necesarias para reducir impresiones y ejecuciones redundantes. No se afirma certificación ISO ni cumplimiento de una norma no evaluada.'),
    ('Recomendaciones', 'Probar Android e iOS en teléfonos físicos con la misma cuenta; validar permisos y entrega de avisos; obtener revisión del instructor y pares con un guion de tareas; reconstruir el prototipo editable en Figma; preparar firma Android y Team de Apple; sustituir el icono de lanzador antes de publicación. La autocalificación de la sección 6 debe completarla el estudiante.'),
]

REFERENCES = [
    'SENATI. PAWD-403_TRABAJOFINAL.pdf, caso práctico y preguntas guía, pp. 2-4.',
    'SENATI. PAWD-403_FORMATOALUMNOTRABAJOFINAL.docx, formato del alumno.',
    'Flutter. Documentación e implementación multiplataforma: https://docs.flutter.dev/',
    'Firebase para Flutter: https://firebase.google.com/docs/flutter/setup',
    'Persistencia y concurrencia: https://firebase.google.com/docs/firestore/manage-data/enable-offline',
    'Reglas: https://firebase.google.com/docs/firestore/security/get-started',
    'Emuladores: https://firebase.google.com/docs/emulator-suite',
    'Notificaciones 22.0.0: https://pub.dev/packages/flutter_local_notifications/versions/22.0.0',
    'Recursos: Unsplash License, https://unsplash.com/license; Manrope/OFL, https://github.com/google/fonts/tree/main/ofl/manrope.',
]
