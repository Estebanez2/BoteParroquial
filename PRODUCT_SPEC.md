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

Vigente 2026-10-30, D114–D115: el usuario rechaza v0.3 y pide otro aspecto global.
Paletas elegibles con claro/oscuro, guardadas en este móvil. Inicio pierde el panel
promocional; el grupo presenta foto panorámica y nombre/descripción debajo.
Participantes agrupa acceso a Personas/Miembros. Acciones económicas iguales en
resumen e historial; navegación general concentrada en la barra inferior.
Atrás desde una sección vuelve al resumen y desde este a Tus grupos. La revisión
física del nuevo resultado sigue pendiente. Ver docs/VISUAL_REDESIGN_V04_VALIDATION.md.

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

Avance autorizado del producto completo del 2026-10-17: creación/edición de grupos,
nombre de cuenta, informes/ficha económicos y CSV se han añadido parcialmente.
No son nuevos criterios para cerrar el MVP. Detalle y límites en
docs/FULL_PRODUCT_PROGRESS_2026-10-17.md; el resto de esta lista sigue sujeto a fase.

Después se añaden códigos de invitación, solicitudes/aprobación y salida/expulsión
como subconjunto de Phase 7. Rules publicadas y datos DEMO aislados. No cambian
los criterios de cierre del MVP ni habilitan enlaces, vínculos
generales, roles editables o transferencia. Registro:
docs/PHASE7_INVITATIONS_VALIDATION.md.

Readmisión añadida tras elección explícita: solicitudes con aprobación obligatoria
y retorno como miembro conservando vínculo e historia, incluso en entrada
automática. Evidencia: docs/PHASE7_READMISSION_VALIDATION.md.

Ampliación del 2026-10-18: vínculos únicos cuenta/persona con gestión manual y
auditoría, vista de pendientes, persona inactiva con advertencia y degradación
automática de admin al perder la persona activa. Sin cambios de movimientos ni
fotos; conservar vínculo al salir hasta desvinculación expresa. Fuera del MVP
inicial. Evidencia: docs/PHASE7_LINKS_VALIDATION.md.

Ampliación posterior del mismo día: gestión general de roles no owner y
transferencia por el propietario con Google y nombre exacto del grupo. Owner
anterior pasa a member, conservando vínculo e historial. No amplía los criterios
de cierre del MVP ni declara terminada la validación física. Evidencia:
docs/PHASE7_ROLES_TRANSFER_VALIDATION.md.

Continuación Phase 8 (2026-10-19), fuera del MVP original: configuración de cuotas
temporales/versiones y periodos de personas, con resumen de importes esperados,
integrada, con Rules publicadas/verificadas. No marca pagos ni genera deuda a partir de ingresos. Estado
de publicación, decisiones y comprobaciones: docs/PHASE8_QUOTAS_PERIODS_VALIDATION.md.

Continuación de Phase 8: asignaciones expresas de ingresos a meses, con propuesta
revisable, pagos parciales, pendientes, adelantos, sobrepagos y crédito sin asignar.
Anular/corregir deja de contar el reparto original; no se hereda al sustituto.
No se infieren pagos históricos ni deuda cuando falta configuración. Evidencia
de esa entrega: docs/PHASE8_ALLOCATIONS_VALIDATION.md.

Entrega posterior: devoluciones parciales desde un ingreso, con hasta cuatro meses
seleccionados y crédito sin asignar; anular restaura, corregir revisa expresamente
el sustituto. Una retirada normal conserva las cuotas. Las personas nuevas pueden
elegir primer mes al crearlas; omitirlo no crea obligaciones. No se modifican
datos anteriores automáticamente. Evidencia: docs/PHASE8_REFUNDS_VALIDATION.md.

Continuación autorizada de informes (2026-10-19): el usuario prioriza completar
dashboard e informes de cuotas antes de notificaciones. Se muestra cumplimiento
actualizado de los meses seleccionados, incluyendo pagos posteriores y devoluciones.
Pendiente solo hasta el mes actual; meses siguientes, previsión separada. El
dashboard distingue pendiente acumulado de cuotas/dinero del mes. Personas
inactivas conservan obligaciones históricas. Datos incompletos no son deuda cero;
sobrepagos no compensan otros meses/personas. Sin nuevas escrituras ni reglas.
Evidencia: docs/PHASE10_QUOTA_REPORTS_VALIDATION.md. Comparaciones/agregados,
notificaciones, recuperación general y exportaciones ampliadas siguen pendientes.

Phase 9 iniciada expresamente: registro de móviles por botón, preferencia por
grupo y bandeja privada implementados. Cerrar sesión confirma retirada cuando
el móvil estaba registrado. La generación automática sigue pendiente; el MVP
original no se redefine como completamente validado por estas ampliaciones.
Estado/evidencia: docs/PHASE9_NOTIFICATION_CLIENT_VALIDATION.md.

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
