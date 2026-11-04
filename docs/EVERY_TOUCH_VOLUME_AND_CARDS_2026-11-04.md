# Toques, volumen, perfil y tarjetas — D152–D153

## Sonidos: causa y cambio

Había dos descartes deliberados: el repositorio agrupaba escritura (400 ms) y
filtraba eventos cercanos (65 ms); el reproductor rechazaba un efecto mientras
ese mismo efecto seguía activo. El usuario pide ahora cada toque/edición, lo que
sustituye la selección anterior de ráfagas D145/D150.

AppSoundSurface envuelve la app Flutter, incluidos sus Navigator/menús/diálogos,
y emite un tap por pointer-down. También suenan las zonas sin acción y el inicio
de un gesto de desplazamiento, no cada fotograma del arrastre. No participa en la
arena de gestos ni ejecuta callbacks de negocio. Los tap semánticos de componentes
durante ese mismo toque se suprimen hasta terminar el frame para evitar duplicación;
siguen disponibles para activaciones sin puntero, como accesibilidad/teclado.

AppTextField emite typing por cada edición del usuario, sin agrupar ni limitar por
tiempo. Incluye un sonido genérico en campos de contraseña por la petición de todo
texto; nunca envía el texto, las teclas ni credenciales al audio. Restauraciones
programáticas no son ediciones. El teclado/Google/cámara del sistema fuera de
Flutter no se intercepta; escribir en los campos de la app sí genera feedback.

El repositorio conserva apagado, primer plano y volumen cero como únicas puertas
de reproducción. El servicio admite efectos superpuestos mediante AudioPool,
sin la exclusión de efecto ocupado; conserva cancelación al silenciar/suspender
y eliminación de recursos. Las acciones no esperan al sonido. No se cambian los
cinco WAV ni se añaden dependencias o permisos.

## Volumen local

AppVolumeSlider muestra 0–100 %, con Probar sonido en Ajustes de apariencia.
El nivel se aplica durante el ajuste; el archivo se guarda al soltar el control,
sin una escritura por cada movimiento del dedo. Cero evita efectos; desactivado
o segundo plano siguen prevaleciendo. Sonidos del sistema/silencio y rutas de audio
siguen mandando; no se fuerza el volumen del móvil ni se interrumpe otra app.

UiSoundSettings es puro: enabled y volumePercent entero. La configuración nueva
ui-sounds.json tiene versión 1 y se publica mediante temporal/rename, con escrituras
serializadas. Si no existe se lee ui-sounds.txt antiguo; off permanece apagado y
se mantiene el nivel inicial suave del 18 %. No se sobrescribe ni elimina el archivo
antiguo. Volumen de escritura al 45 % del nivel elegido, resto al nivel elegido.
La preferencia pertenece al móvil, no a una cuenta o grupo y no cambia avisos push.

UI → provider → UiSoundRepository → UiSoundService/DeviceUiSoundService. Surface,
slider y eventos viven en Design System; SDK y archivos siguen encapsulados.
El visor de copias hereda solo el callback de presentación, sin acceso a SDK remoto.

## Perfil y grupos

- Perfil: foto y Cambiar mi foto en una fila, con botón flexible a su derecha.
  Se conserva el tamaño editor del avatar y sus permisos/flujo de edición.
- Tus grupos: saldo de tamaño hero, primero y con separación superior pequeña
  inmediatamente bajo la portada; descripción después si existe. Ya no depende
  de una fila de altura ligada a la descripción. Se retiran rol y EUR de la tarjeta;
  dentro del grupo se mantienen. El símbolo monetario del saldo conserva la moneda
  del grupo. Esquinas, nombre sobre foto y entrada por toda la tarjeta se conservan.

## Verificación realizada

Seis casos dirigidos distintos, sin suite general:

1. UiSoundRepository: doce ediciones rápidas sin descarte, nivel aplicado,
   preferencia apagada, segundo plano, cero y fallo de audio no bloqueante.
2. Componentes: texto/restauración, contraseña sin contenido transmitido,
   selectores, casilla/interruptor y confirmación.
3. Surface: botón compartido sin duplicado, diez toques rápidos en control normal,
   zona libre y apertura/selección de desplegable, sin interferir con las acciones.
4. Archivo real local temporal: migración de off, guardado/restauración del nivel
   y apagado. Sin reproducción nativa ni SDK de datos.
   Archivos ui_sounds_test.dart y sound_surface_and_preferences_test.dart;
   log .dart_tool/every-touch-tests.log, cuatro casos superados.
5. Login/perfil/logout conserva navegación y botón Google bajo la nueva surface.
   auth_flow_test.dart; log .dart_tool/every-touch-auth.log, superado.
6. Grupos/edición/perfil/informes con texto ampliado mantiene flujo sin excepciones.
   full_product_progress_test.dart; log .dart_tool/every-touch-profile.log, superado.

Análisis limpio: .dart_tool/every-touch-analyze.log. Profile compilado correctamente:
.dart_tool/every-touch-profile-build.log. APK build/app/outputs/flutter-apk/app-profile.apk,
128,3 MB según Flutter. SHA256:
b56b224345bc491c07166b59118efdd89cae0d2fd95428b920f50088a0f1877e.
diff --check limpio. No instalado ni ejecutado por el agente.
No hay lecturas/escrituras remotas, Rules, índices o datos de prueba nuevos.

## Pendiente físico

El usuario instala y ejecuta. Escuchar sonidos nativos rápidos, nivel y persistencia,
apagado/silencio, desplazamiento y navegación sin tirones. Revisar foto/botón a la
derecha y saldo bajo portada con descripción corta/larga. No se han generado
capturas ni se da por validada la apariencia, audibilidad o iOS.
Guía móvil sección 30.

## Corrección D154 — Dos columnas bajo portada

Por precisión del usuario, la descripción va a la izquierda y el saldo grande a
la derecha, en la misma fila debajo de la foto. AppGroupPreview usa AppAdaptiveRow
con alineación superior: descripción corta o larga no empuja el saldo abajo.
FittedBox.scaleDown ajusta solo si el importe no cabe; se mantiene hero cuando
cabe. Con texto ampliado o falta de ancho se admite apilar para accesibilidad.
Sin EUR/rol/Entrar; imagen, radios y acción se conservan. No se modifican sonidos,
datos o permisos. No se añaden pruebas para este ajuste visual reversible.
Análisis: .dart_tool/group-card-columns-analyze.log. Profile:
.dart_tool/group-card-columns-profile.log. Usuario valida físicamente.

D154: análisis y diff --check limpios, profile compilado en
build/app/outputs/flutter-apk/app-profile.apk (128,3 MB según Flutter).
SHA256 c08285db8242949279d6158ddd67d8539139762c2c17ff70e852fab51bda494d.
No instalado ni ejecutado por el agente.
