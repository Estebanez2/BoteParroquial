# Navegación de grupo: corrección de renderizado (D131)

03/11/2026. El usuario comunica tirones importantes al cambiar con la barra.
Se mantiene la elección D130 y el laboratorio temporal. Sin cambios de datos,
Rules, índices, dependencias, secretos o despliegues remotos.

## Diagnóstico y cambio

La revisión del código encontró trabajo superpuesto al desplazamiento: montaje
de pantallas de destino con sus providers/cálculos y composición, animaciones
del origen aún activas, y curvas de reversa easeOut que aceleraban la salida al
final en vez de acompañar la entrada. RepaintBoundary por sí solo no congela una
pantalla durante una transición personalizada.

AppDeferredSection recibe el builder de la feature desde appRoute. Durante la
entrada propia o la del grupo exterior muestra un AppSkeleton estático, adecuado
a la sección; monta el contenido después de terminar el movimiento y presentar
ese fotograma. Las consultas posteriores conservan sus indicadores reales de
carga/error. No inventa datos, importes ni un estado de conexión.

Una sección ya montada conserva su aspecto durante la salida mediante
SnapshotWidget permisivo. Su imagen solo vive en memoria de renderizado durante
el movimiento; no se escribe en disco ni es una copia diaria. Al acabar se libera.
TickerMode pausa efectos y suscripciones Consumer de Riverpod dentro de ese
árbol; las decisiones de identidad/acceso se observan fuera, en la shell.
AppSectionRenderScope transmite una clave opaca y permiso de congelación: cambio
de cuenta/grupo/membresía/disponibilidad invalida el cuadro y presenta el guard
actual. No se mantienen pantallas mediante caché ni keepAlive entre cuentas.
En web no se activa la captura. Movimiento reducido omite espera y captura.

Las curvas reversas easeIn acompasan entradas easeOut en lugar de salir con una
aceleración tardía. Se conservan lados por índice, indicador N01 persistente,
P03/P05, botones B07/B08/B04/B05 y onda de un segundo/zoom al abrir grupo.
El router aislado de copias usa la misma infraestructura sin escapar de su
ProviderContainer ni permitir escrituras.

Fuentes oficiales consultadas: [prácticas de rendimiento Flutter](https://docs.flutter.dev/perf/best-practices),
[allowSnapshotting](https://api.flutter.dev/flutter/widgets/TransitionRoute/allowSnapshotting.html)
y [SnapshotWidget](https://api.flutter.dev/flutter/widgets/SnapshotWidget-class.html).
Comportamiento TickerMode/Consumer comprobado en el código instalado de Riverpod
3.4.3. Esta es una corrección del camino de renderizado, no una medición previa
que atribuya porcentajes de tiempo a cada causa.

## Comprobaciones necesarias realizadas

Cinco casos dirigidos distintos, sin suite completa:

- Tres de section_rendering_test: destino sin montar durante el deslizamiento;
  espera de animación exterior y pausa/liberación; cambio de cuenta/retirada de
  acceso que descarta inmediatamente el cuadro congelado.
- Dashboard: barra persistente, dirección real y posiciones acompasadas de las
  páginas, esqueleto antes del montaje, navegación/Atrás/editores y revocación.
- Copia diaria: navegación habitual aislada, aviso fijo y acciones bloqueadas.

Logs: `.dart_tool/section-jank-rendering.log`, `section-jank-dashboard.log`,
`section-jank-snapshot.log`. `flutter analyze --no-pub` limpio, en
`section-jank-analyze-final.log`. Los dos avisos iniciales de API de TickerMode
en el test se corrigieron usando valuesOf; no se ignoraron reglas del analizador.

## APK y medición en dispositivo

APK profile compilado con `--dart-define=TRACE_GROUP_MOTION=true`:
`build/app/outputs/flutter-apk/app-profile.apk`, SHA-256
`752f824d553d2b05cc0e4d028f3d3880aa40356c0f3531a022f149a5496df553`.
Log de compilación: `.dart_tool/section-jank-profile.log`.

APK debug también compilado: `build/app/outputs/flutter-apk/app-debug.apk`,
SHA-256 `b3ad01efead852cef006b59c14272ee3c60509fa984858790da1a4f096c74bca`;
log `.dart_tool/section-jank-debug.log`. `git diff --check` sin incidencias.
Rules conserva SHA-256
`35bf3eec1b7b4ff1a23d297e51368bc7a4ac0b4f58be332b9e9845d8cb7e85f1`.

GroupMotionMetrics está desactivado por defecto; solo profile con ese define
registra líneas GROUP_MOTION. Contienen índices de pestañas, frecuencia del
dispositivo, tiempos build/raster/vsync y conteos frente al presupuesto de frame.
No incluyen cuenta, grupo, nombres, importes ni tokens. Las ventanas de 950 ms
incluyen entrada y carga inmediata; pueden solaparse con toques rápidos. No son
una medición exacta de FPS ni permiten sumar ventanas solapadas como frames únicos.

El A059P estaba conectado y el usuario cambió diez veces entre pestañas con el
APK anterior. dumpsys gfxinfo solo contó un frame de la vista Android y no sirve
como línea base del renderizado Flutter. No se obtuvo una traza Flutter previa.
Se ha pedido instalar/abrir el profile corregido y repetir para medir el resultado;
la fluidez física está **pendiente**, no certificada por las pruebas de widgets.
El usuario instala y ejecuta. No se ha reinstalado ni manipulado su sesión.

El primer intento manual volvió a mostrar tirones, pero la lectura SHA-256 del
APK instalado acreditó que seguía ejecutándose el debug anterior D130
(`0e7eb6fa4afd08751e521ca39da960893932fcb0ffa2e36ce5c082c6d86de940`).
Por eso no hubo líneas GROUP_MOTION. Se facilitó instalación directa con ADB
del profile actualizado antes de atribuir ese resultado al código corregido.

Guía manual: sección 23 de [GUIA_PRUEBAS_MOVILES.md](GUIA_PRUEBAS_MOVILES.md).
No hay validación física iOS ni entrega push acreditadas por este cambio.

Confirmación posterior del usuario, 03/11/2026: tras corregir la ruta de
instalación indica «ahora sí va fluido». Se da por comprobada su navegación
de grupo en A059P con el profile corregido. Los pendientes anteriores de esta
prueba quedan resueltos por esa confirmación, sin certificar FPS generales,
todos los dispositivos, otros efectos ni iOS.
