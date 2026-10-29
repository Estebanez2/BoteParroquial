# Phase 9 — Preparación de notificaciones

Fecha: 2026-10-19. **Preparación parcial; no hay notificaciones activadas.**

Registro histórico de la primera entrega. Registro de dispositivos, preferencias,
bandeja y permisos se incorporan después: ver
[PHASE9_NOTIFICATION_CLIENT_VALIDATION.md](PHASE9_NOTIFICATION_CLIENT_VALIDATION.md).
Los pendientes de este documento reflejan su momento, no el estado posterior.

## Acuerdos

- D091: Supabase ejecutará el trabajo de servidor y FCM entregará las push.
  Firebase mantiene identificación y datos. Sin Blaze ni cambio de plan.
- Recordatorios a las **10:00 de la zona del grupo**, 7 días y 1 día antes del
  último día del mes. El reloj del dispositivo no determina el día del grupo.
- D092: push discreto sin cantidades; detalle económico dentro de la app.
  Los gestores recibirán un resumen por grupo de personas sin cuenta vinculada,
  en lugar de una notificación por persona. Todavía no hay envío ni agrupación.
- La especificación §20 excluye recordatorios para personas inactivas, conservando
  sus obligaciones/historial en informes. §50 requiere cuota mensual pendiente.
- FCM no tiene coste; Supabase Free incluye 500.000 invocaciones de funciones,
  además de sus límites de base, almacenamiento y transferencia. La cuota es
  compartida con otras funciones como fotos. No se promete gratuidad ilimitada;
  los proyectos gratuitos pueden pausarse tras inactividad. El trabajo programado
  deberá acotar lecturas, ejecuciones y destinatarios. No activar facturación.

