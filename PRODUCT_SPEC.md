BoteParroquial — MVP

Este documento define únicamente el MVP inicial.

La aplicación completa está definida en:

docs/FULL_PRODUCT_SPEC.md

Objetivo del MVP

Permitir que unos pocos administradores gestionen conjuntamente un bote de dinero desde varios móviles.

Todos los administradores deben consultar los mismos datos mediante Firebase.

Aunque inicialmente exista un único bote utilizado por pocas personas, ninguna parte de la arquitectura debe asumir que solo existirá un grupo.

Login

El usuario inicia sesión mediante Google utilizando Firebase Authentication.

No existen contraseñas propias de BoteParroquial.

Una cuenta autenticada no obtiene automáticamente acceso administrativo.

Los permisos dependen de su membresía en cada grupo.

Grupos

El modelo debe permitir varios grupos.

Durante el MVP puede utilizarse inicialmente un solo grupo.

Cada grupo representa un bote independiente.

Contendrá:

miembros;

personas;

movimientos;

configuración propia.

Personas

Los administradores pueden:

consultar personas;

crear personas;

editar personas;

activar personas;

inactivar personas.

Una persona interna no tiene por qué tener una cuenta de la aplicación.

Las personas con movimientos económicos no se eliminan.

Ingresos

Un administrador puede registrar:

persona;

cantidad;

fecha efectiva;

descripción opcional.

También se almacena automáticamente:

usuario que registra el movimiento;

fecha de creación.

El dinero se almacena en céntimos.

Retiradas

Un administrador puede registrar:

cantidad;

fecha;

motivo;

persona opcional.

Una retirada puede pertenecer a una persona o al grupo en general.

Movimientos

Tipos:

income
withdrawal

Estados preparados:

active
cancelled
corrected

No se eliminan movimientos económicos directamente.

Saldo

Se calcula como:

ingresos activos - retiradas activas

No existe un saldo editable manualmente como fuente de verdad.

Historial

Debe permitir consultar movimientos ordenados cronológicamente.

Cada movimiento mostrará como mínimo:

tipo;

cantidad;

persona;

fecha;

descripción;

creador;

estado.

Roles del modelo

Aunque el MVP inicialmente utilice administradores, el modelo admite:

owner
admin
member

Los permisos completos de la futura versión están definidos en docs/FULL_PRODUCT_SPEC.md.

Uso sin conexión y recuperación (acordado en Phase 6)

Consultar los datos ya guardados con aviso de posible desactualización o información
incompleta. Confirmar operaciones económicas requiere conexión. Guardar localmente
el envío antes de escribir y comprobar su resultado al volver al grupo; un reintento
explícito conserva el mismo identificador y datos, sin reenvíos automáticos.
En un conflicto, permitir descartar solo el intento local tras revisar el historial
y confirmar. «Hoy» se determina por la zona del grupo, no por la zona del móvil.

Presentación del MVP

2026-10-16: editar la foto actual desde su imagen guardada, sin elegirla de nuevo;
cancelar conserva la anterior, guardar confirma los cambios. Aviso de actualización
sin confirmar oculto durante comprobaciones iniciales breves, sin afirmar que no
hay Internet cuando únicamente se están leyendo datos de caché.

Actualización posterior (2026-10-15): el usuario autoriza preparar fotos con
Supabase Storage, sin Firebase Storage/Blaze. Función remota y UI de fotos
integradas: cámara/galería, vista previa, guardado explícito y retirada confirmada.
Fotos privadas, personas internas independientes, permisos de D053/D055.
Usuario confirma fotos de personas/cuenta. Foto de cuenta predeterminada en los
grupos sin personalización, con permisos de cambio locales al grupo. Se añaden
caché privada sin parpadeo y recorte/zoom/rotación. El usuario confirma la corrección
en A059P; los permisos con otros roles siguen pendientes. Decisiones D057/D058.
Este acuerdo sustituye el aplazamiento de almacenamiento citado a continuación.
Permisos D053 conservados; detalles y pendientes en docs/SUPABASE_SETUP.md.

Ajuste visual acordado el 2026-10-15: rediseñar las funciones actuales según las
referencias del usuario. Iniciales para cuentas, personas y grupos sin imagen;
subidas de fotos expresamente aplazadas. Los permisos futuros de edición de fotos
se registran en DECISIONS; no habilitan todavía escrituras nuevas de perfiles,
grupos o membresías. No se adelantan funciones futuras dibujadas en las referencias.

Fuera del MVP inicial

No implementar todavía salvo fase específica:

cuotas mensuales;

pagos atrasados;

pagos adelantados;

notificaciones;

estadísticas avanzadas;

exportaciones;

invitaciones completas;

auditoría avanzada;

Cloud Functions;

Cloud Storage.
