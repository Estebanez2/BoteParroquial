# Orientación vertical — D167

Petición: la app siempre en vertical, sin rotación horizontal.

- main.dart solicita solo DeviceOrientation.portraitUp antes de inicializar Firebase
  y mostrar la UI. Configuración global de arranque, sin lógica en pantallas.
- MainActivity Android declara screenOrientation=portrait desde el lanzamiento.
  El editor UCrop ya tenía portrait; se conserva.
- Info.plist iOS/iPad solo admite UIInterfaceOrientationPortrait. UIRequiresFullScreen
  habilitado para que iPad no requiera todas las orientaciones para multitarea.
  Implica no usar Slide Over/Split View en iPad, conforme a la configuración Flutter.

Límites del sistema: Android 16+ puede ignorar restricciones de orientación en
pantallas de al menos 600 dp. No añadir opt-outs ni trucos de tamaño de pantalla.
Cámara, galería, selector de compartir y Google externos conservan su configuración.
Referencia oficial: https://api.flutter.dev/flutter/services/SystemChrome/setPreferredOrientations.html

Validación: Info.plist analizado como XML y ambas listas solo contienen Portrait;
full screen true. Sin pruebas de dominio nuevas por este ajuste de arranque/configuración.
flutter analyze sin incidencias. Release 1.0.6+7 compilado (137,6 s). aapt confirma
MainActivity screenOrientation=0x1 (portrait), también UCrop, y versionCode 7.
Firma D156 comprobada con apksigner. 75.860.541 bytes; SHA-256:
`907329543e3930f8193a1af9145128bb98a1c7e4e36f27e18f2e03ec2067325b`.
APK: `build/app/outputs/flutter-apk/app-release.apk`.
Usuario instala/ejecuta. iOS requiere Mac/Xcode,
sin compilación ni prueba física aquí. No cambios remotos ni nueva firma.

Comprobar en móvil: activar rotación automática del teléfono, abrir la app y girarlo
en Inicio, grupo, formularios, Apariencia y copia local. La interfaz propia debe
permanecer vertical; volver del editor de foto y comprobar de nuevo. No dar por
probado en todos los sistemas con solo compilar el APK.
