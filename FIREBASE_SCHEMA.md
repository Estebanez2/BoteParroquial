Esquema de Firestore

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

Transiciones

Permitidas inicialmente:

active → cancelled

active → corrected

No reactivar movimientos antiguos anulados o corregidos.

Una corrección crea un nuevo movimiento y conserva el anterior.

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
