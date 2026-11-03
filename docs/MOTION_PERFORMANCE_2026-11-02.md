# Transiciones por contexto y barra continua — 02/11/2026

Continuación y cierre técnico: **03/11/2026**. La decisión D128 se mantiene con
la fecha en que fue elegida; las comprobaciones de editores y los APK finales
se actualizan al cierre. La ejecución física sigue a cargo del usuario.

## Petición y decisión D128

El usuario comunica tirones y repetición en las transiciones anteriores y pide
alternativas consultadas en Internet, además de animación en la barra del grupo.
Elige **efectos más marcados**, con más desplazamiento y zoom. Esta entrega
sustituye el estilo y los tiempos de D127, conservando su pulso completo,
cancelación, prevención de repeticiones y movimiento reducido.

## Referencias consultadas

- [Material Motion de Google](https://codelabs.developers.google.com/codelabs/material-motion-flutter/):
  patrones distintos según relación entre vistas; Fade Through para secciones.
- [FadeThroughTransition, documentación oficial](https://pub.dev/documentation/animations/latest/animations/FadeThroughTransition-class.html):
  fundido secuencial y escala de entrada, apropiado para navegación inferior.
- [Buenas prácticas de Flutter](https://docs.flutter.dev/perf/best-practices):
  reutilizar subárboles durante las animaciones y limitar opacidad/coste de build.
- [Medición de rendimiento de Flutter](https://docs.flutter.dev/perf/ui-performance):
  comprobar en dispositivo físico y modo profile; debug no representa release.

Se adaptan esos patrones con primitivas del SDK detrás de componentes App*.
No se incorpora una dependencia externa ni se distribuyen APIs de terceros por
las pantallas. No se copian imágenes, assets ni ejemplos de producto.

## Cambios

AppMotionPage transporta intención visual, sin reglas ni nombres de negocio:

| Contexto | Presentación Material |
| --- | --- |
| Entrar en un grupo | Zoom 90–100 % y aparición |
| Secciones del grupo | Fundido secuencial y escala de entrada 96–100 % |
| Formularios y editores de personas/fotos | Subida del 16 % y aparición |
| Otras pantallas | Avance horizontal corto del 10 % y aparición |

AppContextPageTransitionsBuilder y AppPageTransitions centralizan efectos y
curvas. Duración de ruta Material: 240 ms; barra: 180 ms. La página anterior ya
no se desplaza en paralelo. Apple conserva su transición/gesto nativos en rutas
Material; los editores manuales comparten la apertura vertical. Movimiento
reducido omite efectos; los controles conservan acción inmediata.

El pulso conserva presión/retorno completos y sus protecciones, pero pasa de
140 a 80 ms por tramo: espera máxima de 160 ms, en lugar de 280 ms. No hay
temporizadores de navegación en las features ni esperas para las pestañas.

GroupNavigationShell mantiene una única barra fuera del Navigator de secciones,
tanto en vivo como en el visor de copias. AppNavigationHost evita duplicar barras
de los AppScaffold internos. El indicador se desplaza, el icono seleccionado
crece ligeramente y cambia el estilo del texto. Su estado visual no se recrea al
cambiar de sección. No se introduce una caché de pantallas, datos ni permisos.

Se mantienen rutas, parámetros, retorno al resumen y después a Tus grupos,
guards y comprobación reactiva de membresía. Los editores manuales se abren
en el Navigator raíz para cubrir la barra y conservar pantalla completa: no
dejan pestañas detrás con las que saltarse los cambios sin guardar. El visor conserva su
ProviderContainer independiente, SDKs bloqueados y aviso fijo de solo lectura.

AppReveal elimina la combinación anterior de Opacity reconstruida, traslación,
escala y escalonamiento largo. Usa FadeTransition breve con hijo estable y no
añade entrada propia cuando su ruta ya está animándose. RepaintBoundary aísla
el contenido de las transiciones. Son reducciones concretas del trabajo visual;
sin traza en móvil no se atribuyen todos los tirones a una causa ni se garantiza
una frecuencia de fotogramas.

## Validación

Siete casos dirigidos distintos superados, sin ejecutar la suite completa:

- `context_motion_test.dart`: cuatro contextos, hijo sin reconstrucción por frame
  y reducción de movimiento.
- Dos seleccionados de `color_picker_motion_test.dart`: pulso protegido y rutas.
- Uno seleccionado de `design_system_test.dart`: entrada eficiente/reducida.
- Uno de `dashboard_test.dart`: navegación, permisos y barra persistente con
  posición intermedia y final distintas. El tramo de movimiento activa las
  animaciones que el fixture original deshabilitaba por accesibilidad. Comprueba
  también que Añadir persona cubre la barra y que al volver esta se recupera.
- Uno seleccionado de `daily_snapshots_test.dart`: visor, retorno y restricciones.
- Uno seleccionado de `photos_test.dart`: elegir/editar actual/cancelar/guardar.

Se corrigieron las observaciones del test sin ocultar fallos: aislar las cuatro
primitivas del efecto extra de MaterialApp, habilitar movimiento solo en el
tramo que comprueba interpolación de la barra y proporcionar un repositorio
de personas en memoria al abrir el editor desde el fixture de dashboard.
Las repeticiones se limitaron a los casos afectados por esos cambios y por la
versión final de las rutas.

`flutter analyze --no-pub`: sin incidencias. Compilaciones debug y profile
correctas, ambas sin instalación ni arranque. SHA-256:

- `build/app/outputs/flutter-apk/app-debug.apk`:
  `fda71855c3b24c292f54234415cdc7638530b5d99c3a94d6ffa57b7862573a8c`.
- `build/app/outputs/flutter-apk/app-profile.apk`:
  `d68a0120bfa602b9acf480668461408e590d5a9af8faa329e53416cd1d70342c`.

Firma Android verificada en ambos APK: mismo certificado de desarrollo, sin
cambio de identidad para la actualización. No equivale a probar Google Sign-In
en dispositivo. Compilaciones finales del 03/11/2026, posteriores al ajuste de
Navigator raíz de los editores. Los hashes de compilaciones intermedias no
identifican estos APK finales.

Logs locales: `.dart_tool/motion-refresh-{context,controls,reveal,dashboard,snapshot,photos}.log`,
`motion-refresh-analyze.log`, `motion-refresh-debug.log` y `motion-refresh-profile.log`.

Los casos cubren movimientos distintos y contenido sin reconstrucciones por
frame; pulso/doble toque/deshabilitación; rutas/Atrás/movimiento reducido;
AppReveal; navegación real del grupo con indicador persistente y posiciones
intermedias; navegación del visor y sus restricciones.

## Prueba física pendiente

Para valorar fluidez, usar el APK **profile** actualizado; debug queda disponible
para desarrollo. Ningún APK de esta entrega se ha instalado o ejecutado en un
móvil. No se afirma que los tirones estén resueltos sin esa comprobación.

Recorrido **ANI-01–ANI-04**, sección 20 de GUIA_PRUEBAS_MOVILES.md. Android con
datos reales, texto ampliado y movimiento reducido, e iOS/gesto nativo pendientes.
Sin cambios de Firestore remoto, Rules, índices, Supabase, IAM o configuración.
