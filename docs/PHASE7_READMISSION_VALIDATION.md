# Phase 7 — Readmisión con aprobación, 2026-10-17

El usuario responde «Permitir solicitud con aprobación obligatoria». Se resuelve
la pregunta pendiente de la entrega inicial de invitaciones. Decisión D069.

Publicación posterior de vínculos el 2026-10-18:
[PHASE7_LINKS_VALIDATION.md](PHASE7_LINKS_VALIDATION.md). La versión de Rules de
este informe queda como evidencia histórica; no es la publicación más reciente.

## Comportamiento

- Una cuenta que salió o fue expulsada solicita volver con un código válido y
  habilitado de un grupo activo. Su membresía permanece inactive mientras espera.
- La solicitud requiere aprobación de owner/admin autorizado incluso cuando las
  cuentas nuevas entran automáticamente. No puede autoaprobarse ni reactivar su
  membresía de forma independiente.
- Al aprobar se reactiva la misma membresía como member, conservando personId y
  joinedAt. No recupera admin, no se crea otra persona y no cambian su actividad,
  movimientos ni fotos. Un antiguo owner no se reactiva por este flujo.
- La preview consulta solo la membresía propia en servidor, con UID explícito;
  muestra «Tu vuelta necesita aprobación» y «Solicitar entrada». El envío vuelve
  a comprobar configuración/membresía vigentes en transacción.
- Aprobar/rechazar conserva el control de versión y la auditoría atómica existente.
  Rechazar no concede acceso. Puede solicitarse otra vez con código válido; no
  implica un baneo permanente. No se crean periodos de participación ni cuotas.

Se mantiene UI → Provider → Repository → Service → Firebase. isReadmission es
solo información del modelo de preview, sin campo persistido nuevo. Los permisos
se validan también en Rules, sin confiar en el texto/botón del cliente.

## Validación realizada

- Formato aplicado a los ocho archivos Dart afectados; flutter analyze --no-pub
  sin incidencias.
- Un caso Flutter visual existente ampliado y ejecutado: configurar, aprobar,
  retirar y presentar/enviar readmisión. A 360 px, texto al 160 % y movimiento
  reducido, sin excepciones. Servicios simulados; no acredita uso físico.
- Cinco casos del archivo invitations_rules.test.cjs en emulador: los cuatro de
  invitaciones afectados y un caso nuevo de readmisión. Todos superados.
- Caso nuevo: solicitud pendiente con entrada automática, lectura del grupo aún
  denegada, autoaprobación rechazada, aprobación sin membresía rechazada, admin
  rechazado como rol de retorno, vínculo/antigüedad adulterados rechazados,
  aprobación por gestor activo, salida propia y rechazo posterior. También
  expulsión/readmisión de admin, que vuelve solo como member; persona/movimiento
  históricos permanecen intactos.
- No se repiten las suites completas ni se reanudan segunda cuenta real, dos
  móviles, pruebas offline o iOS aplazadas. El usuario ejecutará la app.
- flutter build apk --debug --no-pub -t lib/main.dart: correcto, APK actualizado
  en build/app/outputs/flutter-apk/app-debug.apk. Sin instalación ni arranque.

Logs locales: .dart_tool/readmission-rules-validation.log. La aprobación real en
Android sigue pendiente; no se infiere a partir del emulador o del APK.

## Reglas publicadas y verificadas

Proyecto boteparroquial, base (default). Se mantiene la autorización expresa de
publicación del usuario; esta ampliación implementa la opción que ha escogido.
Deploy compilado y completado. Lectura posterior de release/fuente con
tools/verify_firestore_rules.cjs confirma matchesLocal=true.

- Ruleset: projects/boteparroquial/rulesets/546c76d7-8784-4565-8326-365182315b98.
- Actualización: 2026-10-17T10:37:08.559634Z (12:37 Europe/Madrid).
- SHA-256 remoto/local: c1f2201e1cbf93e505a4cc64c00b7bcecd18fd1487464e7b1892017edca711be.
- Logs: .dart_tool/readmission-rules-deploy.log y readmission-rules-verified.log.

La versión c4d4cdd5 de PHASE7_INVITATIONS_VALIDATION.md queda como historial.
La copia anterior externa de Phase 6 se conserva; no se restaura nada. Ver
[FIRESTORE_RULES_BACKUP.md](FIRESTORE_RULES_BACKUP.md).

No se escriben documentos reales ni se modifican los ejemplos existentes en
este ajuste. No cambia Supabase, índices ni configuración de Authentication.
La muestra DEMO anterior sigue siendo ficticia, sin cuentas Auth adicionales.

## Pendientes

Validación física por el usuario y las pruebas aplazadas del MVP; gestión general
de roles, enlaces reales y transferencia según
roadmap. Esta entrega no declara completados Phase 7 ni el producto completo.
La vinculación única se incorpora en la entrega posterior enlazada arriba.