Fuentes oficiales consultadas el 2026-10-19:
[FCM/precios](https://firebase.google.com/pricing),
[funciones de Supabase](https://supabase.com/docs/guides/functions/pricing),
[plan y límites](https://supabase.com/pricing),
[programar funciones](https://supabase.com/docs/guides/functions/schedule-functions),
[autorización FCM](https://firebase.google.com/docs/cloud-messaging/send/v1-api).

## Implementado en este bloque

`lib/models/quota_reminder.dart` y
`lib/repositories/quota_reminder_repository.dart`:

- Fechas civiles correctas para meses de 28/29/30/31 días y diciembre.
- Consumen el informe de un único mes actual del mismo grupo. Rechazan otro
  grupo o un informe antiguo. Una fecha distinta de las dos previstas no da plan.
- Seleccionan personas activas con pendiente mensual conocido y positivo.
  Una cuota saldada, no aplicable o suspendida no genera candidato.
- El pago procede del reparto neto ya existente, incluyendo devoluciones;
  crédito libre/sobrepagos de otros meses no pagan el mes del recordatorio.
- Separan los identificadores sin configuración, sin inventar una deuda.
- Solo producen candidatos de obligación. No resuelven destinatarios, preferencias,
  hora de entrega, reintentos, persistencia ni deduplicación. No se consumen aún
  desde providers/pantallas o un servidor.

`supabase/functions/_shared/fcm.ts`:

- Adaptador privado de transporte HTTP v1, sin endpoint invocable desde Flutter.
- Solo admite credenciales del proyecto `boteparroquial`; OAuth se solicita al
  endpoint fijo de Google con alcance `firebase.messaging` y JWT firmado RS256.
- Caché de token corta con margen previo a caducidad y renovación compartida.
- La operación valida por defecto; entregar requiere `validateOnly: false`.
- Distingue token `UNREGISTERED` mediante el código concreto de FCM, errores
  temporales y fallos definitivos. No reintenta automáticamente un envío incierto.
- Errores genéricos sin claves, tokens ni respuestas técnicas. Peticiones con
  tiempo límite y sin seguir redirecciones.
- No hay credenciales de servicio creadas/cargadas, caller, worker o despliegue.
  El módulo no se incorpora a `photo-access` y no cambia sus permisos.

La proyección Dart es preparación del cliente y referencia de comportamiento;
**no se ejecuta en Supabase**. Falta implementar allí el cálculo autoritativo y
validar su coherencia con reglas/periodos/asignaciones/devoluciones actuales.

## Consultas remotas realizadas

Consulta de solo lectura con la sesión existente de Firebase CLI:

- `fcm.googleapis.com`: `ENABLED`.
- La sesión dispone de permisos para crear cuentas/claves de servicio, modificar
  IAM y habilitar servicios. Esto acredita la posibilidad de preparar la conexión;
  no significa que se haya creado/asignado nada ni prueba que un futuro despliegue
  vaya a funcionar.
- Diagnóstico local ignorado: `.dart_tool/notifications-preflight.cjs` y su log.
  No imprime credenciales. No hay cambios de Firebase/Supabase, Rules o datos.

## Comprobaciones ejecutadas

- `dart format` en los tres archivos Dart nuevos.
- `flutter test --no-pub test/quota_reminders_test.dart`: **3 pruebas superadas**.
  Calendario bisiesto/meses cortos/diciembre; pendiente frente a crédito/inactividad/
  configuración desconocida; fechas fuera de aviso, otro grupo e informe antiguo.
- `flutter analyze --no-pub`: **sin incidencias**.
- `deno fmt` y `deno test supabase/functions/_shared/fcm_test.ts`: comprobación de
  tipos y **3 pruebas superadas**. JWT firmado con clave efímera local, alcance,
  caché/caducidad/validación por defecto, errores y rechazo de proyecto/endpoint.
  Google/FCM están simulados: no hubo OAuth real ni ninguna entrega de prueba.
  Tras endurecer el análisis de detalles nulos en errores de FCM se repite solo
  el caso afectado, no los tres casos ni otras suites.
- No se repite la suite completa. No se compila APK: no cambian UI, plugins,
  arranque o código nativo y los módulos nuevos aún no se conectan a la app.
- No se instala ni ejecuta la app. Las validaciones físicas previas siguen pendientes.

Logs ignorados: `.dart_tool/quota-reminders-tests.log`,
`.dart_tool/quota-reminders-analyze.log`, `.dart_tool/fcm-transport-tests.log`.

## Siguiente bloque pendiente

1. Aplicar D092 al generador de contenido y al agrupado de destinatarios cuando
   se incorpore el worker: sin importes en push, un resumen por grupo a gestores.
2. Definir preferencias/categorías y destinatarios para los demás sucesos de §53.
   No dar por elegida una matriz general a partir del recordatorio mensual.
3. Cuenta de servicio dedicada y permisos mínimos para servidor. El adaptador de
   FCM solo solicita el alcance de envío; eso **no** autoriza leer/escribir Firestore.
   El futuro procesador de cuotas necesitará autorización de lectura separada.
   Revisar específicamente cualquier permiso de escritura para la bandeja.
   Los SDK/REST con identidad de servidor usan IAM y no Security Rules del cliente:
   validar siempre grupos activos, membresías, vínculos y ámbito en servidor.
4. Configurar secretos exclusivamente en Supabase. No copiar claves a Flutter,
   al repositorio, a argumentos de comandos ni al chat; no reutilizar una cuenta
   con privilegios generales innecesarios. No se requiere por ahora una acción
   manual: la comprobación de permisos permite intentar la preparación por terminal.
   Si una autorización/Console resulta indispensable, detenerse con el paso exacto.
5. Contrato de registro de dispositivos por cuenta/sesión, token refresh y retirada
   al salir/cambiar de cuenta; consentimiento y preferencias. Añadir SDK FCM y
   permisos de Android cuando exista el flujo de registro. APNs/iOS requiere su
   configuración y posterior validación con Mac/dispositivo, hoy no acreditadas.
6. Bandeja privada, destinatarios con acceso vigente y controles de lectura/estado.
   Mantener datos del grupo en `groups/{groupId}/notifications`, sin permitir
   al cliente inventar avisos económicos o enviar a otro UID. Respaldar/publicar
   Rules solo cuando ese contrato y las comprobaciones estén preparados.
7. Worker seguro, deduplicación duradera, recuperación de fallos parciales y cron
   a las 10:00 civiles, contemplando cambios de horario. Releer deuda/roles antes
   de enviar. No aceptar destinatarios/importes calculados por Flutter como autoridad.
8. Validación dirigida del flujo real cuando haya registro, permisos y servidor;
   el usuario ejecuta la app. No reanudar las pruebas aplazadas de otra cuenta.
