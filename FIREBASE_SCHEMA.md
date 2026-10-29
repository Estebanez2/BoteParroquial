Esquema de Firestore

Copias diarias del 23/10/2026: no se añaden campos, colecciones, índices ni Rules.
Lectura REST bajo JWT de usuario, membresías filtradas por UID y documentos de
grupos activos accesibles. Una misma readTime cubre las páginas; acceso releído al
terminar. No copiar `users` global, Auth, dispositivos, entregas ni worker privado.
Formato local versionado: uid/day/readTime/savedAt/documents con valores REST
originales, cifrado con clave del dispositivo. No restaurar/importar ese formato
al caché Firestore ni usarlo para autorizar escrituras. Cuotas y saldo continúan
derivándose de las mismas fuentes, congeladas al instante archivado. Detalle:
[DAILY_OFFLINE_COPIES_VALIDATION.md](docs/DAILY_OFFLINE_COPIES_VALIDATION.md).

Contrato de recuperación publicado y verificado, 2026-10-20:

- `persons.historyGuardVersion=1` en altas nuevas; `firstMovementId` se añade con
  el primer movimiento, mediante testigo atómico e inmutable. No es un saldo.
  Personas anteriores sin esta garantía nunca son elegibles para papelera.
- Papelera en el documento de persona: `trashedAt` servidor, `trashedBy` y
  `trashedWasActive`; `isActive=false`. Vencimiento derivado de `trashedAt+10 días`.
  `purgingAt` solo puede iniciarse una vez vencido el plazo según Rules; permite
  limpiar la foto antes de borrar la ficha conservando evento de purga.
- Grupo bloqueado para eliminación: `isActive=false`, `deletionBy`,
  `deletionName`, `deletionStartedAt`; identidad/moneda originales conservadas
  hasta terminar. Subcolecciones se limpian antes de la raíz.
- `users/{uid}/groupDeletionTasks/{groupId}`: `groupName`, `createdAt`,
  `status=deleting/done`. Solo esa cuenta; prueba de propietario/Google reciente
  al crear, finalización conjunta con borrar la raíz. No permite recuperar grupo.
- `users/{uid}/accountLifecycle/current`: `groupIds`, `createdAt`,
  `status=preparing/closing`, `closingAt` al sellar. El estado preparando bloquea
  nuevas entradas/grupos; el flujo retira membresías y vuelve a consultarlas antes
  de sellar. Solo se puede retirar un marcador todavía preparando. El cierre
  impide recrear perfil o dispositivos. Se conserva ante resultado Auth incierto.
- Nuevas acciones de auditoría de grupo: `person.created/updated/activated`,
  `person.trashed/restored/purged`, `movement.created/cancelled/corrected`.
  Antes/después cerrados y contrastados con escrituras del mismo commit.

Publicación y evidencia vigentes de esta continuación:
[registro](docs/FULL_PRODUCT_COMPLETION_2026-10-20.md). Rules finales SHA-256
`35bf3eec1b7b4ff1a23d297e51368bc7a4ac0b4f58be332b9e9845d8cb7e85f1`.

Perfil y fotos: `users/{uid}.lastAuditEventId` enlaza un renombre atómico con
`users/{uid}/auditEvents/{eventId}` privado, acción `profile.renamed`, identidad
propia y before/after de displayName. La actualización de sesión conserva ese
puntero y el nombre guardado; no renombra personas o membresías.
Fotos generan `photo.changeRequested` y `photo.changeCompleted` en auditoría privada de
cuenta o de grupo según destino. ID `photo-request-{operationId}` y
`photo-complete-{operationId}`; campos cerrados de huella anterior, operationId,
modo, tipo/ID de destino y huella nueva. Confirmación exige su intención previa
del mismo actor. Storage y Firestore no comparten transacción: una intención
sin confirmación no acredita foto guardada. Ver reglas para valores exactos;
estos eventos no certifican integridad económica.

Caja agregada: dos índices de `movements` por status/type/amountCents y
status/type/occurredAt/amountCents. No se añaden documentos `monthlySummaries`,
saldos persistidos ni nuevas colecciones globales. Cuatro sumas REST comparten
readTime; el caché privado del móvil queda fuera de Firestore y no es respaldo.

Estado vigente de avisos, 2026-10-20: worker/cron publicados y preferencias
económicas/informativas añadidas. El contrato ampliado al final de este documento
sustituye el pendiente histórico de generación. Reglas verificadas y evidencia:
[informe](docs/PHASE9_NOTIFICATIONS_AND_LINKS_VALIDATION.md).

Actualización de fotos (2026-10-15): se prepara Supabase Storage para archivos,
manteniendo el contrato de imágenes sin campos ni reglas específicos de fotos.
Bucket y función de fotos desplegados. Autorización: Edge Function con consultas
Firestore REST bajo Security Rules del usuario, sin replicar roles ni campos:
docs/SUPABASE_SETUP.md. El aplazamiento de Storage del rediseño es histórico.
Foto de cuenta por defecto cuando falta una foto de miembro; se resuelve en la
función tras autorizar grupo, sin campos nuevos ni copiar documentos/perfiles.

Este archivo es la fuente principal de verdad del modelo persistido.

Cliente de notificaciones (2026-10-19): contratos de dispositivos, preferencias
y bandeja añadidos al final. Publicación/respaldo y límites exactos en
docs/PHASE9_NOTIFICATION_CLIENT_VALIDATION.md. El worker se incorpora después,
según la actualización vigente; aquel informe describe solo el cliente.

Publicación anterior del 2026-10-19: cuotas temporales y periodos, con D077/D078
resueltos. Evidencia/hash: docs/PHASE8_QUOTAS_PERIODS_VALIDATION.md. Los despliegues
de 2026-10-18 y anteriores que siguen son historial.

