# Cuota de Firestore, tarjetas y sonidos — D143–D145

## Resultado y diagnóstico

La comprobación de solo lectura contra Firestore devolvió HTTP 429,
RESOURCE_EXHAUSTED, «Quota exceeded.». Ocurrió ya al consultar grupos, antes de
ejecutar las sumas de la gráfica. Android declaraba una red con capacidad INTERNET
y VALIDATED. No hay evidencia de una caída de la base ni de que el móvil hubiera
perdido Internet. El mensaje no identifica qué contador exacto agotó la cuota.
No se han activado facturación ni cambios de plan.

[Firebase explica las cuotas y su consulta en Uso](https://firebase.google.com/docs/firestore/quotas).
Las cuotas gratuitas diarias se restablecen aproximadamente a medianoche del
Pacífico, no a medianoche de Madrid; no se atribuye el error a un contador diario
concreto sin consultar sus métricas.

La app distingue ahora el 429 de los errores de red y permisos. Ofrece las copias
guardadas también por cuota agotada. La caja conserva su caché privada ante un
429, pero no la presenta como confirmación actual ni borra archivos por confundir
el límite con una revocación. Ese error no activa los reintentos de red.
El botón Actualizar gráfica invalida la consulta de caja de la que depende el
panel; antes solo reintentaba el panel y heredaba el mismo error de caja.
La descarga de copias también identifica el 429 y conserva la anterior.

## Cambios visuales

- Gestionar este espacio conserva su borde de color; se retira la tarjeta exterior
  que dibujaba otro marco. AppExpandableRow sigue siendo el componente compartido.
- Editar grupo muestra los campos, sin identidad repetida ni apertura promocional.
  Conserva comprobación de acceso, guardado y aviso de cambios sin guardar.
- Tus grupos utiliza el nombre en una caja sobre la portada, también compartida
  con el encabezado interior por AppCover. Debajo, descripción a la izquierda y
  saldo a la derecha, sin Entrar. Toda la tarjeta sigue siendo pulsable con su
  onda/expansión. Con texto ampliado se apila el contenido para conservar lectura.

## Sonidos acordados

El usuario elige activados por defecto, volumen suave, respeto del modo silencio
y un interruptor local; escritura con un toque por ráfaga, no por cada carácter.
Ubicación: menú de cuenta → perfil → Ajustes de apariencia → Sonidos de la app.
La preferencia es del móvil, independiente de los avisos push y de las cuentas.

Cinco efectos: toque, escritura, confirmación, foto preparada y advertencia.
Se integran en AppControlFeedback, AppTextField, AppSnackbar, menús, desplegables,
barra inferior y en la presentación del borrador de foto. Los controles comunes
emiten eventos semánticos; no contienen SDKs, preferencias ni negocio. Una acción
se ejecuta sin esperar al audio. El sonido de confirmación corresponde al mensaje
de éxito de la operación, no a haber pulsado Guardar. Preparar una foto no significa
haberla subido. Los campos de contraseña no emiten sonidos de escritura ni se
transmite texto al reproductor. Restaurar un controlador tampoco suena.

UI → AppSoundScope/callback de aplicación → provider → UiSoundRepository →
DeviceUiSoundService. El repositorio limita ráfagas/toques y bloquea segundo plano
o preferencia apagada; el servicio encapsula archivo local y audioplayers 6.8.1.
Cinco pools de sonidos locales creados bajo demanda, sin red. Cancelación por
generación evita iniciar sonidos pendientes después de desactivar o suspender.
Android consulta ringerMode sin cambiarlo; atributos sonification/assistanceSonification,
sin solicitar foco de audio. iOS usa categoría ambient. Se detiene al salir de primer
plano. El fallo de audio no debe bloquear una operación.

Efectos de [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds),
CC0, obtenidos de copia pública al fallar la descarga oficial. Procedencia, originales,
conversión a WAV mono y licencia en assets/sounds/SOURCES.md y KENNEY-LICENSE.txt.
Unos 58 KB de WAV, sin sonidos descargados al usar la app. Volumen relativo 18 %,
escritura 8 %; la audibilidad depende del volumen/ruta y ajustes del dispositivo.
No se consideran aprobados auditivamente hasta probarlos en móvil.

## Verificación

Seis casos dirigidos distintos superados, sin suite completa:

1. Política de sonidos: ráfagas, preferencia, segundo plano, confirmación inmediata
   y fallo no bloqueante. ui_sounds_test.dart.
2. Eventos compartidos de toque/escritura/guardado, contraseña y restauración de
   texto sin sonido. ui_sounds_test.dart.
3. Reintento mediante el botón real del panel: primer error de cuota, segunda caja
   válida, gráfica obtenida. trend_retry_test.dart.
4. Clasificación 429/403/503 e integridad de céntimos int64. cash_aggregates_test.dart,
   caso «Céntimos REST».
5. Dashboard, tarjetas, navegación y revocación con texto ampliado. dashboard_test.dart,
   caso «Dashboard:».
6. Creación/edición de grupo, informes y ficha conservados; cabecera de edición
   retirada. full_product_progress_test.dart, caso «Grupos, informes, ficha».

Registros: .dart_tool/sounds-ui-final-tests.log, sounds-and-retry-tests.log,
sounds-cash-test.log, sounds-dashboard-test.log y sounds-group-editor-test.log.
Análisis limpio en .dart_tool/sounds-analyze.log. Profile compilado correctamente
en .dart_tool/sounds-profile-build.log. APK:
build/app/outputs/flutter-apk/app-profile.apk (128,2 MB según Flutter).
SHA256: a6a36e1d7fab4226a6828ae91381576519e4785e12669c9f9bfdf8102ff652f5.
No instalado ni arrancado automáticamente. git diff --check sin errores.

La primera continuación se interrumpió por cuota de la revisión automática de
permisos; la ejecución quedó sin realizar. El usuario pidió seguir y la revisión
permitió reanudar. No se eludió la revisión ni se ejecutó la suite general.

## Límites y pruebas pendientes

El usuario instala y ejecuta. Probar los sonidos, volumen, silencio y conservación
del interruptor tras reiniciar. Revisar las nuevas tarjetas y editar grupo. iOS
necesita Mac/Xcode y prueba física. Una compilación no acredita sonido nativo.
La lectura real de la gráfica queda pendiente de que Firestore admita consultas;
la prueba local acredita el reintento, no elimina una cuota del servidor.

No se modifican documentos remotos, Rules, índices, funciones, credenciales o roles.
Rules local conserva SHA256 fee05c4c229be0c907840b47c6c5269213c2f419955620c6d7d8f81f75556055.
Guía móvil: sección 27 de GUIA_PRUEBAS_MOVILES.md.

## Continuación D146 — Portada más discreta

El usuario pide nombre abajo a la izquierda, letra menor y caja más transparente.
AppCover compartido cambia a headingSmall, caja alfa .28 y degradado inferior
.45 → 0. Afecta a Tus grupos y a la identidad dentro del grupo. No cambia acciones,
datos ni sonidos. Análisis limpio: .dart_tool/cover-bottom-analyze.log. No se añaden
tests para este ajuste puramente visual; compilación profile en
.dart_tool/cover-bottom-profile.log. Usuario instala/ejecuta y valida apariencia.

La nueva comprobación remota de solo lectura sigue devolviendo HTTP 429,
RESOURCE_EXHAUSTED, «Quota exceeded.» ya al consultar grupos. No se ejecutan las
sumas posteriores; no se hacen escrituras ni se altera plan/facturación. No hay
evidencia de borrado de datos o caída total: el servicio responde y rechaza la
lectura por límite. Se puede consultar la copia en menú de cuenta → Copias en
este móvil, sin instalar otro APK para acceder a ella. El APK nuevo aplica el
ajuste visual; no recupera cuota del servidor. No se conoce el contador exacto
agotado sin consultar sus métricas de uso.

Profile D146 compilado: build/app/outputs/flutter-apk/app-profile.apk.
SHA256: 9627dc353488551d95ce5438c2b608e53790b0fd8c64a23ae3eb58c8bab30bcd.
Sin instalación/arranque por el agente; diff --check limpio.

## Continuación D147 — Acceso a copias y portada ausente

Se detecta una segunda vía: REST ya clasificaba 429, pero el SDK de grupos/perfil
convertía resource-exhausted en unknown y sincronización lo convertía en network.
Se conserva ahora FailureCode.resourceExhausted con un mensaje común. Así el
envoltorio de recuperación de Inicio/acceso ofrece copias también para este error.
Se añade el mismo envoltorio al fallo de una tarjeta individual de grupo. Reintentar
y consulta local siguen siendo opciones separadas; el visor aislado no adquiere
un escape al servidor ni se entra en copias automáticamente.

La regresión descubre además que yield* reenviaba los errores del stream sin
pasar por el catch de FirebaseException. El guard de grupos consume ahora con
await for para clasificar el error antes de emitirlo. No basta con añadir una
rama al switch si no se intercepta el error. Corregido y comprobado con un error
real del tipo SDK en la consulta de membresías, sin conexión a base remota.

AppCover sustituye las iniciales por icono de imagen ausente y Sin foto. No hay
descarga adicional: es un marcador visual del Design System con colores del tema,
también al no poder renderizar una imagen. La carga real mantiene su esqueleto;
las fotos válidas de caché se conservan. No cambian las iniciales de avatares de
cuentas/personas ni se borra/migra ninguna foto.

Dos casos dirigidos: cuota del SDK en la consulta de membresías llega clasificada
al consumidor; error de red y cuota permiten ir al catálogo local sin sustituir
reintento ni escapar del visor/denegación. Archivos firestore_quota_recovery_test.dart
y offline_recovery_test.dart; log .dart_tool/quota-sdk-recovery-tests.log.
Ambos superados. No se han creado datos de prueba remotos.
Análisis: .dart_tool/quota-sdk-analyze.log. Compilación: .dart_tool/quota-sdk-profile.log.
No se reejecutan las suites ni las pruebas de sonidos, que no se modifican.

Respuesta sobre plazo: Firebase documenta restablecimiento de cuotas gratuitas
diarias alrededor de medianoche del Pacífico; el 04/11/2026 equivale aproximadamente
a las 09:00 de Madrid. Esa previsión solo aplica si el contador agotado es diario;
el mensaje recibido no identifica el contador. No garantizar una hora sin métricas.
[Fuente oficial](https://firebase.google.com/docs/firestore/quotas).

Auditoría de sonidos: existen tap, typing por ráfagas, photo preparado, success
tras confirmación y warning, con los puntos de integración descritos en D145.
No se afirma que cada control nativo del sistema operativo use esos sonidos ni
que se hayan escuchado/aprobado físicamente. Preferencia y silencio no se alteran.

D147: análisis limpio y profile compilado (128,2 MB según Flutter).
APK: build/app/outputs/flutter-apk/app-profile.apk.
SHA256: 9c10047c75071c8b4f3e29a22e2d02932870e0197fc874b5824568d45d9f82ce.
No instalado ni ejecutado por el agente. diff --check limpio. Apariencia, acceso
desde el 429 real en móvil y sonido nativo siguen pendientes de prueba física.

## Continuación D148 — Esquinas y estimación de consultas

AppGroupPreview recorta solo las esquinas superiores de la portada con radio
AppRadius.large - AppSpacing.actionBorder; el radio interior deja visible el
borde que antes tapaba la imagen rectangular. Se mantiene el recorte exterior,
contenido, navegación y onda. Cambio visual reversible: no se añaden tests que
solo reflejen el recorte. Análisis limpio en .dart_tool/group-cover-corners-analyze.log;
compilación profile en .dart_tool/group-cover-corners-profile.log. Usuario revisa
en móvil; no se han generado capturas ni dado por aprobada su apariencia.

La cuota gratuita documentada es 50.000 lecturas de documentos por día y proyecto,
compartida por dispositivos y procesos. Ejemplos teóricos sin otro consumo:
10 documentos por consulta → unas 5.000 consultas; 100 → 500; 1.000 → 50.
No son límites garantizados: cada consulta tiene un mínimo, las reglas pueden
leer documentos adicionales, las escuchas cobran cambios/reconexiones según
condiciones y las consultas pueden leer índices. Las sumas agregadas tienen
su propia contabilidad por entradas de índice, no descargan cada documento.
Una copia completa de 1.000 documentos ya supone aproximadamente 1.000 lecturas
de contenido, más su validación/consultas vacías; una por cada móvil acumula uso.
Consultar datos solo desde una copia local no requiere lecturas del servidor.
No se mide ni se atribuye aquí qué flujo agotó realmente el contador.

Fuentes: [cuotas gratuitas](https://firebase.google.com/docs/firestore/quotas) y
[cálculo de lecturas, índices, agregados y reglas](https://firebase.google.com/docs/firestore/pricing).
No hay nuevas lecturas/escrituras remotas ni cambios de plan en esta continuación.

D148: profile compilado en build/app/outputs/flutter-apk/app-profile.apk.
SHA256: 1218698bcd6b4792bea3ebb20735b5d37c6374d077482ce11d8aac7daf0fad3e.
Análisis y diff --check limpios; no instalado ni ejecutado por el agente.
