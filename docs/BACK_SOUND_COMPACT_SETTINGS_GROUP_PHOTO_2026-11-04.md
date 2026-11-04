# Gesto Atrás, sonidos, ajustes y foto al crear grupo — D161–D163

## D161: sonido por tipo de acción y regreso del sistema

- Menús usan click_1–4.wav, la familia anterior de clic normal. Nuevos press_1–4
  para controles normales: 65 ms, carácter de clic mecánico filtrado, sin nota
  sostenida, cuatro variaciones aleatorias sin repetición inmediata. Back y nivel
  se conservan. No vuelven los toques globales ni sonidos de zonas deshabilitadas.
- AppSystemBackSound coordina RootBackButtonDispatcher y NavigatorObservers de
  raíz/secciones. Solo observa, no sustituye permisos, pop ni AppFormGuard.
- Back clásico del sistema: registra su solicitud mientras el dispatcher original
  la delega y emite solo si un observer confirma pop. Deduplica por solicitud lógica
  si la misma acción cierra rutas de raíz y shell. Sin filtro temporal de clics.
- Gesto predictivo/iOS: observer consulta userGestureInProgress durante didPop;
  gesto cancelado sin pop no suena. Botón explícito conserva su evento back, sin
  volver a emitirlo desde observer cuando no hay gesto/solicitud de sistema.
- Misma integración en el router aislado de copias, sin añadir SDKs al contenedor.
- Referencias oficiales y SDK local consultados:
  https://api.flutter.dev/flutter/widgets/RootBackButtonDispatcher/didPopRoute.html
  y https://docs.flutter.dev/platform-integration/android/predictive-back.
  No basta con escuchar didPopRoute para todas las variantes predictivas.

## D162: apariencia compacta

AppSoundSettingsPanel centraliza interruptor, icono de prueba y volumen en fila;
AppVolumeSlider admite presentación compacta sin perder semántica ni rango 0–100.
Quitados A tu manera, el párrafo introductorio, Suaves y solo en este móvil y la
frase Personas, movimientos y el bote de tu comunidad. Tipografía/paletas se
conservan. Preview reproduce el clic real una vez. Silencio/apagado siguen vigentes.

## D163: creación sencilla con foto opcional

- Nuevo grupo sin GroupOpening ni textos promocionales. Campos y foto opcional
  desde cámara/galería. Previsualización 16:9 solo cuando se elige imagen; editar
  o quitar borrador. Picker/cropper existentes preparan el archivo local.
- GroupDraftPhotoController almacena borrador por formulario; cambiar UID lo
  descarta. Seleccionar/cancelar/editar antes del alta no accede a Storage ni exige
  membresía inexistente. PhotoRepository.editDraft edita bytes locales, sin relajar
  access/upload/remove ni los permisos de fotos existentes.
- AppFormGuard protege campos y foto; durante selección/guardado se bloquea salida.
- Usuario elige conservar grupo si falla la foto. GroupManagementController crea
  primero grupo/membresía/persona según opción; después PhotoRepository.upload,
  con comprobaciones vigentes de cuenta/permisos. Dos servicios, sin promesa de
  atomicidad. Si falla Supabase, grupo ya confirmado permanece y se avisa.
- Reintentar dentro de ese formulario reutiliza ID/UID y salta el alta ya confirmada.
  Campos quedan bloqueados y el botón indica Reintentar guardar foto. Si se quita
  el borrador se puede Abrir mi grupo. No crear otro para resolver la subida.
- Al cerrar el formulario el borrador es efímero: se advierte salida sin guardar;
  el grupo existente sigue en Inicio y su foto se puede editar desde allí.
  No se ha añadido subida persistente en segundo plano ni borrado compensatorio.

## Evidencia y pendientes

Siete casos dirigidos distintos, entre system_back_sound_test.dart,
group_creation_photo_test.dart y sound_surface_and_preferences_test.dart.
Tras corregir el tamaño mínimo del panel y la deduplicación raíz/shell, pasan
los escenarios afectados. Navegación confirmada/cancelada/bloqueada, botón sin
duplicación, altura del panel, variación y preferencias, alta parcial con un único
grupo y reintento, picker sin acceso remoto previo.

Análisis final: sin incidencias. APK release 1.0.3+4 compilado (143,0 s), firma
D156 comprobada con apksigner y versión confirmada con aapt. 75.831.857 bytes;
SHA-256: `2c93291056cb40a25812ebe2cdd3c8f77563b6325955a7bb3f3a5dce8ffc11dc`.
Ruta: `build/app/outputs/flutter-apk/app-release.apk`.
Usuario instala/ejecuta. No acreditar
gesto nativo físico, timbre, cámara/cropper/Supabase reales por estas simulaciones.
No cambios remotos, Rules, índices, IAM ni nueva clave; misma firma oficial D156.

## Prueba breve en móvil

1. Actualizar release. Entrar a una sección y regresar con gesto: un tono; volver
   con botón: uno. Cancelar gesto no debe sonar. Formulario con cambios conserva
   confirmación antes de descartar; no se autoriza una salida por reproducir audio.
2. Desplegable: clic normal de 1.0.2. Botones: nuevos clics menos tonales. Probar
   varias pulsaciones, silencio y apagado. Valorar audibilidad/timbre en el móvil.
3. Apariencia: panel compacto, interruptor/volumen/prueba; textos retirados ausentes.
4. Nuevo grupo: rellenar campos, foto opcional con cámara/galería y recorte 16:9;
   cancelar conserva borrador previo. Atrás con foto sin guardar avisa.
5. Crear y confirmar grupo/foto; si la foto falla tras el alta, reintentar en ese
   mismo formulario y comprobar que solo existe un grupo. No borrar datos reales
   ni cortar Internet durante operaciones económicas para probar este caso.