Actualización 2026-10-18: vínculo recíproco members.personId ↔ persons.linkedUid,
con auditoría y degradación automática de admin. Preparación de dos vínculos
anteriores y Rules publicadas/verificadas. Evidencia exacta:
docs/PHASE7_LINKS_VALIDATION.md. Las publicaciones anteriores son historial.

Entrega posterior del mismo día: roles generales y transferencia atómica,
publicadas y verificadas. Registro histórico y límites:
docs/PHASE7_ROLES_TRANSFER_VALIDATION.md.

Estado del 2026-10-17: Rules de grupos, perfil, invitaciones, solicitudes y bajas
publicadas tras autorización expresa y pruebas dirigidas. Hash remoto coincidente
con el archivo local. Sin migración masiva; 14 documentos DEMO nuevos en un grupo
separado. Versión y evidencia: docs/PHASE7_INVITATIONS_VALIDATION.md.

No duplicar el esquema completo en otros documentos.

Estructura

users/{uid}

groups/{groupId}

groups/{groupId}/members/{uid}

groups/{groupId}/persons/{personId}

groups/{groupId}/movements/{movementId}

También implementadas parcialmente:

groups/{groupId}/invitationSettings/current

groups/{groupId}/invitations/{code}

groups/{groupId}/joinRequests/{uid}

groups/{groupId}/auditEvents/{auditEventId}

groups/{groupId}/quotaSettings/current

groups/{groupId}/quotaRules/{monthOrdinal}

groups/{groupId}/quotaRules/{monthOrdinal}/versions/{auditEventId}

groups/{groupId}/participationPeriods/{participationPeriodId}

groups/{groupId}/allocations/{allocationId}

groups/{groupId}/allocationBalances/{incomeId}

groups/{groupId}/notifications/{notificationId}

Contrato de avisos implementado en cliente y servidor; estado remoto en la
validación vigente de Phase 9.

users/{uid}/pushDevices/{deviceId}

groups/{groupId}/members/{uid}/notificationPreferences/reminders

Contrato de Phase 9

`pushDevices`: deviceId es la huella SHA-256 del token de entrega calculada por
el Service. Campos cerrados: token (string 16..4096), platform (android/ios),
createdAt y updatedAt (timestamp de servidor); createdAt inmutable. Solo su
cuenta autenticada lee/escribe/retira, incluso si ya no pertenece a ningún grupo.
No hay roles globales ni UID ajenos en este registro. Rules comprueba el formato
del ID; la coherencia hash/token y la sustitución son responsabilidad del Service,
y el worker deduplica por token y comprueba el registro vigente antes del envío.
El journal local no guarda el token: solo UID/huellas e intención enabled/retirar.

`notificationPreferences/reminders`: quotaPushEnabled (bool), updatedAt (timestamp
de servidor). Solo se consulta/cambia la propia preferencia con cuenta, grupo y
membresía activos. No cambia rol ni membresía. Ausencia permite recordatorios
tras consentimiento explícito de registrar un móvil; elegir false solo suprime
push de recordatorios de ese grupo, no la creación/lectura de su bandeja.

`notifications`: un documento por destinatario, dentro del grupo; campos iniciales:
recipientUid (string), kind (quotaReminder/unlinkedQuotaSummary), title/body (string),
createdAt (timestamp), readAt (null o timestamp). No duplica groupId de la ruta.
Generación reservada al servidor; clientes, incluidos owner/admin, no
crean/borran avisos ni cambian su contenido. Solo el destinatario con acceso
activo al grupo lee y marca readAt de null a hora de servidor. El marcado usa
transacción online. La consulta filtra recipientUid y limita a 50, ordenando por
createdAt descendente; índice COLLECTION recipientUid ASC + createdAt DESC.
No hay colección global de notificaciones o permisos de lectura cruzada.
El worker añade category (reminders/economic/informative) y sourceKey (string
estable de fuente/destinatario); ID = SHA-256 de sourceKey. Creación condicional,
sin sobrescribir readAt. Además de los dos kinds iniciales admite joinRequested,
memberAccepted, memberJoined, unlinkedMember, linkChanged, adminGranted, adminLost,
incomeAssociated, withdrawalAssociated, quotaChanged, ownershipTransferred,
movementCancelled e invitationRegenerated. No se reciben planes de Flutter.

`groups/{groupId}/members/{uid}/notificationPreferences/economic` y `/informative`:
campos exactos pushEnabled (bool), updatedAt (timestamp de servidor). Get/create/
update solo propios con acceso activo; sin list/delete. Ausencia permite esa
categoría únicamente si hay registro consentido del móvil. No elimina bandeja.

Persistencia privada del worker (sin permisos cliente, ni siquiera para gestores):

- `groups/{groupId}/notificationWorker/state`: cursor (ISO UTC), lastReminder
  (clave mes/etapa o null), owner (UUID de lease o null), leaseUntil y updatedAt
  (timestamps). Lease/CAS y avance tras procesar, no saldo ni estado de cuotas.
- `groups/{groupId}/notificationDeliveries/{hash}`: notificationId, recipientUid,
  tokenHash, state (attempting/sent/unregistered/uncertain), createdAt y updatedAt.
  Hash de aviso/huella. Reserva antes de enviar; una reserva existente impide
  repetir un push incierto. No guarda el token de entrega.
- `groups/{groupId}/notificationDeviceStates/{hash}`: recipientUid, tokenHash,
  state=unregistered, createdAt. Hash de UID/huella, cuarentena por grupo de tokens
  que FCM rechaza como no registrados. Rotación produce otra huella elegible.

