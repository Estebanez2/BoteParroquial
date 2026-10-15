Registro de decisiones

Este documento contiene decisiones ya tomadas.

No contiene propuestas.

D001 — Dinero en unidades enteras

Todo el dinero se almacena como int.

Ejemplo:

20,50 € = 2050

Motivo:

evitar errores de coma flotante.

D002 — Datos económicos separados por grupo

Personas y movimientos pertenecen siempre a un grupo.

No existen colecciones económicas globales.

D003 — Arquitectura multigrupo desde el comienzo

Aunque inicialmente se utilice un solo bote, la persistencia admite varios grupos.

D004 — Movimientos económicos inmutables históricamente

No se eliminan ni se sobrescriben para corregir errores.

Estados:

active
cancelled
corrected

D005 — UI sin acceso directo a Firebase

Dirección:

UI → Provider → Repository → Service → Firebase

D006 — Android primero, iOS compatible

Android es la plataforma inicial de pruebas.

El código debe evitar dependencias innecesariamente exclusivas de Android.

D007 — Personas con historial no se eliminan

Se marcan como inactivas.

D008 — Roles por grupo

Roles:

owner
admin
member

se almacenan en members.

No existen administradores globales.

D009 — Riverpod y go_router

Riverpod:

estado e inyección.

go_router:

navegación.

D010 — Saldo derivado de movimientos

La fuente de verdad son los movimientos económicos.

Un saldo almacenado en el futuro será únicamente un agregado optimizado y deberá mantenerse consistentemente.

D011 — Importes positivos

amountCents siempre es positivo.

type determina si suma o resta.

D012 — Metadatos con hora de servidor

createdAt y updatedAt utilizan tiempo del servidor cuando corresponda.

occurredAt representa la fecha económica efectiva.

D013 — Miembros normales de la aplicación completa

Los miembros normales pueden consultar la información del grupo.

No pueden:

crear;

editar;

borrar;

registrar movimientos;

gestionar personas;

gestionar roles.

D014 — Registro de movimientos

Solo:

owner
admin

pueden registrar ingresos o retiradas.

D015 — Retiradas

Una retirada puede estar:

asociada a una persona

o

asociada al grupo en general

D016 — Saldo negativo

Se permite.

Debe mostrarse una advertencia fuerte antes de confirmar la operación.

D017 — Cuota mensual

La aplicación completa tendrá una cuota común para todas las personas activas del grupo.

La cuota puede cambiar, pero sus cambios se versionan por periodo.

Cambiarla no modifica meses históricos.

D018 — Pagos

Una persona puede:

realizar varias aportaciones al mes;

aportar más que la cuota;

pagar meses atrasados;

pagar meses futuros.

Las futuras allocations determinarán a qué meses corresponde cada aportación.

D019 — Participación

Las personas tendrán periodos de participación.

Al añadirlas se podrá elegir desde qué mes comienzan a computar.

Una persona puede inactivarse y reincorporarse posteriormente.

D020 — Propietario

Solo existe un propietario por grupo.

No puede ser:

expulsado;

degradado por un administrador.

Antes de salir debe transferir la propiedad.

D021 — Administradores

Un administrador puede:

gestionar personas;

registrar dinero;

administrar miembros;

ascender miembros vinculados;

degradar otros administradores salvo al propietario.

Para ser administrador debe estar vinculado a una persona interna activa.

D022 — Vinculación

Solo los administradores pueden vincular usuarios y personas.

Reglas:

1 usuario → máximo 1 persona por grupo

1 persona → máximo 1 usuario

Puede cambiarse posteriormente.

D023 — Información visible

En la aplicación completa todos los miembros pueden consultar toda la información económica del grupo.

Solo owner/admin pueden modificarla.

D024 — Invitaciones

Los miembros pueden compartir el enlace de invitación.

Los administradores gestionan:

regeneración;

aprobación;

activación/desactivación de nuevas entradas.

D025 — Moneda

La moneda se elige al crear un grupo.

Después no puede modificarse.

D026 — Sin superadministrador global

No existirá un usuario con acceso oculto a todos los grupos.

D027 — Historial administrativo separado

El historial económico y el historial administrativo son pantallas y conceptos diferentes.

D028 — Papelera

Los elementos que puedan eliminarse temporalmente permanecerán 10 días en papelera.

No aplica a movimientos financieros.

D029 — Eliminación de grupo

Solo el propietario puede eliminarlo.

La eliminación es definitiva.

Debe existir una confirmación fuerte antes de hacerlo.

D030 — Encapsular el sistema visual

Tokens y componentes visuales en lib/design_system/, con API pública propia App*.
Las features no exponen componentes de bibliotecas visuales externas directamente.
Los tokens viven en design_system/theme y no se duplican en core/theme.

D031 — Galería de desarrollo separada

La propuesta se revisa mediante lib/main_showcase.dart, solo debug y sin Firebase.
La aprobación de identidad visual y la migración de pantallas son pasos separados.
No se ha rediseñado el login existente ni alterado su lógica.

Decisiones todavía pendientes

Diseño visual definitivo: v0.1 implementada y documentada en DESIGN_SYSTEM.md,
pendiente de aprobación del usuario. No dar por aprobada la propuesta por compilar.

Política concreta de generación de exportaciones grandes.

Momento exacto en que introducir Cloud Functions.

Estrategia definitiva para agregados de estadísticas.

Política final de caché y funcionamiento offline para operaciones económicas.

Reglas exactas para una futura baja completa de cuenta de usuario.

Añadir nuevas decisiones con ID y motivo.

No eliminar decisiones anteriores sin dejar constancia del cambio.
