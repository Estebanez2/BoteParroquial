# Selector visual, paletas expresivas y movimiento — 02/11/2026

## Acuerdos y cambios (D125–D127)

El usuario elige **cuadrado y barra arcoíris**, manteniendo hexadecimal completo;
pide conservar la primera paleta y sustituir las otras por direcciones mucho más
distintas, incluyendo Cyberpunk y Cartoon. Durante la tarea añade pulsación
completa antes de actuar y transiciones de pantalla en toda la app. Todo se
implementa en la biblioteca visual compartida y su adaptación de routing, sin
dependencias nuevas ni SDKs externos.

### Selector intuitivo

AppColorField conserva su API y abre el mismo panel. AppColorPlane presenta un
cuadrado: blanco a la izquierda, tono puro a la derecha y negro abajo. Tocar o
arrastrar mueve el círculo y actualiza color/vista previa/hexadecimal. AppHueSlider
muestra el espectro completo y cambia el tono de base. Puede escribirse el código
completo de seis cifras, con o sin #; inválido bloquea «Usar este color».

No se persiste nada hasta confirmar el color y guardar la paleta en su editor.
La paleta conserva el ejemplo claro/oscuro y tres semillas RGB. Hay ajuste con
flechas de teclado y semántica de intensidad/luminosidad; incremento/decremento
anuncian su valor resultante. El panel permite desplazarse con teclado visible.
No se han añadido fuentes, imágenes ni servicios para renderizar el selector.

### Paletas nuevas

Atlántico conserva sus tokens de color anteriores, en ambos modos. Las otras
cuatro cambian colores y fondos; la generación compartida ajusta tonos legibles:

| Nombre visible | Colores base | Identificador persistido |
| --- | --- | --- |
| Atlántico | Azul, ámbar, lavanda | atlantic |
| Cyberpunk | Amarillo ácido, cian, fucsia; fondos violeta | iris |
| Cartoon | Azul eléctrico, rojo, amarillo; crema/tinta | coral |
| Arcade | Verde radiactivo, uva, naranja; fondos verdes | forest |
| Pop Art | Mandarina, violeta, lima; rosa/vino | graphite |

Se mantienen los identificadores locales para no perder la selección existente:
quien tenía Iris verá ahora Cyberpunk, por ejemplo. Las paletas propias, letras y
modo siguen guardados igual. No se toca el archivo en segundo plano para migrar.
AppPaletteCatalog centraliza nombres/descripciones; AppColors centraliza colores,
fondos y contraste. Los colores semánticos de aviso/error/éxito no cambian su función.

### Pulsación y navegación

AppPressFeedback controla la secuencia en AppButton, AppIconButton y AppCard
interactiva: presión hasta 0,97 y retorno, 140 ms por tramo como máximo, antes de
ejecutar el callback. Mantener pulsado conserva el feedback; un toque corto ya no
lo corta. Se ignoran activaciones repetidas durante el ciclo. Deshabilitar o
desmontar cancela la acción pendiente; cancelar el gesto no dispara ninguna.
Movimiento reducido llama a la acción inmediatamente y sin escala. No se animan
cifras económicas ni se conceden permisos desde la presentación.

AppPageTransitions/AppSlidePageTransitionsBuilder definen deslizamiento horizontal
y desplazamiento secundario de la página anterior. AppTheme lo aplica a las rutas
Material; Apple conserva transición nativa con guardia de movimiento reducido.
Editores de personas/fotos que usan PageRouteBuilder reutilizan la misma función;
AppDialog y AppBottomSheet reutilizan tokens de duración y noAnimation al reducir
movimiento. Menús y otros controles conservan sus animaciones nativas existentes.

Se detectó un problema real: go_router 18.0.2, en esta instalación, consulta
MaterialApp de material_ui, mientras la app usa el SDK Flutter. Su detección
escogía NoTransitionPage, por lo que modificar solo PageTransitionsTheme no bastaba.
`core/routing/app_route.dart` crea MaterialPage del SDK explícitamente con la misma
pageKey, parámetros, restorationId y estructura de rutas. Tanto el router principal
como el del visor la utilizan. No se cambia go_router ni sus paquetes transitivos.
La geometría/transición continúa en design_system, sin copiarla en features.

Referencia consultada: [PageTransitionsTheme de Flutter](https://api.flutter.dev/flutter/material/PageTransitionsTheme-class.html).

## Evidencia

Trece pruebas dirigidas distintas superadas, sin ejecutar la suite completa:

- Cuatro nuevas: cuadrado/arcoíris/hex/validación; pulso completo, doble toque,
  deshabilitación y movimiento reducido; tarjeta/navegación/atrás con transición
  real; cuatro paletas, modos, conservación básica de Atlántico y IDs anteriores.
- Cuatro de apariencia: contraste de las diez variantes, persistencia, carga
  tardía/reintento y UI con texto ampliado.
- Dos seleccionadas de Design System: botón ocupado/deshabilitado y cancelación
  de gesto con movimiento reducido.
- Una de personas: validar, crear, editar, descartar y activar/inactivar.
- Una de fotos: elegir/editar actual/cancelar/guardar explícitamente.
- Una del visor: dashboard, Actividad, Atrás, Participantes y aviso fijo, sin
  acciones de escritura y sin enlazar su contenedor aislado al vivo.

Las pruebas detectaron y permitieron corregir: semántica ajustable sin valores
incrementados; inicialización tardía del controlador al desmontar en movimiento
reducido; páginas sin transición. Se ajustaron observaciones al frame real y el
test del visor permite completar E/S de su caché entre frames. Repeticiones
limitadas a fallos/cambios afectados; no se declara exitosa una ejecución fallida.

Tres capturas simuladas revisadas en `.dart_tool/color_motion_preview/`:
visual-picker, radical-palettes-light y radical-palettes-dark. Representan el
selector y ejemplos App*, sin datos de Firestore ni aprobación física del usuario.

`flutter analyze --no-pub`: sin incidencias. `flutter build apk --debug --no-pub`:
compilación correcta. APK: `build/app/outputs/flutter-apk/app-debug.apk`.
SHA-256 de esta entrega:
`ed03955341b5711f77b3adfadad77101a4d97f1e8c1a8421bb90f3b129ed4875`.

## Alcance y pendientes

No hay cambios de Rules, índices, Firestore remoto, Supabase, cron, IAM ni planes.
No se instala ni ejecuta la app en móviles. iOS/Mac, gesto nativo Apple y fluidez
de Android con datos reales siguen pendientes de comprobación física. Pasos
**COL-01–COL-04**, sección 19 de GUIA_PRUEBAS_MOVILES.md. Usuario ejecuta la app.
La copia semanal local del portátil permanece aplazada.