Estos metadatos nunca alteran personas, movimientos, asignaciones o membresías.
El adaptador de servidor limita las escrituras a esas rutas y notifications;
la identidad IAM dedicada no tiene permisos de borrado. Reglas cliente siguen
cerradas; IAM privilegiado no se valida mediante Security Rules.

No crear:

persons/{personId}
movements/{movementId}
admins/{uid}

como colecciones globales.

Convenciones

IDs técnicos, nunca correos.

UID corresponde a Firebase Authentication.

Campos en camelCase.

Dinero como enteros.

Timestamps en Firestore.

Roles por grupo.

No duplicar groupId dentro de documentos si ya viene determinado por la ruta salvo que exista una necesidad explícita.

users/{uid}

Perfil global de la cuenta.

Campos:

displayName: string
email: string?
photoUrl: string?
createdAt: timestamp
updatedAt: timestamp
lastSignInAt: timestamp?

Ampliación del 2026-10-17: el nombre de aplicación puede editarlo solo su cuenta.
ensureProfile conserva el nombre ya guardado en lugar de sobrescribirlo con Google.
La edición escribe displayName/updatedAt en transacción con control de versión;
Rules admite conservar lastSignInAt o actualizarlo con hora de servidor, nunca
inventar otra fecha. La recarga de perfil sigue el mecanismo de acceso existente.

No contiene rol global.

groups/{groupId}

Campos:

name: string
description: string?
currency: string
timeZone: string
isActive: bool
createdBy: string
createdAt: timestamp
updatedAt: timestamp

Inicialmente:

currency = EUR

En la aplicación completa la moneda se elige al crear el grupo y posteriormente no puede cambiarse.

No existe saldo editable como fuente de verdad.

Creación/edición desde app (Phase 7 parcial, 2026-10-17):

- Campos adicionales: updatedBy: string y lastAuditEventId: string.
- Obligatorios en grupos nuevos; los grupos anteriores pueden carecer de ellos.
  Una edición autorizada los añade sin migrar ni sobrescribir su historia.
- Creación atómica de grupo, members/{uid} del creador como único owner inicial,
  auditEvents/created y, opcionalmente, persons/owner. La persona del propietario
  se crea por defecto en la app y se puede omitir por decisión del usuario.
- Monedas soportadas: EUR, USD y GBP, con dos decimales. Zonas de creación:
  Europe/Madrid, Atlantic/Canary, Europe/London, America/New_York,
  America/Bogota y America/Mexico_City. No se modifica una zona histórica existente.
- Owner y admin vinculado a persona activa pueden editar solo nombre/descripción
  y metadatos del cambio. Moneda, zona, creador y estado quedan inmutables.
- Auditoría obligatoria mediante getAfter en la misma transacción. No se habilita
  borrado de grupos. Las bajas y entradas posteriores se describen en members.
- Un usuario autenticado puede leer un ID de grupo inexistente para comenzar la
  transacción; esto no autoriza leer grupos existentes ajenos ni listar grupos.

groups/{groupId}/members/{uid}

Campos:

uid: string
displayName: string
role: owner | admin | member
status: active | inactive
joinedAt: timestamp
updatedAt: timestamp
personId: string?

personId representa la vinculación usuario/persona del grupo. La persona opcional
del owner se vincula al crear grupo; gestión autorizada puede cambiar el vínculo
después, conforme a las reglas del bloque de vinculación descrito abajo.

Una cuenta puede tener roles distintos en grupos diferentes.

Ampliación acordada en Phase 2: uid debe coincidir con el ID del documento.
Permite descubrir las membresías propias mediante collectionGroup('members')
filtrada por uid, sin listar grupos ajenos. Índice de ámbito COLLECTION_GROUP
en firestore.indexes.json. No se duplica groupId: se obtiene de la ruta.
displayName es una copia del nombre visible en el momento del aprovisionamiento;
no se sincroniza automáticamente con el perfil global en esta fase. Permite
mostrar miembros sin abrir la lectura de sus perfiles privados users/{uid}.
Las membresías propias inactivas pueden descubrirse, pero no dan acceso al grupo.

Histórico de Phase 2: todos los roles activos pueden leer el grupo activo y sus membresías.
Ningún cliente puede crear, modificar ni borrar grupos o membresías; el primer
grupo se aprovisiona desde terminal con credenciales del operador y escritura
atómica. Solo se crea un owner, sin persona interna todavía (Phase 3).
No se habilita CRUD de personas ni operaciones económicas en esta fase.

Primera entrega de Phase 7: se habilita la creación de la
membresía propia como owner durante la creación atómica de un grupo nuevo.
No se permite concederse gestión en un grupo existente, añadir otro propietario
ni crear personas extra durante ese arranque. No se habilita borrado de membresías.
members/{uid}.personId = 'owner' cuando se eligió crear la persona inicial; null
si se omitió. La vinculación general y unicidad se incorporan el 2026-10-18;
transferencia se incorpora después, según el contrato siguiente.
No inferir un propietario mutable a partir de createdBy.

Segunda entrega de Phase 7:

- lastAuditEventId: string, obligatorio en altas por invitación y bajas. Opcional
  al leer membresías anteriores y el bootstrap del owner.
- Entrada nueva con código activo: member, active, personId=null, joinedAt y
  updatedAt de servidor. Debe existir decisión approved y auditoría en el mismo
  commit. El usuario no puede elegir owner/admin ni vincular una persona al entrar.
- Salida propia o expulsión por owner/admin autorizado: active → inactive y
  role=member, con evento inmutable y updatedAt de servidor. Se conservan UID,
  nombre, joinedAt y personId. Admin deja de conservar privilegios al salir.
- Owner protegido: no puede salir, ser expulsado o degradarse por este flujo.
- Readmisión (D069): inactive → active exclusivamente tras solicitud y aprobación
  de owner/admin autorizado, junto con auditoría. Siempre role=member, personId y
  joinedAt conservados. No se reactiva una membresía owner ni se recupera admin.
  No se cambia la actividad de la persona ni se crean periodos de participación.
