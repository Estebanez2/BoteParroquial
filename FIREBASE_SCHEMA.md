Esquema de Firestore

Actualización de fotos (2026-10-15): se prepara Supabase Storage para archivos,
manteniendo este contrato de Firestore sin cambios. No hay campos ni reglas nuevos.
Bucket y función de fotos desplegados. Autorización: Edge Function con consultas
Firestore REST bajo Security Rules del usuario, sin replicar roles ni campos:
docs/SUPABASE_SETUP.md. El aplazamiento de Storage del rediseño es histórico.
Foto de cuenta por defecto cuando falta una foto de miembro; se resuelve en la
función tras autorizar grupo, sin campos nuevos ni copiar documentos/perfiles.

Este archivo es la fuente principal de verdad del modelo persistido.

No duplicar el esquema completo en otros documentos.

Estructura

users/{uid}

groups/{groupId}

groups/{groupId}/members/{uid}

groups/{groupId}/persons/{personId}

groups/{groupId}/movements/{movementId}

Futuro:

groups/{groupId}/quotaRules/{quotaRuleId}

groups/{groupId}/auditEvents/{auditEventId}

groups/{groupId}/participationPeriods/{participationPeriodId}

groups/{groupId}/allocations/{allocationId}

groups/{groupId}/notifications/{notificationId}

groups/{groupId}/joinRequests/{requestId}

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

groups/{groupId}/members/{uid}

Campos:

uid: string
displayName: string
role: owner | admin | member
status: active | inactive
joinedAt: timestamp
updatedAt: timestamp
personId: string?

personId representa la futura vinculación entre usuario autenticado y persona interna.

Una cuenta puede tener roles distintos en grupos diferentes.

Ampliación acordada en Phase 2: uid debe coincidir con el ID del documento.
Permite descubrir las membresías propias mediante collectionGroup('members')
filtrada por uid, sin listar grupos ajenos. Índice de ámbito COLLECTION_GROUP
en firestore.indexes.json. No se duplica groupId: se obtiene de la ruta.
displayName es una copia del nombre visible en el momento del aprovisionamiento;
no se sincroniza automáticamente con el perfil global en esta fase. Permite
mostrar miembros sin abrir la lectura de sus perfiles privados users/{uid}.
Las membresías propias inactivas pueden descubrirse, pero no dan acceso al grupo.

En Phase 2 todos los roles activos pueden leer el grupo activo y sus membresías.
Ningún cliente puede crear, modificar ni borrar grupos o membresías; el primer
grupo se aprovisiona desde terminal con credenciales del operador y escritura
atómica. Solo se crea un owner, sin persona interna todavía (Phase 3).
No se habilita CRUD de personas ni operaciones económicas en esta fase.

groups/{groupId}/persons/{personId}

Campos:

displayName: string
notes: string?
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
Las membresías siguen sin poder escribirse desde el cliente. Si se inactiva una
persona vinculada a un admin, este pierde el permiso efectivo de gestionar
personas; la degradación persistida del rol y las vinculaciones pertenecen a Phase 7.

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

Imágenes — acuerdo de producto, todavía sin persistencia implementada

El usuario pospone subidas y Storage en el rediseño del 2026-10-15. No se añaden
campos de foto a groups/members/persons ni se abren reglas por esa preparación.
El photoUrl existente en users sigue siendo el dato del perfil de autenticación;
no implica que exista un editor de fotos. La UI actual utiliza iniciales.

Para la fase de fotos: cuenta global editable solo por su dueño, foto independiente
por grupo editable por su miembro; admin puede editar miembros normales, owner
también admins. Solo owner cambia la imagen del grupo. El vínculo entre foto de
persona interna y foto de miembro aún debe concretarse. Ver D053; no asumir campos,
rutas de Storage ni sincronizaciones antes de implementar y probar esas reglas.

Futuro: cuotas

quotaRules almacenará reglas de cuota con periodo de aplicación.

No sobrescribir cuotas históricas al modificar la cuota actual.

Futuro: periodos

participationPeriods permitirá representar:

alta
baja
reincorporación

de una persona.

Una persona puede tener varios periodos.

Futuro: allocations

Permitirá asignar ingresos a meses concretos.

Ejemplo:

Ingreso: 50 €

20 € → mayo
20 € → junio
10 € → julio

Esto permitirá:

pagos atrasados;

pagos adelantados;

varias aportaciones;

crédito.

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
