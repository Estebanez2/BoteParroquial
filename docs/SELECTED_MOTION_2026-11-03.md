# Animaciones elegidas en la aplicación — 03/11/2026

## Decisión D130 y alcance

El usuario confirma el reparto de los efectos del laboratorio y decide
**conservar el laboratorio por ahora**. La selección se aplica de verdad a los
componentes compartidos; la fluidez y aprobación física siguen pendientes.

| Elemento | Efecto elegido |
| --- | --- |
| Botones principales y confirmaciones destructivas | B07: banda de brillo |
| Secundarios, iconos, menús y selectores AppChoiceBar | B08: onda exterior |
| Intento con datos incompletos/incorrectos | B04: sacudida, sin ejecutar el envío |
| Botón deshabilitado visible | B05: balanceo, sin ejecutar su acción |
| Barra del grupo | N01: indicador deslizante, sin rebote/escala del icono |
| Navegación general | P03: entrada completa desde la derecha |
| Formularios y editores | P05: entrada completa desde abajo |

Los controles propios componen AppControlFeedback. Usa hijos estables, pintura
para brillo/onda y transformaciones para rechazos. Duración: 320 ms; no se
superpone el antiguo pulso de escala. Los menús mantienen su selección nativa:
sus disparadores aplican el feedback antes de abrir. Los pickers y controles del
SO conservan su comportamiento propio; no se reemplaza la UI nativa de cámara,
Google o recorte.

## Validación, acciones y seguridad

AppButton recibe una función de validación explícita del formulario; no deduce
permisos, requisitos ni valida botones de Cancelar por encontrar un Form cerca.
Se conectan personas, perfil, grupos, transferencia, movimientos, devoluciones,
cuotas, reparto mensual, invitaciones y paletas. Los validadores del dominio se
siguen llamando a través de los controllers/repositories existentes. No se
trasladan cálculos económicos o permisos al Design System.

La validación se comprueba antes del efecto y otra vez al terminar por si el
borrador cambió mientras tanto. Hay un solo ciclo activo por control. Desmontar,
marcar ocupado/deshabilitar o dejar de ser la ruta actual cancela una
acción pendiente. Un control con loading no inicia efectos de rechazo ni otra
operación. Los deshabilitados mantienen onPressed nulo y semántica deshabilitada;
el gesto adicional solo dibuja B05, sin convertirlo en una acción habilitada.
Los errores posteriores de red/concurrencia conservan su presentación existente;
no se presentan como campos incompletos ni se reintentan automáticamente.

## Entrar a un grupo desde su tarjeta

AppGroupEntry pinta una onda que recorre la tarjeta durante **un segundo**.
Después mide su rectángulo respecto al Overlay del Navigator correspondiente y
pasa AppGroupOrigin a la ruta. La página crece desde ese rectángulo real hasta
llenar la pantalla, con el radio suavizándose. El contenido de destino permanece
estable durante la transformación. La expansión de ruta usa el token de 240 ms;
no añade otro pulso o un segundo efecto de botón antes de la onda.

Se conecta en Inicio, grupo ya aceptado de invitación y grupos del visor local.
AppGroupOrigin contiene solo geometría efímera: no se guarda en Firestore,
archivos ni preferencias y no participa en autorización. Una entrada directa,
restaurada o sin tarjeta usa P03; no inventa una tarjeta ni espera un segundo.
Si la tarjeta desaparece o se abre otra ruta durante la onda, no navega después.
El acceso real al grupo sigue comprobándose por sus providers y reglas actuales.

## Navegación dentro del grupo

AppMotionPage lleva un índice visual de sección. GroupNavigationShell conserva
la barra y publica AppSectionMotionScope, con origen y destino transitorios:

`Inicio (0) → Actividad (1) → Participantes (2) → Informes (3)`.

Un índice mayor entra por la derecha y el anterior sale a la izquierda; un índice
menor hace lo contrario. Se cubren salto entre hermanas y vuelta a Inicio con la
página previa conservada. Personas/Miembros pertenecen al índice 2; sus aperturas
de detalle no inventan un cambio de pestaña. N01 desplaza el indicador sin esperar
un efecto de botón (180 ms). Rutas, parámetros, historial de Atrás y guards se
conservan, incluido el router de copias con su ProviderContainer independiente.