- Consulta de la membresía propia por ID permitida incluso si no existe, para
  transacciones de entrada. No concede leer el grupo ni datos privados ajenos.
- Salida/expulsión no cambia persons, movements, imágenes ni cuotas.

Vinculación general (2026-10-18):

- Cambio explícito por owner/admin autorizado, con getAfter de membresía, persona
  anterior/nueva y evento member.linkChanged en el mismo commit. Un UID tiene un
  solo personId; cada persona tiene un único linkedUid. No hay índices globales.
- Cambiar/quitar conserva status, joinedAt, nombre y todos los movimientos de
  ambas personas. No cambia fotos ni notas/nombres. Owner solo cambia su propio
  vínculo; otro admin no puede cambiar el vínculo del owner.
- Personas inactivas permitidas con advertencia. Un admin desvinculado o pasado
  a persona inactiva queda como member en el mismo commit; no hay promociones.
- Membresía inactive puede desvincularse expresamente para liberar la reserva.
  No se le asigna una persona nueva hasta readmitirla. Salir no libera la persona.
- Comparación de updatedAt de membresía y personas para rechazar formularios
  obsoletos; contención en la persona compartida evita dos reclamaciones a la vez.

groups/{groupId}/invitationSettings/current

Campos: code: string (32 caracteres base64url, 192 bits aleatorios); enabled: bool;
requiresApproval: bool; updatedBy: uid; updatedAt: timestamp servidor;
lastAuditEventId: string. Solo get por miembros activos; no list. Solo gestión
autorizada cambia ajustes junto con vista previa y auditoría. No existe hasta
configurar por primera vez; ausencia equivale a invitaciones sin habilitar.

groups/{groupId}/invitations/{code}

Campos exactos: groupName: string; currency: string; requiresApproval: bool;
createdAt: timestamp; updatedAt: timestamp. Sin personas, saldo, miembros,
descripción, fotos ni perfiles. Get para cuenta autenticada que conoce el código
actual habilitado de un grupo activo, o para miembro activo del grupo. No list
ni lectura anónima. El código es una capacidad de entrada: compartirlo revela
estos datos mínimos y permite solicitar acceso o entrar según configuración.

Formato compartido inicial: groupId.code. Sin dominio ni enlaces inventados.
Regenerar cambia settings.code: los documentos previos se conservan, pero sus
códigos dejan de autorizar vistas previas/entradas ajenas. Desactivar no borra
miembros ni solicitudes pendientes. Renombrar un grupo actualiza su vista previa
actual en la transacción del Service. No hay nuevos índices compuestos.

groups/{groupId}/joinRequests/{uid}

Campos exactos: uid; displayName; code; status: pending | approved | rejected;
createdAt; updatedAt; reviewedBy: uid?; reviewedAt: timestamp?; lastAuditEventId.
Una solicitud por cuenta/grupo. Nombre copiado del perfil de aplicación actual;
sin sincronización automática posterior. La cuenta lee solo su solicitud por ID;
gestión autorizada puede consultar solicitudes del grupo (pantalla: pendientes).

Con aprobación: pending, reviewedBy/reviewedAt=null y auditoría join.requested.
Gestión decide approved/rejected con autor/hora de servidor y evento; aprobar
crea el member en el mismo commit. Entrada automática solo para cuenta sin
membresía anterior: approved, reviewedBy=uid y reviewedAt=request.time, junto
con member y auditoría join.accepted. No implica que un gestor la haya revisado.
Los ajustes vigentes se comprueban al enviar, aunque la vista previa sea anterior.
Una solicitud rechazada puede volver a enviarse con un código válido; no es un
baneo. Regenerar/desactivar códigos no cancela solicitudes ya recibidas.
Readmisión: quien tiene membresía inactive solo puede enviar pending, con campos
de revisión null. No da acceso al grupo. Aunque requiresApproval=false, no puede
autoaprobarse. Gestión decide approved/rejected; approved reactiva la misma
membresía en el mismo commit, conservando vínculo/antigüedad. La preview de la
cuenta consulta su membresía para informar de la aprobación obligatoria; no se
añaden campos persistidos ni se abren perfiles ajenos. Una solicitud rechazada
puede repetirse con un código válido. No hay notificaciones push, vencimiento
ni borrado implementados. Evidencia: docs/PHASE7_READMISSION_VALIDATION.md.

groups/{groupId}/persons/{personId}

Campos:

displayName: string
notes: string?
linkedUid: string?
lastAuditEventId: string?
isActive: bool
createdBy: string
updatedBy: string
createdAt: timestamp
updatedAt: timestamp

Las personas con historial financiero no se eliminan.

Se inactivan.

Phase 3 habilita lectura para miembros activos del grupo activo y creación/edición
para owner o admin vinculado a persona activa del mismo grupo. Todos los borrados
están denegados; activar/inactivar conserva el documento y su ID.
displayName: obligatorio, máximo 256 caracteres y no solo espacios.
notes: opcional/null, máximo 2000 caracteres. No hay campos nuevos de cuotas ni enlaces.
createdBy/createdAt son inmutables; updatedBy es el UID autenticado y updatedAt
usa hora de servidor. La creación exige isActive=true y ambos autores iguales al UID.
La edición y cambio de estado desde la app comprueban updatedAt en transacción
para no sobrescribir silenciosamente un cambio concurrente.
linkedUid es la referencia inversa de members/{uid}.personId, dentro del mismo
grupo. Ausente/null significa sin vínculo; nunca un correo ni rol global. Nuevas
personas normales nacen sin vínculo. persons/owner nace con linkedUid=uid cuando
se elige crear la persona inicial. Los campos nuevos son opcionales al leer.
lastAuditEventId referencia el cambio de vínculo o inactivación más reciente;
otros cambios ordinarios lo conservan, sin borrar eventos anteriores.

