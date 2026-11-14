# Enfoque

Aplicación de tareas personales, académicas y laborales. Proyecto final SENATI, desarrollado en Flutter y Dart con Firebase Authentication y Cloud Firestore. Todo el proyecto está dentro de `Entregable`; no modifica los otros ejercicios de Flutter.

## Empezar

Requisitos: Flutter 3.47.9 o compatible con Dart 3.13, Node 24, Java 21 o superior para Firebase Emulator Suite, Android SDK 36. Usa el Dart incluido en Flutter.

```powershell
cd C:\idaw4\Flutter\Entregable
flutter pub get
npm ci
npm run emulators
```

En otra terminal, para revisar rápidamente la aplicación con Firebase local:

```powershell
flutter run -d chrome --dart-define=USE_EMULATORS=true
```

Para un emulador Android:

```powershell
flutter emulators --launch Pixel_6
flutter run -d emulator-5554 --dart-define=USE_EMULATORS=true --dart-define=EMULATOR_HOST=10.0.2.2
```

Registra una cuenta de prueba desde la aplicación. El proyecto `demo-enfoque` usa servicios locales, sin facturación ni conexión a una base de producción. La información de los emuladores es temporal. Para conservarla, arranca con `npx firebase emulators:start --project demo-enfoque --only auth,firestore --import=.emulator-data --export-on-exit=.emulator-data` una vez creado ese directorio mediante una exportación. No emplees cuentas ni contraseñas reales en este entorno.

Sin configuración Firebase, `flutter run` muestra una pantalla que explica cómo conectarlo; no carga tareas ficticias. La integración de producción requiere tu propio proyecto: consulta [CONFIGURACION_FIREBASE](docs/CONFIGURACION_FIREBASE.md).

## Funciones

- Registro, acceso, recuperación de contraseña y cierre de sesión.
- Creación, edición, eliminación confirmada y cambio de estado de tareas.
- Descripción, categoría, fecha/hora opcional, prioridad y recordatorio.
- Búsqueda; filtros Todas, Hoy, Próximas, Completadas y Vencidas; orden por fecha, título o prioridad.
- Categorías iniciales y personalizadas. Eliminar archiva y conserva las asociaciones; admite restauración.
- Inicio por fechas, calendario mensual con indicadores y estadísticas calculadas con datos almacenados.
- Tema claro/oscuro, tres acentos, nombre del perfil y preferencias persistentes.
- Streams de Firestore con estado de caché y escrituras pendientes. Cada cuenta accede solo a sus documentos.
- Recordatorios locales Android/iOS, zona horaria IANA, reprogramación y cancelación. La web no programa avisos.

## Estructura

```text
lib/
  main.dart                 Inicio y configuración
  app.dart                  Sesión y navegación
  core/                     Tema, preferencias, Firebase, errores, recordatorios
  domain/task.dart          Modelos, filtros, validaciones y estadísticas
  data/task_repository.dart Repositorio de Firestore y contrato de acceso
  features/auth/            Acceso y registro
  features/tasks/           Listado, formulario, categorías y estado
  features/dashboard/       Inicio, calendario y avance
  features/settings/        Perfil y personalización
test/                       Unitarias, widgets y reglas/emuladores
integration_test/           Integración Flutter para Android
test_driver/                Exportación de capturas de integración
assets/                     Foto y tipografía locales, licencia de la fuente
docs/                       Informe, guías, diagramas, pruebas y auditoría
config/                     Ejemplo de configuración pública Firebase
firestore.rules             Aislamiento y validación de datos
```

Se utiliza `ChangeNotifier` con `ListenableBuilder`, incluidos en Flutter. Separa el estado de los widgets sin incorporar un framework adicional. Los dobles en `test/support.dart` solo se usan para las pruebas; la aplicación utiliza Firestore.

## Comprobaciones

```powershell
dart format lib test integration_test test_driver
flutter analyze
flutter test
# Con los emuladores de desarrollo detenidos:
npm run test:rules
flutter build apk --debug
# Con Firebase local y Android iniciados:
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d emulator-5554 --dart-define=USE_EMULATORS=true --dart-define=EMULATOR_HOST=10.0.2.2
```

Resultados y alcance: [PRUEBAS](docs/PRUEBAS.md). APK de depuración: `build/app/outputs/flutter-apk/app-debug.apk`. La compilación sin parámetros muestra la guía de conexión; para crear un APK conectado, añade los parámetros de emulador o configuración de producción. Un APK debug no está firmado para distribución en tiendas.

Se incluye además `dist/enfoque-emuladores-debug.apk`, construido desde `lib/main.dart` con Firebase local en `10.0.2.2`. Es la aplicación normal para un emulador Android, no el ejecutable de pruebas. Necesita `npm run emulators` activo en Windows; no sirve para conectar un teléfono físico a producción. Instálalo con `adb install -r dist/enfoque-emuladores-debug.apk`.

## Documentación para sustentar

- [Informe final y preguntas guía](docs/INFORME_FINAL.md)
- [Configuración Firebase y sincronización entre dispositivos](docs/CONFIGURACION_FIREBASE.md)
- [Android e iOS](docs/PLATAFORMAS.md)
- [Arquitectura y diagramas](docs/DIAGRAMAS.md)
- [Diseño e importación a Figma](docs/prototipo/README.md)
- [Procedencia de recursos](docs/RECURSOS_VISUALES.md)
- [Auditoría final](docs/AUDITORIA_FINAL.md)

## Límites de la entrega

No incluye credenciales de producción ni publicación en tiendas. iOS requiere macOS y Xcode. La entrega de notificaciones con el teléfono bloqueado, la app cerrada o tras reiniciar requiere validación manual. Los cambios remotos solo actualizan los avisos de un dispositivo cuando este recibe datos con la aplicación activa o vuelve a abrirla; no hay un servidor FCM. Firestore conserva la última escritura recibida para campos modificados concurrentemente.

Las consultas leen las tareas del usuario y filtran en Dart, adecuado para decenas de tareas. Para miles de registros se deben incorporar paginación y consultas con índices. No se ha realizado un estudio con usuarios ni una auditoría humana.