Los formularios manuales de personas/fotos/paletas/primeros meses comparten
AppPageTransitions.formRoute y cubren la barra mientras se editan. Los paneles
AppBottomSheet se alojan fuera del Navigator de secciones mediante el contexto
de AppNavigationHost: cubren la barra sin saltar al Navigator de otra app/visor
ni escapar del contenedor aislado. No se cambia a rootNavigator global para
resolver este problema. Compatibilidad iOS conservada en código, sin prueba
física acreditada; la selección de formularios/grupos prevalece sobre la antigua
transición uniforme de Cupertino para esos contextos.

Movimiento reducido omite efectos, transformaciones y espera de un segundo.
No se modifica silenciosamente esa preferencia del SO. No hay cambios remotos,
de Rules, índices, SDKs, IAM, configuración de avisos ni datos de prueba nuevos.

## Evidencia comprobada

Nueve casos dirigidos distintos superados, sin suite completa:

- Tres nuevos de selected_motion_test: B07/B08, validación/B04/B05 y loading;
  cancelación al perder acceso/cambiar datos/desmontar; onda de un segundo,
  rectángulo inicial real, expansión y ausencia de navegación tardía desde otra ruta.
- Dashboard: permisos, indicador persistente e interpolación, entradas reales
  izquierda/derecha al saltar pestañas y volver a Inicio, editores y Atrás.
- Context motion: ejes P03/P05 y contenido sin reconstrucciones por fotograma.
- Personas: validar, crear, editar/descartar y activar/inactivar, con sus menús.
- Movimientos: céntimos, advertencias, corrección confirmada y anulación sin
  doble saldo, usando repositorios en memoria.
- Visor: entrada al grupo guardado y navegación con aviso fijo y escrituras bloqueadas.
- Menú Añadir: conserva llave y acción Entrar con código tras el disparador B07.

Se corrigió un problema real de alojamiento de paneles, que quedaban bajo la
barra de grupo, en AppBottomSheet/AppNavigationHost. En los fixtures se excluyó
la animación continua del indicador de loading de una espera global, se dejó
el margen de un fotograma al completar el segundo y se aisló la copia automática
sin Firebase del flujo financiero; este último confirma ahora expresamente el
diálogo de revisión del reparto que ya existía. No se relajaron validaciones ni
permisos para hacer pasar las pruebas. Se repitieron solo casos afectados.

Logs `.dart_tool/selected-motion-*`: components, components-recheck, dashboard,
context, persons, movements, snapshot, menu. Los logs iniciales con fallos no
representan comprobaciones superadas; el informe describe su resolución.

`flutter analyze --no-pub`: sin incidencias. Compilaciones debug y profile
correctas; no se han instalado ni ejecutado en un móvil. APK de esta entrega:

- `build/app/outputs/flutter-apk/app-debug.apk`, SHA-256:
  `0e7eb6fa4afd08751e521ca39da960893932fcb0ffa2e36ce5c082c6d86de940`.
- `build/app/outputs/flutter-apk/app-profile.apk`, SHA-256:
  `1d67fc14393f2d0643baa3e78413ffa7bbd5105e5630cea965df6e3a157f535b`.

Análisis y builds: `.dart_tool/selected-motion-analyze-final.log`,
`selected-motion-debug.log`, `selected-motion-profile.log`. Las reglas locales
conservan SHA-256 `35bf3eec1b7b4ff1a23d297e51368bc7a4ac0b4f58be332b9e9845d8cb7e85f1`.

## Pendiente en móvil

El usuario instala y ejecuta. Guía **SEL-01–SEL-06**, sección 22 de
GUIA_PRUEBAS_MOVILES.md. No hay medición de FPS, aprobación en dispositivo,
validación de iOS/APNs ni entrega push acreditadas por esta tarea.

El laboratorio D129 sigue accesible en Inicio de debug/profile por petición
expresa. No retirarlo ni reemplazar las elecciones por otras sin indicación.