Al inactivar una persona se registra person.inactivated. Si su cuenta vinculada
es admin, role cambia a member en el mismo commit. Rules rechaza inactivarla sin
esa degradación o sin auditoría. No modifica el vínculo ni degrada un owner.
Reactivar conserva member; volver a ser admin requiere gestión de roles futura.
Esto sustituye la limitación de Phase 3 que solo retiraba el permiso efectivo.

Preparación anterior: tools/backfill_person_links.cjs comprueba todas las
membresías (también inactive), detecta duplicados y personas ausentes/huérfanas y
se detiene sin escribir si hay conflictos. --apply añade únicamente referencias
inversas faltantes, con precondiciones updateTime de persona/membresía y evento
person.linkBackfilled (actor técnico). No cambia createdAt/updatedAt/updatedBy
históricos, nombres, actividad, roles, fotos ni dinero; repite el personId ya
existente como comprobación del snapshot. --verify es solo lectura. No reparar
vínculos por nombre ni al abrir pantallas. Esta operación privilegiada no es una
prueba cliente ni un permiso de Rules para escribir auditoría técnica.

groups/{groupId}/movements/{movementId}

Campos:

type: income | withdrawal

amountCents: int

status:
    active
    cancelled
    corrected

occurredAt: timestamp

description: string

personId: string?

createdBy: string

createdAt: timestamp

updatedAt: timestamp

cancelledAt: timestamp?
cancelledBy: string?
cancellationReason: string?

correctedAt: timestamp?
correctedBy: string?
correctionReason: string?
correctedByMovementId: string?
correctionOfMovementId: string?

amountCents debe ser:

> 0

Phase 4: entero positivo hasta 99999999999999 céntimos. Nunca double.
Ingreso exige personId de una persona existente del mismo grupo; retirada permite
personId=null para el grupo. Se permite persona inactiva con advertencia en la app.
description admite hasta 2000 caracteres: opcional/vacía para ingreso y obligatoria
para retirada. Motivos de anulación/corrección obligatorios, hasta 2000 caracteres.

occurredAt representa un día civil: guardar año/mes/día elegidos como medianoche UTC,
sin convertir a UTC un instante de medianoche local. Mostrar esos componentes sin
toLocal para no desplazar el día entre móviles. La app admite hoy o fechas anteriores
según el calendario de la zona IANA del grupo desde Phase 6 (selector 2000–hoy);
no son operaciones planificadas. El reloj del dispositivo aporta el instante de
referencia; cambiar solo su zona no cambia «hoy» del grupo. Zona IANA inválida bloquea.
Rules añade una cota de servidor request.time+24 h para el margen de zonas horarias
de esa representación y exige occurredAt == occurredAt.date() (medianoche UTC).
La validación exacta de «hoy» por zona IANA en servidor sigue pendiente: Rules no
usa la base IANA del cliente. createdAt/updatedAt y metadatos usan hora de servidor.

Solo owner/admin válido escribe; miembros activos leen. Las reglas impiden editar
importe, tipo, persona, fecha, descripción o creador de un documento existente.
Cambiar cualquiera de esos datos requiere una corrección con un sustituto nuevo.
Se permite cambiar también income/withdrawal al corregir, conservando el original.
No se borran movimientos ni se reactivan estados terminales.

Una corrección actualiza el original y crea el sustituto en una misma transacción.
Las reglas getAfter exigen enlaces recíprocos dentro del grupo, sustituto inexistente
antes y activo después, actor y timestamps de la misma operación. Un sustituto puede
ser corregido otra vez o anulado, conservando toda la cadena.

El ID del nuevo documento funciona como clave de envío. Desde Phase 6, el intento
se conserva antes de escribir en un archivo privado por UID/grupo, fuera de Firestore.
Reabrir la app permite comprobar en servidor su resultado y recuperar el mismo envío
con los mismos datos/ID. No se repite automáticamente. La transacción comprueba el
ID y los datos existentes; un reintento idéntico no crea otro movimiento. No iniciar
un envío nuevo mientras siga pendiente otro en esa cuenta/grupo.
El descarte explícito de un intento local, tras revisar historial, leer servidor
y confirmar, no borra/anula un movimiento ni detiene una solicitud anterior en curso.

Saldo

Saldo conceptual:

sum(income active)
-
sum(withdrawal active)

Los movimientos:

cancelled
corrected

no contribuyen al saldo original.

Un movimiento sustituto con estado active sí contribuye.

Phase 5 presenta esta proyección sin campos ni colecciones nuevos. Los totales de
ingresos/retiradas son históricos y solo incluyen active; el conteo de personas usa
persons, no members. La actividad reciente deriva del último cambio de cada movimiento:
createdAt, cancelledAt o correctedAt, no de occurredAt. No constituye una auditoría
completa de todos los eventos. No duplicar como otro registro de actividad la creación
del sustituto activo de una corrección ya representada por su original.

Transiciones

Permitidas inicialmente:

active → cancelled

active → corrected

No reactivar movimientos antiguos anulados o corregidos.

Una corrección crea un nuevo movimiento y conserva el anterior.

Imágenes — Supabase Storage, sin nuevos campos de Firestore

El aplazamiento inicial del rediseño fue sustituido por la implementación de
fotos, caché y editor. Foto de cuenta como predeterminada de miembro, con excepción
por grupo y foto de persona interna independiente; no se sincronizan personas.
No se añaden campos de imagen a groups/members/persons. photoUrl del perfil
Google no sustituye este contrato. Ver docs/SUPABASE_SETUP.md y D057/D058.

