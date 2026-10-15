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

Decisiones de Phase 2

D032 — Descubrimiento de grupos y miembros (2026-10-15)

El usuario elige uid y displayName en members. Consultar únicamente las
membresías propias por uid con collectionGroup; obtener groupId de la ruta.
El nombre de membresía es una copia al aprovisionar, no un perfil público global.

D033 — Alcance controlado de Phase 2 (2026-10-15)

El usuario elige seguir el roadmap: aprovisionar Prueba1 desde terminal con su
cuenta de la app como owner. Creación desde UI, invitaciones, cambios de roles y
transferencia siguen en Phase 7. No asignar una segunda cuenta inventada.
Las reglas deniegan todas las escrituras cliente de grupos y membresías.
El operador crea grupo y owner atómicamente con fecha de servidor; no se crea
persona interna hasta la fase correspondiente. Moneda EUR y zona Europe/Madrid.

D034 — Uso del sistema visual en Phase 2 (2026-10-15)

El usuario pide avanzar usando los componentes y solicita UI distintiva con
animaciones cuando encajen. Conectar AppTheme claro/oscuro a la app y utilizar
App* en home y grupos, con titulares editoriales y AppReveal que respeta el
movimiento reducido. La apariencia puede iterarse; no se reanudan pruebas
manuales aplazadas de auth. Login conserva su composición previa con el tema común.

D035 — Consultar alternativas (2026-10-15)

Petición explícita: no dar decisiones por entendidas; cuando haya varias formas
de hacer algo, explicar alternativas, recomendar una y preguntar antes de elegir.
No volver a consultar decisiones ya acordadas ni interpretar silencio como respuesta.

Decisiones de Phase 3

D036 — Formularios de Personas en panel inferior (2026-10-15)

El usuario elige panel inferior para alta y edición: nombre y notas opcionales.
Activar/inactivar usa confirmación y conserva el documento; no hay borrado.
No se adelantan cuotas, vinculaciones ni gestión de roles.

D037 — Validación proporcional (2026-10-15)

El usuario solicita solo las pruebas necesarias para reducir tiempo y consumo.
Ejecutar comprobaciones dirigidas al cambio y riesgos reales; no repetir suites
completas ni generar capturas o matrices de casos sin necesidad. Mantener análisis
estático y compilación pertinentes, y documentar los límites de la evidencia.

Decisiones de Phase 4

D038 — Formularios y personas inactivas

El usuario elige pantallas completas para movimientos. Se permite registrar para
personas inactivas, con advertencia, sin reactivarlas. Un ingreso exige persona;
una retirada puede pertenecer al grupo. El owner/admin conserva los mismos requisitos
de acceso que en Personas. No se añaden cuotas ni asignaciones mensuales.

D039 — Corrección y fechas

El usuario permite cambiar también ingreso/retirada al corregir. El original se
conserva y el sustituto se crea atómicamente. Solo se admiten fechas efectivas de hoy
o anteriores en la app. Día civil representado como medianoche UTC; metadatos de
registro separados, con hora del servidor. Ver los límites de zona horaria en el esquema.

D040 — Integridad y advertencias

El ID del envío permanece durante los reintentos del formulario. Las transacciones
verifican documento/versión y las reglas exigen correcciones recíprocas atómicas.
Solo active contribuye al saldo. Antes de confirmar se consulta el servidor y se
advierte si la operación deja saldo negativo. No se persiste un saldo editable.
El aviso refleja esa consulta, no una reserva de saldo frente a operaciones concurrentes.

D041 — Datos de prueba autorizados

El usuario confirma que Personas funciona y autoriza crear casos ficticios en la base
del prototipo; indica que él borrará los datos antes del uso real. Marcar ejemplos como
DEMO/[Prueba], no sobrescribir existentes al sembrar y no hacer ahora un borrado global.
Permanece vigente la preferencia de ejecutar solo comprobaciones necesarias.

Decisiones todavía pendientes

Diseño visual definitivo: base v0.1 en uso por petición del usuario en Phase 2;
la apariencia puede seguir iterándose con él.

Política concreta de generación de exportaciones grandes.

Momento exacto en que introducir Cloud Functions.

Estrategia definitiva para agregados de estadísticas.

Política final de caché y funcionamiento offline para operaciones económicas.

Reglas exactas para una futura baja completa de cuenta de usuario.

Añadir nuevas decisiones con ID y motivo.

No eliminar decisiones anteriores sin dejar constancia del cambio.
