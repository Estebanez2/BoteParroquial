# Phase 9 — Cálculo de recordatorios en servidor

2026-10-20. Continuación después de terminar la
[guía para dos o tres móviles](GUIA_PRUEBAS_MOVILES.md).

## Entregado

`supabase/functions/_shared/quota_reminders.ts` implementa el dominio del futuro
worker en TypeScript/Deno. No usa Flutter ni acepta una orden de envío del cliente.

- Ventana desde las 10:00 hasta terminar el mismo día civil del grupo, en las seis
  zonas IANA soportadas. Días 7 y 1 antes del último día del mes, contemplando
  febrero bisiesto y horario de verano. No recupera al día siguiente.
- Cálculo del pendiente **del mes actual**, con la regla temporal y las etapas
  explícitas. Una frontera de baja/reactivación compartida cuenta una vez.
- Solo allocations de ingresos activos pagan; devoluciones activas descuentan
  sus partes. Correcciones/anulaciones conservan historia sin computar el original.
  Ni crédito libre, ni sobrepagos de otro mes, ni retiradas normales pagan el mes.
- Importes individuales enteros limitados por el contrato; sumas con `BigInt`.
  Configuración desconocida se separa, no se interpreta como deuda cero.
- No genera candidatos para personas inactivas o cuotas saldadas/suspendidas.
- Resuelve destinatarios con membresía vigente y vínculo recíproco. Un antiguo
  miembro nunca recibe el aviso aunque su persona conserve el vínculo. D096 lo
  incluye en el resumen para gestores, junto a las personas sin cuenta disponible.
- Un resumen por grupo/destinatario, no uno por persona. Owner activo y admins
  activos con persona activa vinculada; no basta con un campo role=admin aislado.
  Si el gestor también debe su cuota, su aviso propio y el resumen son categorías
  distintas, no varios resúmenes de personas.
- Borradores discretos sin nombres, cantidades o detalles financieros en el texto.
  La preferencia false conserva borrador de bandeja y suprime su intención push.
- Identidad lógica estable por grupo/mes/etapa/categoría/UID, independiente de la
  hora de reejecución. **Todavía no persiste una reserva ni garantiza deduplicación
  de escrituras/envíos**: eso corresponde al siguiente bloque.
- Rechaza ámbitos mezclados, vínculos rotos, etapas solapadas, repartos superiores
  al ingreso y devoluciones incoherentes; no calcula sobre un historial parcial.

`supabase/functions/_shared/reminder_reader.ts` prepara la lectura REST:

- Proyecto y base fijados a boteparroquial/(default); grupo explícito por llamada.
- Transacción **readOnly** compartida por grupo, personas, miembros, cuotas,
  periodos, movimientos, asignaciones y preferencias. Página tras página dentro
  de esa misma instantánea, sin mezclar importes leídos en momentos distintos.
- Máscaras de campos, páginas de 200 y límite de 10.000 documentos existentes por
  grupo. Si no cabe el historial completo, falla el grupo: no envía con un subtotal.
  Plazo global de peticiones de 45 s, 15 s por petición, sin seguir redirecciones.
- No carga tokens de dispositivos ni modifica documentos. `rollback` libera la
  transacción de lectura al terminar, sin deshacer ni escribir datos financieros.
- Recibe una fábrica de OAuth de servidor, **todavía no configurada ni invocada
  contra Google**. Errores genéricos sin credenciales o respuestas sensibles.
- No se importa desde photo-access; esa función conserva su JWT de usuario y no
  recibe permisos privilegiados.

## Validación ejecutada

- Seis pruebas Deno dirigidas con comprobación de tipos: cuatro de cálculo,
  calendario, destinatarios y rechazos; dos de lectura coherente/paginación,
  preferencias, errores, aislamiento, precisión y límites. HTTP simulado.
  Repetidos solo los dos casos del lector tras endurecer los errores de OAuth;
  lint Deno de los cuatro archivos nuevos sin incidencias tras corregir el mock.
- Una prueba Flutter usa **los mismos 13 escenarios JSON** que Deno y los ejecuta
  contra QuotaReportRepository y QuotaReminderRepository reales. Comprueba crédito,
  sobrepago de otro mes, pago completo/parcial, devolución/anulación, ingreso
  corregido, retirada ordinaria, ausencia de regla/etapas, cuota cero, etapa cerrada
  y reactivación en el mismo mes. No llama a Firebase.
- Formateados los archivos afectados. `flutter analyze --no-pub`: **sin incidencias**
  (73,7 s). No se recompila APK porque no cambia el código de producción de
  Flutter, dependencias o configuración nativa.
- No suites completas, instalación, arranque ni pruebas físicas. Ningún documento
  DEMO creado, ninguna notificación enviada, ningún cambio remoto de Rules,
  índices, IAM, secretos, funciones desplegadas o cron.

Fixtures: `test/fixtures/quota_reminder_parity.json`. Flutter:
`test/quota_reminder_parity_test.dart`. Deno: `quota_reminders_test.ts` y
`reminder_reader_test.ts` junto a los módulos. Logs Flutter ignorados:
`.dart_tool/reminder-parity-test.log` y `.dart_tool/reminder-parity-analyze.log`.

## Qué falta para activar avisos

1. Identidad de servicio separada con permisos IAM revisados y secretos solo en
   Supabase. El adaptador de FCM existente tiene alcance de envío; no se debe
   confundir con autorización de lectura/escritura de Firestore.
2. Descubrir/acotar grupos y ejecutar el lector desde un worker autenticado,
   sin endpoint que acepte listas de destinatarios o cantidades de Flutter.
3. Persistir bandeja y reservas duraderas, con IDs estables y creación condicional;
   resolver concurrencia, fallos parciales y política de envío FCM incierto.
   La clave lógica preparada aquí es una pieza, no una entrega exactamente una vez.
4. Antes de crear/entregar, releer datos y permisos vigentes y las preferencias;
   verificar dispositivos aún registrados y deduplicar tokens. Una instantánea
   inicial no autoriza un envío minutos después ni evita por sí sola una baja.
5. Conectar transporte FCM, tratamiento de UNREGISTERED y cron/Vault de Supabase.
   Recuperar desde las 10:00 durante ese día sin duplicados (D096). Revisar costes
   y cuotas antes de activar; no activar Blaze o planes de pago.
6. Entrega real controlada y ampliación del apartado 12 de la guía. APNs/iOS y
   las demás categorías de notificaciones de §53 siguen pendientes.

No hace falta una acción manual del usuario para este bloque local. No afirmar
que ya hay recordatorios automáticos por disponer de estos módulos comprobados.

Fuentes oficiales revisadas el 2026-10-20:
[listDocuments y consistencia/paginación](https://firebase.google.com/docs/firestore/reference/rest/v1/projects.databases.documents/list),
[beginTransaction](https://firebase.google.com/docs/firestore/reference/rest/v1/projects.databases.documents/beginTransaction),
[REST y autorización IAM frente a Rules](https://firebase.google.com/docs/firestore/use-rest-api),
[programación con Cron/pg_net/Vault](https://supabase.com/docs/guides/functions/schedule-functions).