Roles y transferencia (2026-10-18):

- Owner/admin autorizado cambia member → admin solo si membresía activa y persona
  activa vinculada recíprocamente en el mismo grupo. Admin → member permitido,
  incluida la propia degradación; owner excluido y autopromoción prohibida.
- Cambia solo role, updatedAt y lastAuditEventId de la membresía; exige un evento
  member.roleChanged del mismo actor/commit. No se cambia joinedAt, personId o uid.
- Solo owner transfiere: su membresía pasa owner → member y la del receptor
  member/admin → owner. Receptor distinto, activo y con vínculo activo recíproco.
  Ambas conservan todos sus demás campos y comparten updatedAt/lastAuditEventId.
- En el mismo commit groups/{groupId} actualiza únicamente updatedAt, updatedBy
  y lastAuditEventId. Nombre, moneda, zona, createdBy y fechas históricas se conservan.
  createdBy nunca representa al propietario actual; no se añade ownerUid al grupo.
- Rules valida token Firebase con proveedor google.com y auth_time no futuro de
  hasta 300 segundos. El formulario exige el nombre exacto y reautentica la cuenta
  antes de enviar; la regla comprueba el nombre vigente en el evento, sin afirmar
  que pueda probar que un humano lo haya escrito. No se guardan tokens/credenciales.
- Sin borrado, cambios económicos, sincronización de fotos ni migraciones remotas.
  Mantiene un único owner partiendo de un grupo válido; no repara automáticamente
  datos corruptos escritos mediante credenciales privilegiadas.

groups/{groupId}/auditEvents/{eventId} — subconjunto implementado

Campos: action: string; actorUid: string; entityId: string; entityType: string
opcional (group si falta); createdAt: timestamp de servidor; before: map?; after: map.
Sin update ni delete. El ID está referenciado por lastAuditEventId en la entidad
correspondiente. Rules exige el mismo commit/actor/fecha y antes/después exactos:

- group.created / group.updated, entityType=group, entityId=groupId; mapas con
  name y description, before=null en creación. Compatibles con eventos sin tipo.
- invitation.changed, entityType=invitation, entityId=current; mapas con enabled
  y requiresApproval; after añade regenerated: bool. Sin copiar el código secreto.
- join.requested / join.accepted / join.approved / join.rejected,
  entityType=joinRequest, entityId=uid; mapas con uid, displayName y status.
- member.left / member.removed, entityType=member, entityId=uid; mapas con uid,
  role, status y personId. Preservan el rol previo cuando una baja degrada a member.
- member.linkChanged, entityType=member, entityId=uid; mapas uid/personId/role.
  Cambio y desvinculación, incluida la degradación necesaria, en un único evento.
- member.roleChanged, entityType=member, entityId=uid; mapas uid/personId/role.
  Antes/después exactos de la promoción/degradación autorizada.
- group.ownershipTransferred, entityType=group, entityId=groupId; mapas ownerUid
  y groupName. El UID anterior debe ser el actor owner, el nuevo el receptor;
  nombre del grupo vigente en ambos mapas. Evento inmutable ligado al grupo y
  a ambas membresías, que se validan con getAfter.
- person.inactivated, entityType=person, entityId=personId; mapas isActive,
  linkedUid y role (null si no había vínculo). Valida la degradación atómica.
- person.linkBackfilled, entityType=person, entityId=personId; mapas personId y
  linkedUid. Evento técnico de preparación escrito por herramienta privilegiada,
  no por el cliente. No se reconstruye historial anterior a este registro.

before=null cuando la entidad no existía. Payloads planos de string/bool/int/null;
enteros de meses/importes/versiones añadidos en Phase 8. Otros eventos de dinero
amplían explícitamente modelo y validación. Los de devoluciones conservan esos
mapas planos y añaden el contrato técnico de planes descrito en su sección.
Lectura solo para owner/admin autorizado. Desde 2026-10-20 la pantalla consulta
páginas de cincuenta, ordenadas por createdAt e ID descendentes, con cursor
exacto y botón para consultar anteriores; búsqueda/filtros solo sobre cargados.
No hay campos o índices nuevos por esta consulta. No se borran eventos anteriores.
No se reconstruyen eventos de cambios históricos
ni se afirma que exista auditoría general de todas las operaciones. Las
operaciones financieras conservan su historial propio anterior.

Cuotas y periodos — implementados y Rules publicadas el 2026-10-19

D077/D078 resuelven las políticas. Evidencia y versión remota:
docs/PHASE8_QUOTAS_PERIODS_VALIDATION.md. No se han migrado ni sembrado personas.

Mes civil persistido como ordinal int: year * 12 + month - 1; octubre 2026 = 24321.
Rango 24000–25211 (enero 2000–diciembre 2100). Dominio usa YearMonth. No son
instantes ni dinero; createdAt/updatedAt continúan como Timestamp de servidor.

groups/{groupId}/quotaRules/{monthOrdinal}

- effectiveFromMonth: int, igual al ID convertido a string.
- monthlyFeeCents: int >= 0, <= 99999999999999. Cero suspende temporalmente la cuota.
- revision: int >= 1, aumenta exactamente uno al sustituir la regla de ese mes.
- createdBy/createdAt: origen inmutable; updatedBy/updatedAt: último cambio.
- lastAuditEventId: también ID de la versión creada en el mismo commit.

Primera regla con mes inicial explícito; después solo crear/sustituir desde un mes
posterior al actual del grupo. Se aplica hasta la siguiente regla por fecha.
Meses actuales/pasados protegidos; sin delete. La proyección usa la regla vigente
de cada mes, conservando todas las versiones sustituidas. No modifica el saldo.

groups/{groupId}/quotaRules/{monthOrdinal}/versions/{auditEventId}

