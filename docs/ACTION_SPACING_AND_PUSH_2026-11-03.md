# Acciones, zona pulsable y prueba push de las 19:20

03/11/2026. Continuación D135–D137, solicitada por el usuario. Sin cambios en
dinero, cuotas, datos de personas, Rules, índices, IAM o claves.

## Biblioteca visual

- AppButton reserva separación exterior con tokens: vertical AppSpacing.sm y
  horizontal AppSpacing.xs. Evita bordes pegados entre botones y da aire antes
  y después del texto. Se aplica también a ghost/outline/compact, sin ir
  duplicando estilos o separadores por feature. Conservar los separadores de
  secciones que ya existían y objetivos táctiles del propio botón.
- AppExpandableRow tiene borde de acción y fondo semántico, tanto cerrado como
  abierto, padding del encabezado y separación del contenido desplegado.
  Incluye «Gestionar este espacio» y las filas desplegables del historial.
- AppControlFeedback conserva las restricciones de su padre con StackFit.passthrough.
  La disposición anterior podía dejar el hijo al ancho de su etiqueta aunque
  Expanded le hubiera reservado todo un segmento. No es solo una diferencia de
  color: ahora el control recibe la zona realmente visible.
- AppChoiceBar llena expresamente el ancho de cada opción con el TextButton.
  Ingreso/Retirada y demás barras de selección responden en el hueco interior,
  no únicamente al tocar letras. Se conservan selected, disabled, foco y B08.

Esto cubre los casos señalados: Editar grupo/Historial administrativo,
Añadir persona/Abrir papelera, Ver ficha y texto anterior en ambos informes,
Repartir por meses/Corregir/Anular, Ajustar este mes y otros AppButton sin
separadores. No cambia navegación ni introduce animaciones, blur, capas
persistentes o mediciones intrínsecas en listas. D131 se conserva.

«Comprobar registro» muestra ahora loading y un mensaje al terminar: éxito,
no registrado o error. El callback sigue pasando por su provider; no se
llama a Firebase desde la pantalla ni se envía una notificación de prueba.

## Diagnóstico de las 18:00

Cron job 2 sí ejecutó su SQL a `2026-11-03T17:00:00.076683Z`, con estado
succeeded. HTTP devolvió 200 con attempted=1. El registro técnico de entrega
de Firestore quedó **unregistered**, no sent.

Además, el destino de la primera entrega era incorrecto para la cuenta que el
usuario estaba usando: se había reutilizado la antigua cuenta DEMO
JDQpjp5XtFTDOoVgK5Rbc9EGUHB2 en demo-comunidad-20261020. El nombre visible
coincidía y no acreditaba identidad. No atribuir el fallo al APK visual ni dar
esa prueba por entregada. No asumir ese UID para futuros envíos manuales.

El usuario identifica su cuenta actual como propietaria de **Catequesis**.
Lectura del grupo y membresía activa permitió resolver sin cambiar roles:

- groupId: AuXu3Jg8oRW86NqLLEO9.
- uid: 8UXIz070Z9TTm4hrJcwi8OD8qoK2.
- Registro actualizado al pulsar Comprobar: `2026-11-03T18:17:49.089Z`.

No se imprimieron tokens ni secretos. No se borraron registros de otras cuentas.

## Prueba de las 19:20: recepción confirmada

Se añadió el job 4, boteparroquial-test-20261103-1920, a las 18:20 UTC /
**19:20 Europe/Madrid**. Función notification-probe desplegada y destino
corregido antes de la hora (última publicación a las 19:19:50 del portátil).
SQL reproducible: supabase/notification_probe_1920_20261103.sql.

Resultado real:

- Cron: succeeded, inicio `2026-11-03T18:20:00.048741Z`.
- Entrega: **sent**, confirmada `2026-11-03T18:20:03.979Z`.
- Registro seguía vigente para la cuenta de Catequesis.
- Usuario confirma **«Sí, ha llegado»** en el móvil.

Título: **BoteParroquial · Prueba 19:20**.
Cuerpo: «Este es el aviso de prueba que pediste. No cambia cuotas ni movimientos.»
Lugar: notificaciones de Android/cortina/pantalla bloqueada, con app en segundo
plano; esta prueba puntual no añade una falsa cuota a la bandeja de la app.

No necesitó instalar el APK nuevo: la capacidad push ya estaba en el instalado.
La actualización sí es necesaria para ver los cambios visuales y la confirmación
de registro de esta entrega. La prueba de las **20:00 de hoy** se conserva y su
destino también queda en Catequesis, con título «BoteParroquial · Prueba 20:00».
No afirmar todavía su recepción ni la de otros dispositivos/iOS.

Siguen reserva duradera y ausencia de reintento incierto, ventanas fechadas
de diez minutos y autenticación con el secreto existente del proyecto aislado.
Jobs de prueba se retiran tras ejecutar su SQL. Cron habitual job 1 intacto,
sin modificar preferencias del usuario, crear claves o cargar secretos nuevos.

## Comprobaciones

Cinco casos dirigidos distintos, sin suite completa:

1. Selector y botón Expanded: toques lejos de la etiqueta, ambos temas y disabled.
2. Separación real texto/botones y botones horizontales, borde y apertura desplegable.
3. Bandeja/preferencias, confirmación de registro, consentimiento y revocación
   con texto ampliado en ambos temas.
4. Formulario compacto e ingreso con cuota, después de los márgenes nuevos.
5. Deno: fechas, concurrencia, último registro, resultado incierto y retirada.

Logs locales .dart_tool/action-spacing-hit.log, action-notification-feedback.log,
action-compact-regression.log y action-probe-test.log. Los cuatro casos Flutter
y el caso Deno pasan. Captura de notificación no solicitada: la confirmación
del usuario acredita solo la recepción descrita, no toda la matriz funcional.

`flutter analyze --no-pub`: sin incidencias, log action-spacing-analyze.log.
Ambos APK compilados, sin instalar/abrir por el agente:

- Profile: `build/app/outputs/flutter-apk/app-profile.apk`, SHA-256
  `3f156c0129302f70a5b68b13062671dcc448469a0653053b7fe029f3bb74be92`.
- Debug: `build/app/outputs/flutter-apk/app-debug.apk`, SHA-256
  `fa0233dd89240ea20f692ffeeb11c4cc4c57eea98f17b98553dd4ebf8cef1abc`.

Logs action-spacing-profile.log / action-spacing-debug.log. Rules conserva
SHA-256 `fee05c4c229be0c907840b47c6c5269213c2f419955620c6d7d8f81f75556055`.
Guía actualizada en sección 25, con secciones 23/24 reordenadas tras la 22 y
comando de instalación directa que conserva datos. Los hashes de informes
anteriores son históricos; no usarlos para identificar el nuevo APK.

```powershell
& "C:\Users\aleja\AppData\Local\Android\Sdk\platform-tools\adb.exe" -s 00166155L000316 install -r "build\app\outputs\flutter-apk\app-profile.apk"
```

Validación física de los nuevos bordes y áreas pulsables pendiente; usuario ejecuta.