Campos exactos: effectiveFromMonth, monthlyFeeCents, revision, actorUid, createdAt.
Inmutables, sin update/delete; obligatorios junto a regla y evento quota.changed.
Lectura por miembros activos. UI muestra últimas 20 versiones de ese mes; las
anteriores permanecen guardadas.

groups/{groupId}/quotaSettings/current

Campos exactos: firstMonth: int, createdBy: string, createdAt: timestamp.
Solo creación con la primera regla, sin update/delete. firstMonth identifica la
regla configurada inicialmente; no limita insertar otras reglas futuras antes de
esa fecha. La existencia del documento impide repetir una inicialización retroactiva.

groups/{groupId}/participationPeriods/{periodId}

- personId: string del mismo grupo; firstMonth: int explícito.
- lastMonthInclusive: int?, null abierto o último mes incluido al cerrar.
- createdBy/createdAt, updatedBy/updatedAt y lastAuditEventId.

Personas añade lastParticipationPeriodId: string? opcional para datos anteriores,
apuntando a su última etapa. Iniciar crea periodo y actualiza persona/auditoría.
Cerrar modifica solo último mes/metadatos de la etapa abierta e inactiva persona
en el mismo commit; si tenía un admin vinculado, se degrada a member. Reactivar
abre etapa nueva sin devolver admin. Origen/primer mes no se reescriben; un periodo
cerrado no se reabre ni se borra. Último mes anterior y primero nuevo pueden ser
iguales (D078); ese mes cuenta una vez. Solapamientos interiores se rechazan.

Esta integración usa meses hasta el actual para altas/bajas; no hay altas
programadas futuras. El alta de persona permite primer mes opcional (ver abajo);
si se omite, se elige después desde la ficha, también para el owner inicial del
grupo. No se deduce historia de createdAt/isActive. Configuración ausente
produce un resumen incompleto, no deuda cero ni pagos confirmados.

Eventos nuevos, mapas planos:

- quota.changed: entityType=quotaRule, entityId=monthOrdinal string; before=null o
  resumen anterior, after exacto effectiveFromMonth/monthlyFeeCents/revision.
- participation.started: entityType=person, entityId=personId; before contiene
  periodId anterior/isActive; after periodo nuevo, firstMonth e isActive=true.
- person.inactivated conserva formato anterior sin periodos. Con periodo añade
  periodId/firstMonth/lastMonthInclusive a ambos mapas, junto a isActive/linkedUid/role.

Rules determina el mes civil con request.time y las seis zonas de creación. Helper
de mes, no conversor general de horas IANA: sus offsets se eligen para fronteras
UTC/DST de mes. Zonas nuevas se rechazan hasta ampliar la validación. Revisar
ante cambios de leyes horarias. UI usa timezone para el calendario IANA del grupo.
No cambia el margen previo de occurredAt en movimientos. Contrato y pruebas en el informe.

Asignaciones — continuación de Phase 8 (2026-10-19)

groups/{groupId}/allocations/{movementId}_{monthOrdinal}

- movementId: string de un ingreso del mismo grupo; personId: su persona.
- month: ordinal int 24000–25211. Un único registro por ingreso/mes.
- amountCents: int >= 0, <= 99999999999999. Total absoluto de ese ingreso para
  ese mes, no incremento. 0 libera el reparto sin borrar registro ni historia.
- participationPeriodId: etapa del mismo grupo/persona que incluye el mes.
  Se comprueba al asignar; puede liberarse una asignación que quede fuera al cerrar.
- revision: int desde 1, aumenta exactamente 1, máximo 1000000000.
- createdBy/createdAt: origen inmutable; updatedBy/updatedAt: actor/servidor.
- lastAuditEventId: evento inmutable creado en el mismo commit.

El ID y movementId/personId/month no cambian; no hay delete. Solo owner/admin
autorizado escribe; miembros activos leen. El ingreso debe seguir active antes
y después del commit, con persona coincidente. Precio temporal no se copia a la
asignación: su importe esperado deriva de quotaRules. Puede existir sobrepago
manual advertido o un pago cuyo cumplimiento sigue incompleto por falta de cuota.

groups/{groupId}/allocationBalances/{movementId}

Campos base: allocatedCents, revision, lastAllocationId, lastAuditEventId,
updatedBy y updatedAt. Revisión entera desde 1. Sin delete. Contador técnico
de capacidad por ingreso, nunca saldo del bote. Los campos de devoluciones se
describen abajo; datos anteriores pueden omitirlos. Al ajustar un reparto
debe cambiar en el mismo commit que la única asignación indicada. Rules exige
total anterior - asignación anterior + nueva y revisión +1; no admite modificar
el contador solo ni dos asignaciones con el mismo contador en un commit.
La transacción resuelve concurrencia entre administradores incluso en meses distintos.

Evento allocation.changed: entityType=allocation, entityId=ID de asignación;
before=null o resumen anterior y after resumen nuevo exacto: movementId, personId,
month, amountCents, revision. Mismo actor/hora/commit, sin update/delete. Versiones
anteriores permanecen en auditEvents; la pantalla administrativa permite consultar
páginas anteriores, sin borrarlas ni reescribirlas.

Solo suman pagos las asignaciones cuyo ingreso fuente sigue active. Anular o
corregir congela el reparto original y deja de contarlo; no requiere borrar ni
reescribir sus registros. El sustituto empieza sin reparto. Sobrante de ingresos
activos es crédito sin asignar, distinto del asignado a meses futuros. Pagos de
varios ingresos pueden acumularse en el mismo mes; sobrepago no salda otro solo.
Configuración incompleta mantiene deuda/diferencia desconocidas. Una retirada
ordinaria no revierte asignaciones. Las devoluciones explícitas del bloque
siguiente sí descuentan los pagos seleccionados, sin reescribir el reparto bruto.

Sin migración. Nuevas asignaciones solo mediante confirmación explícita.
No hay nuevo índice compuesto ni saldo editable.

Devoluciones y alta con periodo — continuación 2026-10-19

El movimiento de devolución sigue en groups/{groupId}/movements/{movementId}.
Es type=withdrawal, amountCents positivo, personId igual al del ingreso fuente.
Añade refund opcional (ausente/null para movimientos normales):

```text
refund: {
  incomeId: string,
  unallocatedCents: int >= 0,
  parts: { "24316": 500, "24317": 1000 }
}
```

parts es mapa de hasta cuatro meses ordinales canónicos a céntimos positivos.
amountCents = unallocatedCents + suma(parts). Un solo ingreso active del mismo
grupo/persona; fecha efectiva no anterior a la del ingreso. No inferir cuotas
devueltas por importe o descripción de una retirada normal.

lastRefundOperationId referencia el evento inmutable de crear/corregir/anular.
Se añade también al original y al sustituto normal cuando se restaura una
devolución al convertirla en movimiento ordinario. Las transiciones conservan
refund e importe históricos; sin delete ni edición directa de importes.

allocationBalances/{incomeId} amplía sus seis campos base con:

- refundedCents: int >= 0, suma del importe de devoluciones active del ingreso.
- refundedAssignedCents: int >= 0, parte de lo anterior correspondiente a cuotas.
- refundedMonths: map de mes ordinal string a céntimos devueltos activos.
- lastRefundOperationId: string del último evento de devolución.

allocatedCents sigue siendo la suma bruta de allocations, sin restar devoluciones.
Crédito libre = ingreso - allocatedCents - refundedCents + refundedAssignedCents.
Pago neto de ingreso/mes = allocation.amountCents - refundedMonths[mes].
El SDK quita claves cuyo retorno llega a cero. Los datos antiguos equivalen a
ceros/mapa vacío. lastAllocationId puede ser null si la primera operación de
contador es devolver crédito de un ingreso aún sin reparto.

Crear/corregir/anular modifica contador y revisión en el mismo commit que
movimientos/evento. Una asignación manual conserva los cuatro campos de devolución
y no puede reducir el reparto de un mes por debajo de lo devuelto. No reutilizar
como crédito libre el dinero de cuotas devuelto. Bloquear la anulación/corrección
del ingreso mientras refundedCents > 0, con validación de cliente y Rules.

auditEvents/{operationId}: entityType=refund, entityId=operationId; action es
refund.create/refund.cancel/refund.correct. Conserva campos comunes y mapas
planos before/after con incomeId, movementId (null cuando no procede) y amountCents
(importe de devolución anterior/nuevo, 0 si no hay plan). Añade el contrato técnico:
kind (create/cancel/correct), incomeId, originalMovementId?, targetMovementId?,
previousAmountCents, amountCents, previousAssignedCents, assignedCents,
previousRefund?, refund? (copias exactas de los planes históricos) y changes
(lista de todas las claves de mes afectadas, únicas, sin null, máximo cuatro).
No hay colección refundOperations: es el mismo evento, no una segunda copia.

Rules exige nuevo evento y sus testigos en el mismo commit/actor/hora. Distribuye
las comprobaciones de meses entre contador (0/1), evento (2) y movimiento destino
o anulado (3); todos obligatorios. Cada comprobación valida ingreso/persona/mes
de la asignación consultada, delta, entero y límites. La auditoría administrativa
sigue leyendo los mapas planos; el plan técnico adicional no cambia ese contrato.
Anular restaura conjuntamente cuotas/crédito; corregir restaura el original y
aplica el sustituto revisado. Mismo origen; unión de meses original/sustituto <= 4.
Para otro origen o más meses, anular y registrar nueva devolución. No barrer ni
reescribir allocations. No se inicializan campos en documentos antiguos en masa.

Alta con primer mes: opción explícita, desactivada por defecto. En un commit crea
persona, participationPeriods/initial-{personId} abierto y
auditEvents/person-created-{personId}. Persona apunta al periodo/evento;
firstMonth <= mes actual del grupo. Evento person.createdWithParticipation,
entityType=person, entityId=personId, before=null, after con displayName, notes,
periodId, firstMonth e isActive=true. ID estable para reintento; el evento inmutable
permite reconocer el mismo alta ya confirmada. Sin mes, no se crea periodo ni se
inventa deuda. No cambia el alta de persona inicial en creación de grupos.
Evidencia y publicación: docs/PHASE8_REFUNDS_VALIDATION.md.

Informes de cuotas — lectura, 2026-10-19

No se añaden colecciones/campos ni se cambian Rules. Se consultan las personas,
movimientos, quotaRules, participationPeriods y allocations del groupId explícito.
Periodos/asignaciones tienen dos streams de contenido compartidos por dashboard
e informes, sin una consulta por persona. Se reutilizan los adaptadores de parseo
individual; las reglas actuales ya permiten lectura por miembros activos.
No se consulta auditoría de acceso administrativo ni se confía en el contador
allocationBalances como agregado de pagos. Todo se proyecta a partir de documentos
válidos de dominio. No se escriben snapshots, porcentajes, deuda ni agregados.
Datos ausentes mantienen pendiente desconocido. Nuevas lecturas no constituyen
migración ni confirmación de un cierre histórico. Ver informe de validación.

Seguridad

Firestore Rules deberá validar, cuando las features se implementen:

usuario autenticado;

membresía activa;

rol;

tipos;

campos;

relaciones dentro del grupo;

transiciones válidas;

inmutabilidad de campos históricos.

Google Authentication por sí sola no concede acceso a ningún grupo.
