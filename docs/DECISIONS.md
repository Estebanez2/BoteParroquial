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

Decisiones de Phase 5

D042 — Dashboard como inicio de grupo

El usuario elige abrir el resumen al entrar en un grupo. Personas, miembros y
movimientos tienen pantallas accesibles desde él. Los cálculos permanecen en
DashboardRepository y el estado en Riverpod; los widgets presentan modelos.
Totales históricos de movimientos activos, sin presentar métricas de cuotas futuras.

D043 — Actividad por último cambio registrado

El usuario elige cambios recientes, incluidas anulaciones/correcciones, en lugar
de ordenar por fecha efectiva. Mostrar cinco entradas; cada movimiento aporta su
último cambio, sin duplicar como registro nuevo el sustituto activo. No es auditoría
completa: esa funcionalidad sigue en Phase 11.

D044 — Proyección del MVP con flujos existentes

El usuario aprueba reutilizar los datos actuales en tiempo real sin modificar
Firestore, en vez de adelantar agregados/reglas. Esta implementación lee el historial
del grupo; optimizar con resúmenes/consultas acotadas cuando crezca sigue pendiente.
Conservar el contrato DashboardSummary para sustituir la fuente sin rehacer la UI.

D045 — Móvil desconectado y cierre del MVP

El usuario comunica que ha desenchufado el móvil. En Phase 5 se valida código/APK
sin afirmar pruebas físicas ni instalarlo. Solicita indicar las partes pendientes
del MVP; registrarlas en el apartado Phase 6 de ROADMAP y en la validación de Phase 5.
Siguen pendientes segunda cuenta, sincronización en dos móviles y hardening.

Decisiones de Phase 6

D046 — Consulta de caché y confirmación económica (2026-10-15)

El usuario elige consultar los datos guardados con aviso de posible desactualización,
en lugar de bloquear también las lecturas. Las operaciones económicas requieren
confirmación de servidor. No inferir frescura financiera de tener Wi-Fi: usar metadata
de Firestore. La primera consulta sin caché puede estar incompleta; avisarlo.

D047 — Recuperación persistente de envíos (2026-10-15)

El usuario elige conservar el envío pendiente para recuperar su resultado al volver.
Antes de escribir se conserva el ID y la intención en almacenamiento privado de la
app, separados por UID/grupo; no hay tokens ni credenciales. Al abrir el grupo se
consulta el servidor y solo un resultado coincidente confirma el envío. Si falta,
reintentar los mismos datos/ID exige confirmación; no reenviar automáticamente ni
sobrescribir el pendiente al iniciar otro envío. No se altera el esquema financiero.

D048 — Confirmación del Dashboard en móvil (2026-10-15)

El usuario comunica que reconecta el móvil y ha comprobado que funciona. Sustituye
el pendiente de comprobación genérica de Dashboard de D045; no acredita los casos
manuales aplazados de autenticación ni sincronización entre dos administradores.

D049 — Descartar un intento local en conflicto (2026-10-15)

El usuario permite descartar el intento local tras revisar el historial y confirmar,
en vez de bloquear nuevos envíos hasta revisión técnica. Exigir lectura de servidor
antes de limpiarlo; no borrar ni anular movimientos. Avisar de que descartar no
detiene una solicitud anterior en curso y que hay que revisar antes de registrar
de nuevo el dinero. Sin conexión o con otro intento distinto, conservar el pendiente.

D050 — Calendario del grupo (2026-10-15)

El usuario elige la zona horaria del grupo para determinar «hoy», aunque el móvil
esté en otra zona. Adaptar IANA en Service (timezone); la fecha efectiva sigue
siendo un día civil UTC. Zona inválida bloquea el envío. La hora del dispositivo
sigue aportando el instante de referencia; Rules conserva su cota de servidor.
No afirmar que esto implementa una validación exacta de zonas IANA en Security Rules.

Decisiones del rediseño por referencias

D051 — Dirección visual proporcionada por el usuario (2026-10-15)

Las ocho referencias sustituyen la propuesta visual inicial: verde oscuro,
menta, coral para retiradas, degradados, contornos finos y títulos serif. Reutilizar
App* y centralizar estilos. Predeterminado oscuro para reproducir la referencia;
se conserva la variante clara. Personas pasa a pantalla completa según la nueva
referencia; sustituye la composición en panel de D036, no sus reglas de dominio.

D052 — Alcance actual: estética e iniciales (2026-10-15)

El usuario elige rediseño con iniciales y posponer subidas de fotos, frente a activar
Firebase Storage/Blaze ahora. También elige rediseñar solo las funciones actuales,
sin adelantar estadísticas, invitaciones o notificaciones de las imágenes. No crear
controles inertes ni datos inventados para aparentar esas funciones. La cabecera de
grupo utiliza una cubierta con iniciales que admite imagen futura; AppAvatar admite
ImageProvider y fallback con iniciales de nombre y apellidos.

D053 — Permisos futuros de fotos (2026-10-15)

El usuario elige foto de cuenta propia y fotos independientes dentro de cada grupo:

- Foto global de cuenta: solo la cambia su dueño, no administradores de otro perfil.
- Foto de miembro en grupo: cada miembro cambia la suya; admin cambia las de
  miembros normales y no las de otro admin/owner; owner puede cambiar también admins.
- Imagen de grupo: solo owner (actualmente el creador con control completo).

Es un acuerdo de producto para la implementación posterior, no permisos desplegados.
Antes de habilitar fotos de personas internas, concretar su relación con la foto
de membresía y los vínculos usuario/persona. No inventar sincronización entre ellas.

D054 — Supabase para fotos (2026-10-15)

El usuario elige Supabase Storage para evitar activar facturación Firebase,
crea el proyecto, confirma la integración Firebase Auth y proporciona URL y clave
publishable. Firebase mantiene Google Sign-In y Firestore. Se prepara el SDK y
conexión diferida sin segundo login. Sustituye el aplazamiento de almacenamiento
de D052; las subidas aún no están implementadas. D053 mantiene los permisos de
producto. Falta elegir cómo autorizar contra los roles de Firestore; ninguna
política debe confiar en roles elegidos por el cliente. Ver docs/SUPABASE_SETUP.md.

D055 — Edge Function y privacidad de fotos (2026-10-15)

El usuario elige la función en Supabase para comprobar permisos actuales en
Firestore, sin replicar roles. Confirma que cada cuenta ve su foto y, dentro del
grupo, las fotos de los demás y la portada. Fotos privadas a través de la función.
Confirma foto independiente de persona interna, gestionable por owner/admin
autorizado, sin sincronización con cuenta/membresía. Completa D053 y resuelve
la elección de autorización pendiente de D054. Implementación local y pruebas
dirigidas disponibles. Actualización posterior: login autorizado, bucket y función
desplegados e integración UI realizada; validación física aún parcial.

D056 — Selección y tratamiento de fotos (2026-10-15)

El usuario elige galería y cámara. Ofrecer vista previa antes de guardar, iniciales
sin foto y retirada confirmada de la imagen, sin tocar historial financiero. La
foto de una persona se añade tras guardar su identidad. Preparar JPEG sin EXIF/GPS
y tamaño máximo 512 KiB. Fotos en memoria; al reanudar/volver se vuelven a leer,
sin prometer sincronización instantánea. Si Android termina el proceso del selector,
descartar el resultado sin contexto y volver a elegir, sin asignarlo a otra cuenta.

D057 — Foto de cuenta predeterminada y excepción por grupo (2026-10-15)

El usuario confirma fotos de personas y de cuenta, pero espera ver la propia en
Miembros. Elige usar la foto de cuenta por defecto con una foto alternativa por
grupo que admin/owner pueden cambiar según D053. La foto global continúa editable
solo por su dueño. El fallback se resuelve en servidor tras autorizar grupo y
membresía; no expone perfiles globales ni copia imágenes a todos los grupos.
Completa D055: otras cuentas del grupo pueden ver esa foto a través del contexto
del grupo, no por la ruta privada de cuenta. Personas internas siguen independientes.

D058 — Caché privada y edición antes de guardar (2026-10-15)

El usuario pide evitar la aparición provisional de iniciales y permite elegir
la implementación adecuada. Se añade caché privada por cuenta con límites,
presentación inmediata en memoria y revalidación de versión en segundo plano.
Se conserva la foto durante actualizaciones; una primera carga sin caché muestra
un espacio neutro. Limpieza por sesión/acceso y descarte de descargas tardías.
También solicita zoom, rotación y edición básica: editor nativo de recorte cuadrado
antes de la vista previa, con confirmación de guardado separada. No implica edición
destructiva de una foto existente hasta pulsar Guardar foto.

D059 — Edición de foto guardada y aviso sin parpadeo (2026-10-16)

Petición explícita del usuario: añadir «Editar foto actual» para abrir la imagen
guardada en el editor existente sin borrarla ni volver a seleccionarla. Mantener
cancelación segura, vista previa y guardado explícito, con permisos sin cambios.

El aviso de datos sin confirmar no debe aparecer durante la breve lectura inicial
de caché cuando hay conexión. Ocultar mientras carga y conceder dos segundos a la
confirmación; mostrar solo si sigue pendiente, y ocultar inmediatamente al confirmar.
El texto describe una actualización pendiente, sin inferir que no hay Internet
solo por metadata de Firestore. No relajar confirmaciones económicas de servidor.
El usuario asume la ejecución de la app para validar estos cambios.

D060 — Ampliación acotada del historial (2026-10-17)

El usuario solicita revisar el MVP y avanzar con una parte elegida de la
especificación completa, sin móvil y con pruebas mínimas. Se escoge búsqueda y
filtros del historial (apartados 56, 85 y 86), sin declarar cerradas las pruebas
físicas pendientes del MVP ni iniciar gestión completa de grupos.

Búsqueda por palabras en nombres de persona/creador, concepto y motivos de
anulación/corrección, ignorando mayúsculas, acentos y espacios sobrantes. Criterios
combinados por fecha efectiva inclusiva, persona (también inactiva), grupo sin
persona, tipo, estado y creador. Sin criterios se conservan todos los estados.
Aplicar confirma el formulario; cancelar lo descarta. Los filtros son temporales
por grupo/sesión, no se persisten y nunca cambian los totales del Dashboard.
El acceso directo a un movimiento por ID ignora filtros para poder seguir cadenas
de corrección. Se reutiliza el flujo actual del MVP, sin consultas nuevas, índices
ni reglas; paginación/búsqueda de servidor quedan pendientes para mayor volumen.

D061 — Creación y edición segura de grupos (2026-10-17)

El usuario autoriza continuar todo lo posible del producto completo. La creación
desde la app guarda grupo, owner inicial propio, persona opcional y evento de
auditoría en una transacción. El usuario elige crear por defecto la persona del
propietario con opción de omitirla. No se abre promoción de roles en grupos existentes.
Owner/admin autorizado edita nombre/descripción con versión y auditoría atómica;
moneda y zona se conservan. El alcance de creación aún no incluye cuota inicial
ni configuración de invitaciones. Grupos anteriores continúan siendo legibles.

D062 — Informes económicos y ficha individual iniciales (2026-10-17)

Se implementa el subconjunto económico mensual/trimestral/anual sobre los flujos
existentes del MVP: fechas efectivas, movimientos activos, saldo inicial y final,
serie mensual y desglose por persona. La ficha conserva todos los estados en su
historial. No son cierres contables inmutables ni estadísticas de cuotas/deuda.
Se mantiene el aplazamiento de agregados/consultas acotadas de D044.

D063 — Nombre de cuenta propio (2026-10-17)

Se habilita editar el nombre global propio, con validación y versión. El acceso
Google conserva el nombre de aplicación guardado. No se sincronizan automáticamente
nombres de miembros o personas ya existentes ni se modifica la cuenta Google.

D064 — Devoluciones y futuras asignaciones (2026-10-17)

El usuario elige que una devolución asociada a una persona pueda seleccionar qué
allocations se revierten; una retirada general no altera cuotas. Es una decisión
para Phase 8, todavía sin implementación de cuotas/allocations. No reinterpretar
retiradas históricas ni dar por deshechas asignaciones inexistentes.

D065 — Exportación CSV inicial por periodo (2026-10-17)

CSV con BOM UTF-8, separador punto y coma, campos entre comillas, importes enteros
en céntimos y todos los estados del periodo. Efecto de anulados/corregidos igual a
cero; conservar referencias de corrección y motivos. Neutralizar fórmulas en texto.
Desde la app solo owner/admin autorizado puede generarlo; consulta financiera de
servidor antes de compartir, tras comprobar sesión/acceso. Compartición nativa
encapsulada en Service mediante share_plus. El usuario elige destino en el móvil;
el agente no envía archivos a nadie. PDF/Excel siguen pendientes. La lectura de
datos económicos por miembros sigue permitida: esta restricción de la acción de
exportar no impide que un lector autorizado copie datos por otros medios.

D066 — Publicación autorizada y respaldo externo (2026-10-17)

El usuario pide expresamente publicar y usar las nuevas Rules tras guardar una
copia de las anteriores fuera de Git. Despliegues realizados y hashes comparados
con la fuente local. Restaurar Git no modifica el backend; volver a la copia de
Rules no revierte datos ni fotos. Evidencia de versión en
docs/PHASE7_INVITATIONS_VALIDATION.md; respaldo en docs/FIRESTORE_RULES_BACKUP.md.

D067 — Primera entrega de invitaciones y aprobación (2026-10-17)

Se implementa el subconjunto de códigos de los apartados 12/13 del producto:
activación, regeneración, aprobación o entrada automática configurables por
gestión autorizada. Miembros activos pueden compartir. Códigos de 192 bits,
formato groupId.secret, sin inventar dominios; vista previa mínima autenticada
para quien conoce el código, sin acceso anticipado al grupo. Entrada siempre
como member, personId=null. Ajustes, decisión/membresía y auditoría se validan
atómicamente. No se autoactivan invitaciones de grupos nuevos. Solicitudes ya
recibidas se conservan al cambiar código o desactivar; notificaciones/enlaces
permanecen en sus fases. La readmisión se concreta posteriormente en D069.

D068 — Salida y retirada de acceso conservan historia (2026-10-17)

Siguiendo los apartados 42/43/45: usuario no owner puede salir; owner/admin
autorizado retira acceso de no owner. Membresía inactiva y rol member, con
personId y joinedAt conservados y evento que guarda el rol anterior. No se borran
personas, movimientos ni fotos. Owner protegido; transferencia aún no disponible.
No se implementan promociones/degradaciones generales como efecto secundario.
Los ejemplos de esta entrega se aíslan en un grupo DEMO con precondición de
creación; sus UID ficticios no se presentan como pruebas de cuentas reales.

D069 — Readmisión con aprobación obligatoria (2026-10-17)

El usuario responde «Permitir solicitud con aprobación obligatoria». Quien salió
o fue expulsado puede solicitar volver usando un código vigente habilitado.
Debe aprobar owner/admin autorizado aunque requiresApproval=false para cuentas
nuevas. El solicitante no puede aprobarse ni recuperar el rol de administrador.
Se reactiva la misma membresía como member conservando personId y joinedAt;
no se crea otra persona ni se cambian su actividad o movimientos históricos.
La preview propia informa de la aprobación y la transacción vuelve a comprobar
la membresía/configuración actual. Auditoría y control de versión existentes.
Sustituye el bloqueo provisional de la entrega inicial de invitaciones.
Evidencia: docs/PHASE7_READMISSION_VALIDATION.md.

D070 — Vinculación con personas inactivas y reserva histórica (2026-10-18)

El usuario elige permitir vincular personas inactivas con advertencia, sin
reactivarlas ni permitir admin mientras estén inactivas. Reafirma conservar el
vínculo de quienes salen o son expulsados hasta que un gestor lo quite expresamente.

D071 — Vínculo recíproco, único y auditado (2026-10-18)

members.personId y persons.linkedUid cambian juntos, en transacción con auditoría
y control de versión. linkedUid es opcional en personas antiguas/sin vínculo.
Cambiar no traslada movimientos, nombres ni fotos. Owner/admin autorizado gestiona
vínculos; solo owner cambia el suyo. Para una cuenta inactiva se habilita quitar
el vínculo reservado; asignar uno nuevo requiere antes readmisión. «Sin vínculo»
lista miembros activos. La preparación anterior detecta duplicados/huérfanos y
se detiene si los hay; no vincula por coincidencia de nombre.

D072 — Pérdida automática de administración (2026-10-18)

Se aplica 10.4: desvincular admin, vincularlo a persona inactiva o inactivar su
persona degrada role a member en el mismo commit con auditoría. Reactivar no
devuelve admin. Owner mantiene su protección y puede existir sin persona.
No se habilitan promociones ni gestión general de roles. No se depende de tareas
en segundo plano para quitar permisos. Ver docs/PHASE7_LINKS_VALIDATION.md.

D073 — Gestión general de administradores (2026-10-18)

Continuación autorizada del producto: se implementan 9.2 y 10.2–10.4. Owner y admin
autorizado pueden ascender miembros y degradar admins, incluida la degradación
propia; nunca modificar owner. Promoción exige cuenta activa y persona activa
vinculada de forma recíproca. Solo role/metadatos y auditoría atómica; no cambia
el vínculo ni se recuperan roles automáticamente. Amplía D072 sin sustituir su
degradación automática. No se implementan notificaciones de cambios de rol.

D074 — Transferir propiedad conserva historia y deja al anterior como miembro (2026-10-18)

El usuario elige «Pasar a miembro» y «Verificar Google y escribir el nombre».
Solo owner entrega el control a otro miembro activo con persona activa vinculada.
Se conserva personId/joinedAt e historial de ambas cuentas. Ambas membresías,
metadatos del grupo y un evento inmutable cambian juntos. No usar createdBy como
owner actual ni modificarlo al transferir; no añadir una segunda fuente de roles.
El antiguo propietario pierde gestión y puede salir posteriormente como miembro.

D075 — Verificación de la misma cuenta y rechazo de cambios concurrentes (2026-10-18)

La app reautentica el usuario Firebase existente mediante Google, comprueba UID,
fuerza token renovado y exige nombre exacto del grupo. No inicia sesión como otra
cuenta. Cancelar/cambiar sesión no envía. Provider y transacción vuelven a comprobar
versiones y elegibilidad. Rules exige proveedor Google, auth_time no futuro de los
últimos cinco minutos y las dos transiciones; no basta ocultar botones. La confirmación
humana pertenece a UI; Rules valida nombre y credencial, no puede demostrar que
el texto se tecleó manualmente. Reintentar requiere revisar el resultado; no hay
reenvío automático. Evidencia: docs/PHASE7_ROLES_TRANSFER_VALIDATION.md.

D076 — Base de cuotas sin inferir deuda de datos incompletos (2026-10-19)

Se comienza Phase 8 mediante modelos de meses/reglas/periodos y proyección pura.
Los importes son enteros; precios temporales y periodos explícitos determinan cada
mes. Falta de configuración de participación o de precio se conserva como estado
incompleto. No confundir importe esperado con cuota pagada, deuda, crédito o saldo.
No se infieren periodos a partir de createdAt/isActive ni pagos a partir de ingresos.
Es preparación técnica del producto especificado, sin nueva política de aplicación,
documentos remotos o reglas publicadas. Evidencia: docs/PHASE8_FOUNDATION_VALIDATION.md.

D077 — Aplicación temporal de cuotas y participación (2026-10-19)

El usuario responde expresamente: cambios de cuota desde el mes siguiente; primer
mes de cada persona elegido expresamente; último mes computable al inactivar
elegido expresamente, con propuesta del actual. La primera cuota del grupo permite
elegir su inicio. No se asignan periodos automáticamente a personas anteriores.

En preguntas posteriores elige permitir cuota 0 como suspensión temporal para el
grupo y sustituir cuotas futuras conservando las versiones anteriores. Nunca
modificar meses actuales/pasados ni borrar versiones. Implementación local de
reglas por mes, versiones inmutables, periodos y auditoría en transacción.
Evidencia y estado remoto: docs/PHASE8_QUOTAS_PERIODS_VALIDATION.md.

D078 — Baja y vuelta en el mismo mes cuentan una sola vez (2026-10-19)

El usuario elige contar el mes una sola vez, aunque aparezca al cerrar la etapa
anterior y abrir la nueva. Puede reactivarse inmediatamente. Se permite igualdad
entre último mes anterior y primer mes nuevo; se rechazan solapamientos interiores.
La proyección emite una única obligación por mes. Ordena una etapa cerrada antes
de la abierta si comparten inicio, sin depender del orden de llegada. Sustituye
la restricción más estricta de la base inicial. No reescribe las etapas anteriores.

D079 — Reparto tras anular o corregir un ingreso (2026-10-19)

El usuario elige revisar expresamente el reparto del sustituto. Las asignaciones
del ingreso original permanecen registradas, pero solo pagan meses si su ingreso
sigue active. Anular/corregir deja de contarlas; no se copian al sustituto aunque
coincidan persona e importe. No se borran ni reescriben asignaciones históricas.

D080 — Propuesta revisable y hasta doce meses futuros (2026-10-19)

El usuario elige hasta doce meses futuros después de los pendientes anteriores y
el mes actual. El sobrante es crédito sin asignar. La propuesta no supera lo
pendiente de cada mes y usa solo el dinero aún libre de ese ingreso. Una cuota
desconocida impide adivinar el reparto; periodos ausentes no son deuda cero.
Esta entrega confirma un mes cada vez y recalcula después; no aplica todos en
segundo plano ni introduce un límite de doce meses a la asignación manual.

D081 — Sobrepago manual y ajuste del reparto sin tocar el bote (2026-10-19)

El usuario acepta sobrepago manual con advertencia. Se muestra por separado y no
compensa otros meses automáticamente. La diferencia global asignado-esperado no
sustituye la suma de meses pendientes. Un ingreso puede pagar varios meses y un
mes recibir varios ingresos. Nunca repartir más que el importe del ingreso.
El ajuste indica el total de ese ingreso para ese mes, no un incremento implícito;
0 libera el importe manteniendo registro y auditoría. Nuevas asignaciones exigen
mes incluido en una etapa; pueden liberarse las que queden fuera tras una baja.
Precio desconocido se advierte y no acredita cumplimiento. Las transacciones
online acoplan reparto, contador de límite por ingreso y evento inmutable.
En aquella entrega seguían pendientes las devoluciones de D064; se incorporan
posteriormente en D082–D084. Una retirada ordinaria no modifica cuotas.
Ver docs/PHASE8_ALLOCATIONS_VALIDATION.md como evidencia de ese bloque anterior.

D082 — Devoluciones parciales de cuotas y crédito (2026-10-19)

El usuario elige combinar asignaciones seleccionadas y crédito sin asignar de una
persona en una devolución, también parcialmente. El ingreso de origen permanece
intacto y active; la retirada tiene importe positivo y conserva el reparto de lo
devuelto. Una retirada ordinaria no altera cuotas. Las asignaciones brutas se
conservan y los pagos netos descuentan solo devoluciones active. El contador por
ingreso impide duplicar dinero o repartir lo ya retornado. Amplía D064 y D081.

D083 — Anular y corregir devoluciones conjuntamente (2026-10-19)

El usuario elige restaurar cuotas/crédito al anular y revisar expresamente el
reparto del sustituto al corregir. La corrección empieza vacía y requiere
confirmación. Conserva original, sustituto y evento inmutable; restaura/aplica
en una transacción. Conflictos de disponibilidad o versión bloquean todo el
commit. No anular/corregir el ingreso mientras tenga devoluciones activas.
Convertir la devolución en movimiento normal también exige confirmar la
restauración; el sustituto normal no afecta cuotas automáticamente.

D084 — Primera devolución por ingreso y hasta cuatro meses (2026-10-19)

El usuario elige un ingreso de origen y hasta cuatro meses seleccionados más su
crédito sin asignar por operación. La corrección conserva origen y la unión de
meses original/sustituto también debe caber en cuatro; para cambiar más o cambiar
origen, anular y registrar otra devolución. Fecha desde la del ingreso hasta hoy
del grupo. No se incorpora backend privilegiado ni se permite saltar límites de
Rules; se distribuyen validaciones entre testigos obligatorios del mismo commit.

D085 — Primer mes opcional durante el alta de persona (2026-10-19)

Se incorpora el alta opcional prevista por el producto y D077. Por defecto se
elige más adelante; si se selecciona ahora, se confirma el mes y se crean persona,
periodo y auditoría juntos. No deducirlo de createdAt ni asignarlo a las personas
existentes. Solo hasta el mes actual del grupo; sin altas futuras programadas.
La persona inicial opcional de un grupo continúa eligiéndolo desde su ficha.

D086 — Nuevo punto de recuperación antes de devoluciones (2026-10-19)

Tras el rechazo de revisión automática, el usuario pide una copia nueva del
estado actual y autoriza expresamente incorporar/publicar las reglas y validarlas.
Se conserva copia remota de reglas activas de asignaciones, ZIP de archivos
locales incluidos cambios sin commit y APK previo, fuera de Git. No se sustituye
el respaldo del MVP. Es copia de código/permisos, no de documentos o fotos.
El ZIP incluye el trabajo local en curso, distinto de las reglas remotas; dejarlo
explícito al restaurar. Evidencia/hashes: docs/PHASE8_REFUNDS_VALIDATION.md.

D087 — Priorizar dashboard e informes de cuotas (2026-10-19)

El usuario elige completar estos resúmenes antes de Phase 9. Se reutilizan datos
y permisos actuales, sin incorporar otro servicio ni notificaciones. La opción de
Supabase/FCM para avisos se explicó, pero no queda elegida ni configurada por esta
respuesta. Comparaciones y agregados para volumen continúan en otro bloque.

D088 — Informes de cuotas con estado actualizado (2026-10-19)

El usuario elige estado actualizado hasta hoy, igual que la ficha individual.
Un pago posterior asignado a un mes pasado lo salda en ese mes y una devolución
activa reduce su pago. No reconstruye cómo estaba al cierre ni guarda snapshots
contables. Caja mantiene fecha efectiva; pago de cuota mantiene mes asignado.
Personas inactivas conservan los meses de sus periodos históricos.

D089 — Pendiente hasta el mes actual y previsión separada (2026-10-19)

El usuario elige que un periodo en curso solo acumule pendiente hasta el mes actual
del grupo. Meses posteriores del periodo se muestran como previsión, con su cuota
y pagos adelantados, sin sumarlos al pendiente actual. Un periodo totalmente futuro
no tiene deuda actual; su obligación prevista aparece en el bloque futuro.
El dashboard distingue acumulado histórico, cuotas del mes y caja del mes.

D090 — Cobertura por obligación y configuración incompleta (2026-10-19)

Aplicación de D077/D081: cobertura suma el menor de pago neto/cuota de cada persona
y mes, sin compensar con excesos otras obligaciones. Porcentaje entero en puntos
básicos (0..10000), sin desbordamiento intermedio; representación a una décima.
Si falta participación/precio en ese tramo, pendiente y porcentaje son desconocidos.
Si esperado es cero, no hay porcentaje ni se etiqueta como persona pagada por esa
ausencia de cuota. Se muestran estados sin cuota computable y sin configurar.
El crédito sin asignar no acredita pagos; su resumen global actual se diferencia
del periodo seleccionado. No se añade una regla de compensación automática.

D091 — Supabase + FCM y hora de los recordatorios (2026-10-19)

Tras preguntar por costes/diferencias, el usuario elige Supabase para el proceso
programado y Firebase Cloud Messaging para entregar push, condicionado al uso
gratuito. FCM figura sin coste; Supabase Free incluye 500.000 invocaciones de
Edge Functions, con otros límites de recursos/transferencia. No equivale a uso
ilimitado ni permite activar un plan de pago o Blaze sin nueva autorización.
Mantener Firebase Authentication y Firestore; no crear otra sesión de usuario.
El usuario elige las 10:00 en la zona horaria de cada grupo para los avisos de
7 días y 1 día antes del último día del mes, según la especificación.
La hora/backend están elegidos, pero el servidor/cron y el cliente push todavía
no están implementados ni configurados. Las consultas de preparación confirmaron
FCM habilitado y permisos disponibles de la sesión CLI; no asignaron permisos ni
crearon claves. Contrato, fuentes y pendientes: PHASE9_NOTIFICATIONS_FOUNDATION.md.

D092 — Push discreto y resumen de personas sin cuenta (2026-10-19)

El usuario elige push con texto discreto, sin cantidades de cuota, pagado ni
pendiente. El detalle económico se consulta dentro de la app autorizada. Para
personas sin usuario vinculado, los gestores reciben un resumen por grupo, no
un aviso separado por persona. El agrupado no permite revelar cuotas de otros
grupos ni duplicar avisos a un mismo gestor. Son requisitos del futuro worker;
la entrega actual no genera aún mensajes, agregación de destinatarios o bandeja.
Preferencias/categorías y demás destinatarios de §53 siguen por concretar.

D093 — Consentimiento explícito y preferencias por grupo (2026-10-19)

El usuario elige el botón «Activar avisos en este móvil», no pedir permiso al
entrar. Auto-init desactivado hasta ese consentimiento. Permite desactivar push
de recordatorios para un grupo y conservar los demás; la bandeja conserva sus
avisos. Implementación inicial: una preferencia ausente permite recordatorios,
pero el servidor no puede entregar nada sin un dispositivo registrado previamente
por elección expresa. Esta preferencia no decide otras categorías futuras de §53.

D094 — Confirmar retirada antes de cerrar sesión (2026-10-19)

El usuario elige esperar a tener conexión y confirmar la retirada cuando este
móvil estaba registrado. Sin registro, logout mantiene su flujo anterior. Un
error de retirada no cierra la sesión. Journal privado guarda UID, huellas de
tokens e intención enabled/retirar antes de operaciones remotas; no guarda el
token de entrega. Al reiniciar se termina una retirada, nunca se convierte en
un alta automática. Se confirma servidor, se invalida token nativo y se limpia
journal antes de salir. No afecta a otros móviles. Un cambio externo inesperado
de cuenta invalida el token local antes de permitir su uso con otra cuenta.
No revoca mensajes que FCM ya hubiera aceptado/entregado antes de la retirada.

D095 — Publicación de permisos de la bandeja con nueva copia (2026-10-19)

La revisión automática rechaza inicialmente publicar los nuevos permisos por
considerar que la autorización anterior cubría devoluciones. Se prepara un
candidato concreto y se explica el bloqueo en PHASE9_NOTIFICATION_RULES_REVIEW.md.
El usuario autoriza después: «haz como antes, una copia de lo que ya funciona
y después ya las publicas». Guardar nuevas reglas activas, proyecto local y APK
antes de publicar; distinguir el código ya preparado en local de los permisos
remotos todavía anteriores. No sobrescribir copias previas ni llamar a esto
un respaldo de documentos/usuarios/fotos. Estado final y evidencia:
PHASE9_NOTIFICATION_CLIENT_VALIDATION.md.

D096 — Antiguos miembros y recuperación del recordatorio (2026-10-20)

El usuario elige incluir en el resumen de gestores las personas activas con cuota
pendiente cuyo usuario vinculado salió o fue expulsado. Ese usuario no recibe el
aviso ni recupera acceso por conservar el vínculo. El cálculo comprueba membresía
y vínculo recíproco; no libera ni reasigna la relación histórica.

Si el programador no consigue ejecutarse a las 10:00, se recupera durante el resto
del mismo día local del grupo, sin duplicados. No se arrastra al día siguiente.
La identidad lógica conserva grupo/mes/etapa/categoría/destinatario al reejecutar.
En esta entrega se comprueba cálculo y lectura consistente; faltan persistencia
de reservas, conexión del worker, credenciales, cron y entrega real. La decisión
de evitar duplicados no equivale a que FCM garantice exactamente una entrega.
Evidencia: PHASE9_REMINDER_SERVER_CALCULATION.md.

D097 — Actividad nueva y entregas inciertas (2026-10-20)

El usuario elige empezar desde la activación, sin notificar el historial de
pruebas. Activación real: 2026-10-20T09:39:44.515Z. Los recordatorios consultan
cuotas actuales. Prefiere perder un push incierto a duplicarlo: reserva duradera
antes del envío, sin repetir esa reserva tras caída/timeout; bandeja conservada.
FCM no garantiza exactamente una entrega. Implementación y evidencia en
PHASE9_NOTIFICATIONS_AND_LINKS_VALIDATION.md.

D098 — Destinatarios y categorías de actividad (2026-10-20)

Distribución aceptada: solicitudes/entradas y falta de vínculo a gestores;
aceptación, vínculo y rol al afectado; movimientos a cuenta vinculada; cuota a
miembros; transferencia a gestores y afectados; código regenerado a gestores.
Sin autoavisos al autor salvo cambios de su acceso/vínculo/rol. Acceso y contexto
vigentes se releen. Preferencias push independientes: recordatorios, económico
e informativo por grupo; todas conservan bandeja. Textos discretos sin importes.

D099 — Dominio gratuito de invitaciones (2026-10-20)

El usuario elige Firebase Hosting gratuito. Dominio existente comprobado:
https://boteparroquial.web.app. Enlace /join/{código}; Android App Links con huella
debug real y página de ayuda si no abre la app. Conserva código durante login,
no URLs de retorno arbitrarias. Abrir no concede membresía. Firma release/Play,
iOS Team ID/AASA y prueba física pendientes; no inventar valores.

D100 — Separación de secretos en dos Supabase (2026-10-20)

Tras explicar que Edge Functions de un proyecto comparten acceso potencial a
secretos, el usuario elige otro proyecto Free para notificaciones. Lo crea
manualmente: BoteParroquialNotificaciones, qngrmxfjckrrfiyioyzl, eu-west-1. Fotos
permanece en ietnizafvtovelyuxbvk, sin credencial privilegiada Firebase. No activar
Blaze ni planes de pago; gratis sujeto a cuotas vigentes, no uso ilimitado.
Desplegar cada función nombrada al ref correcto; no ejecutar deploy indiscriminado.

D101 — Comprobación de actividad cada quince minutos (2026-10-20)

El usuario elige quince minutos tras aclarar que es frecuencia de consulta, no
frecuencia de avisos repetidos. Cron */15 * * * * activo. Actividad puede tardar
aproximadamente ese intervalo; recordatorios mantienen las 10:00 del grupo y
recuperación durante su mismo día (D096), no al siguiente.

D102 — IAM y transferencia de credencial autorizados (2026-10-20)

Dos rechazos automáticos se resolvieron mediante autorizaciones expresas distintas:
crear identidad/rol, y crear/transferir su clave solo al segundo Supabase. Rol
dedicado con seis permisos de lectura/creación/actualización Firestore y envío
FCM, sin borrado ni administración Auth/Rules/IAM. IAM no limita por documento;
el usuario fue informado del alcance y el adaptador restringe rutas en código.
Credencial solo en NOTIFICATION_FIREBASE_CREDENTIALS del proyecto nuevo; temporales
eliminados, ID de clave en registro externo. Nueva copia previa conserva Rules,
proyecto/APK, referencia Hosting y políticas IAM; no documentos ni fotos.
Ver PHASE9_NOTIFICATIONS_AND_LINKS_VALIDATION.md y no reprovisionar a ciegas.

D103 — Comparar el mismo tramo transcurrido (2026-10-20)

El usuario elige mismo tramo transcurrido para mes/trimestre/año en curso, en
lugar de compararlo con el periodo anterior completo. Caja llega hasta hoy civil
del grupo, incluido; el lado anterior se corta en el mismo mes relativo y día,
ajustando al último día si ese mes es más corto. Periodos terminados comparan
ambos completos. Fechas explícitas y sin comparación de hechos para futuros.
Cuotas conserva D088–D090: meses computables completos hasta cada corte, estado
actualizado de pagos/devoluciones hasta hoy, sin prorrateo diario o reconstrucción
histórica. Diferencia de cumplimiento en puntos porcentuales; porcentaje relativo
solo con base anterior positiva y conocida. Evidencia de la implementación:
PHASE10_PERIOD_COMPARISONS_VALIDATION.md.

D104 — Consultar auditoría antigua mediante botón (2026-10-20)

El usuario elige «Cargar más» frente a carga automática al desplazarse, para
controlar las lecturas. Se consultan cincuenta eventos y un testigo de continuidad
por página, sin limitar la vista a cien eventos. Búsqueda/filtros sobre los ya
cargados, con alcance explícito; no descarga automática de todo el historial.
La cabecera se mantiene reactiva hasta empezar a paginar; después anuncia cambios
nuevos para actualizar sin mezclar fronteras. Cursor ligado al grupo, timestamp
completo e ID; antes/después y permisos actuales también en el detalle abierto.
No cambia qué operaciones escriben auditoría ni habilita papelera/eliminación.
Evidencia: PHASE11_AUDIT_HISTORY_VALIDATION.md.

D105 — Reinicio de demostración y copia puntual (2026-10-20)

El usuario autoriza al final de esta continuación borrar documentos Firestore y
fotos Supabase, conservando cuentas Authentication y configuración. Antes se
guardará una copia puntual recuperable. Dos grupos DEMO pertenecen a
ale.manu.cristi@gmail.com. Aplaza expresamente la copia semanal local y el visor;
no se configura ninguna tarea periódica. Registro: FULL_PRODUCT_COMPLETION_2026-10-20.md.

D106 — Papelera solo sin historial ni vínculo (2026-10-20)

Elegido por el usuario: solo personas sin movimientos, asignaciones, periodos de
cuota ni cuenta vinculada; restauración durante diez días. Quienes tienen historia
se inactivan. La elegibilidad debe resistir operaciones concurrentes, sin confiar
en comprobar una lista vacía en el cliente. No migrar garantías de historia a
personas antiguas sin comprobar sus referencias.

D107 — Eliminación definitiva de grupo con Google y nombre exacto (2026-10-20)

Elegido por el usuario: nueva verificación de la misma cuenta Google y nombre
exacto. Antes mostrar saldo, personas, miembros y movimientos, recomendando
exportar. Solo el propietario actual; bloquear operaciones y accesos antes de
limpiar, conservar progreso ante interrupción. Es la excepción expresa de grupo
completo a la prohibición habitual de borrar movimientos individualmente.

D108 — Baja de cuenta preservando historia (2026-10-20)

Elegido por el usuario: transferir o eliminar primero sus grupos propios; después
retirar accesos, dispositivos y fotos propias. No eliminar personas internas ni
historia económica de otros grupos. No confundir esta baja con borrar Google.
Conservar un testigo mínimo ante un resultado incierto para poder reanudar.

D109 — Mantener cifras actuales mediante consultas agregadas (2026-10-20)

El usuario elige consultas agregadas de Firestore para caja y optimizar las
lecturas compartidas de cuotas, en vez de servir resúmenes de servidor que pueden
retrasarse quince minutos. Las consultas de suma no tienen escucha ni caché propias:
una escucha acotada de cambios dispara su actualización; se conserva una última
confirmación privada por cuenta para consulta offline. Mantener enteros exactos,
misma instantánea entre sumas y fecha de confirmación visible. No inferir que la
proyección de cuotas o todos los informes pasan a ser agregados persistidos.

Decisiones todavía pendientes

Las decisiones D110–D112 añadidas al final resuelven la nueva petición de copias
diarias en el móvil. No reactivan la copia semanal del portátil aplazada en D105.

Aprobación visual en móvil de v0.4 (D114–D115). El usuario rechaza el resultado
v0.3 y solicita la nueva dirección; no considerar aprobada aquella propuesta.

Política concreta de generación de exportaciones grandes.

Momento exacto en que introducir Cloud Functions.

Estrategia definitiva para agregados de estadísticas.

Caché y confirmación económica del MVP decididas en D046; reevaluar la política
si una fase futura introduce escrituras económicas offline.

Los criterios de baja de cuenta quedan resueltos en D108.

Añadir nuevas decisiones con ID y motivo.

No eliminar decisiones anteriores sin dejar constancia del cambio.

D110 — Siete copias diarias de consulta en cada móvil (2026-10-23)

El usuario elige las últimas siete copias diarias completas, una por día de
apertura/reanudación con conexión. Si no abrió la app un día, conservar la última
disponible con su fecha real; no fabricar una copia de ayer. Son siete días de
capturas satisfactorias, no trabajo programado con la app cerrada. Cada móvil
mantiene su archivo por cuenta. Solo datos consultables de sus grupos, sin cuentas
ajenas, secretos o registros privados de dispositivos. La copia se abre expresamente
en solo lectura, separada de caché/servidor y con fecha visible. No es restauración.

La implementación usa el readTime del servidor y calendario Europe/Madrid para el
día de archivo; el calendario de cada grupo sigue gobernando sus cálculos, congelado
en el instante copiado. La primera copia completa del día no se sobrescribe por
otra apertura. Fallos o descargas parciales conservan la anterior. Al confirmar
revocación/cambio de acceso se retira ese grupo de archivos y visor; sin conexión
no se puede descubrir una revocación nueva. Limpieza al salir/cambiar de cuenta.

D111 — Copia de datos, fotos según caché (2026-10-23)

El usuario elige datos Firestore completos de su ámbito y fotos disponibles en la
caché privada existente. No descargar todos los binarios ni prometer imágenes
históricas del mismo instante. Avisarlo en el catálogo y en el modo copia.

D112 — Descargar copias con Wi-Fi o datos móviles (2026-10-23)

El usuario permite ambas conexiones. La copia automática necesita Internet y
consume lecturas/tráfico según la cantidad de información. No activar facturación,
cron, servidor nuevo ni permisos privilegiados. UI normal sigue usando sus flujos
actuales; el fichero completo se obtiene de servidor con fecha coherente, no de
una caché que puede estar incompleta. Evidencia: DAILY_OFFLINE_COPIES_VALIDATION.md.

D113 — Rediseño integral, dirección más expresiva (2026-10-30)

El usuario solicita cambiar el aspecto de la app con dos referencias móviles,
extender su lenguaje a los componentes que faltan y consultar webs/repositorios
de diseño y, especialmente, animación. Entre seguir muy fielmente las capturas
y reinterpretarlas con más personalidad, elige expresamente «Más expresivo».
Base carbón y menta, titulares con más presencia, profundidad y movimiento más
visible. Sustituye la dirección serif de D051: v0.3 usa Manrope también en títulos
y saldos. Se conservan tema claro, texto ampliado y movimiento reducido.

Aplicación de esta dirección: componentes App* compartidos, entradas escalonadas,
respuesta de pulsación, ornamentación orbital y navegación inferior entre vistas
existentes. Forui y Flutter Animate sirven de referencia; los efectos se adaptan
al SDK de Flutter, centralizados en el sistema visual. Los adornos no representan
series económicas ni justifican cifras ficticias. Evidencia, APK y pendientes:
VISUAL_REDESIGN_V03_VALIDATION.md. La implementación no equivale a aprobación
estética en dispositivo; el usuario ejecuta la app.

D114 — Nueva estética y apariencia local elegible (2026-10-30)

El usuario indica que no le gusta el resultado v0.3 y pide cambiar completamente
la estética de todas las pantallas, con varias paletas vivas/oscuras/profesionales,
cada una con claro y oscuro. Elige expresamente guardar la elección en este móvil,
sin sincronizarla con la cuenta. Implementación v0.4: Atlántico, Iris, Coral,
Bosque y Grafito; modo Sistema/Claro/Oscuro, base inicial Atlántico/Sistema.
Ajustes desde Inicio y Tu perfil; cambio inmediato y persistencia local con
reintento visible ante fallo. Se retira el panel «CADA APORTE CUENTA» completo.

D115 — Atrás al resumen, Participantes y portada panorámica (2026-10-30)

Ante la pregunta explícita, el usuario elige que Atrás desde Actividad,
Participantes o Informes vuelva al resumen del grupo, y desde ese resumen a
la lista de grupos. No salir de la app desde esas pantallas. La barra renombra
Personas a Participantes y abre una página para elegir Personas o Miembros.
El resumen usa portada horizontal de ancho completo y nombre/descripción debajo.
Ingreso/retirada deben ser iguales en resumen e historial. Se retiran los accesos
generales duplicados a movimientos/personas/miembros/informes del resumen, también
el enlace general de informe de cuotas. Las cifras y detalles de cuotas permanecen.
Estado, pruebas y pendientes: VISUAL_REDESIGN_V04_VALIDATION.md.

D116 — Recorte según destino y aviso de cambios sin guardar (2026-11-02)

El usuario pide que el editor respete las fotos rectangulares y que Atrás avise
si ha cambiado datos sin guardarlos. Portadas de grupo 16:9 según D115; avatares
cuadrados. No transformar imágenes guardadas automáticamente. Aviso reutilizable
en personas, perfil, grupos, movimientos, fotos y nueva selección de primeros
meses, tanto en flecha/Cancelar como Atrás del sistema. Conservar al seguir
editando; salir solo al descartar o tras guardado confirmado. No persistir
borradores implícitamente ni prometer protección ante cierre forzado.

D117 — Primer mes visible con selección múltiple (2026-11-02)

El usuario confirma que «completar datos» significa elegir el primer mes de cuota
y elige bloque visible en Personas, selección múltiple y mes común antes de
confirmar. Solo personas activas sin etapa configurada; nunca inventar el mes a
partir del alta. Reutilizar operaciones individuales atómicas y auditadas: informar
resultado parcial y detener ante fallo; no anunciar atomicidad del conjunto. No
crear pagos ni modificar periodos existentes o reactivar personas.

D118 — Ampliar las cinco paletas con varios acentos (2026-11-02)

El usuario elige mantener las cinco actuales y añadir colores complementarios y
otros acentos en la misma paleta. Atlántico azul/ámbar/lavanda, Iris violeta/lima/
rosa, Coral coral/turquesa/violeta, Bosque verde/frambuesa/ocre y Grafito neutro con
cobre/petróleo. Conservar modos claro/oscuro/Sistema, guardado local y semántica
de errores/avisos. Tokens compartidos, contraste y transiciones completos.

D119 — Solicitar avisos en la primera entrada (2026-11-02)

El usuario sustituye D093: pedir permiso de notificaciones al entrar por primera
vez, sin obligar a buscar el control por grupo, y mantener ese control para
desactivar/reactivar. Se solicita al tener la cuenta autenticada para asociar el
dispositivo correcto. Elección local por UID/móvil; no repetir tras rechazo o
retirada expresa. Mantener controles de Perfil y preferencias independientes por
grupo. Las preferencias ausentes ya valen activo; no sobrescribir false existentes.
Logout conserva la retirada y no se autoriza reactivación automática después.
No implica nueva configuración de worker/cron, IAM, APNs ni entrega física validada.

Alcance y evidencia D116–D119: UX_IMPROVEMENTS_2026-11-02.md.

D120 — Carga con formas y banda de brillo compartidas (2026-11-02)

El usuario sustituye círculos de espera por formas del objeto con brillo diagonal
de izquierda a derecha, en toda la app. AppShimmer/AppSkeleton y variantes viven
en design_system; LoadingIndicator, fotos y botones heredan su presentación.
Respetar movimiento reducido, semántica y datos ya disponibles. No mostrar dinero
ficticio, animar cifras ni convertir barras de gráficos en indicadores de espera.

D121 — Añadir flotante y Copias en cuenta (2026-11-02)

El usuario elige expresamente botón flotante «Añadir» con Crear grupo y Entrar con
código, y mover Copias al menú de cuenta. Mantener Añadir visible al desplazar
muchos grupos y dejar espacio para no tapar el último. Sustituye esos accesos
al final de la lista y Crear junto al título. No habilitar creación en copias.

D122 — Menús con presentación propia en la biblioteca (2026-11-02)

El usuario pide mejorar cualquier desplegable, especialmente el perfil. Componer
identidad, iconos, superficies, selección y separación desde AppMenuRow/App* y
PopupMenuTheme central; mantener controles nativos de foco/cancelación/animación.
No introducir reglas de permisos dentro de componentes visuales.

D123 — Fuente elegible por móvil (2026-11-02)

El usuario solicita elegir letra como las paletas. Ofrecer Manrope, Newsreader
ya empaquetadas y Sistema, aplicadas por AppTheme/AppTypography a toda la app,
incluido el visor aislado por ThemeData. Guardar en apariencia local existente;
no descargar fuentes ni sincronizar con UID. Base anterior Manrope se conserva.

D124 — Paletas personales de tres colores y vista previa (2026-11-02)

El usuario elige principal/complementario/tercer acento con fondos y contraste
automáticos, y añade expresamente un widget de ejemplo antes de crear/guardar.
Selector de color y preview reutilizables en design_system; claro/oscuro visibles
antes de guardar. Conservar semillas RGB originales y ajustar tonos para lectura.
Varias paletas locales con nombre, edición e eliminación; ningún dato de Firestore.
Preferencias por instalación según D114, independientes de cuenta y teléfono.
Conservar cinco predefinidas, estados semánticos y fuente/modo al cambiar paleta.

Evidencia y pendientes D120–D124: VISUAL_LIBRARY_2026-11-02.md.

D125 — Cuadrado de color y barra arcoíris (2026-11-02)

El usuario confirma cuadrado donde arrastrar para intensidad/luminosidad y barra
arcoíris para tono, manteniendo entrada hexadecimal completa. Sustituye los tres
deslizadores anteriores de AppColorField. Conservar color/vista previa/código
sincronizados, validación, accesibilidad y confirmación explícita, sin persistencia
desde el componente. Todas las instancias heredan la nueva biblioteca.

D126 — Cuatro paletas radicalmente distintas; Atlántico intacto (2026-11-02)

El usuario conserva la primera y pide sustituir el resto con direcciones como
Cyberpunk y Cartoon. Nuevas identidades: Cyberpunk amarillo ácido/cian/fucsia,
Cartoon azul eléctrico/rojo/amarillo, Arcade verde neón/uva/naranja y Pop Art
mandarina/violeta/lima, con fondos propios y tonos accesibles para cada modo.
Conservar identificadores persistidos iris/coral/forest/graphite respectivamente
para no reiniciar la selección local. No modificar paletas propias ni fuente/modo.
Nombres y descripciones en AppPaletteCatalog, colores en AppColors.

D127 — Pulsación completa y transiciones compartidas (2026-11-02)

El usuario pide que el toque corto complete el efecto antes de actuar, y más vida
al cambiar de pantalla. AppButton/AppIconButton/AppCard interactiva usan ciclo
de presión/retorno compartido y bloquean repeticiones mientras se ejecuta. Cancelar,
deshabilitar o desmontar no ejecuta el callback pendiente. Movimiento reducido:
sin escala/espera. Deslizamiento horizontal Material, Apple nativo, y editores,
paneles y diálogos mediante AppMotion/AppPageTransitions. No tocar reglas de negocio.
Usar appRoute para páginas Material explícitas del SDK; go_router 18 elegía
NoTransitionPage en esta instalación por su detección de material_ui. Mantener
pageKeys, parámetros, padres y guards, también en el visor aislado.

Evidencia y pendientes D125–D127: COLOR_PICKER_PALETTES_MOTION_2026-11-02.md.

D128 — Efectos por contexto y barra continua, priorizando fluidez (2026-11-02)

Tras comunicar tirones y monotonía, el usuario elige expresamente «Efectos más
marcados» frente a la combinación discreta. Adaptar Material Motion: zoom al
entrar en grupo, fundido/escala entre secciones, subida en formularios y avance
corto en otras rutas. Sustituye el deslizamiento uniforme de D127, sin blur ni
desplazamiento simultáneo de ambas páginas. Pulso completo se acorta a 80 ms por
tramo, rutas Material a 240 ms, barra a 180 ms; no retrasar selección de pestaña.
Una shell mantiene la barra y su indicador fuera de las transiciones de contenido,
también en el visor aislado. No conservar datos/permisos mediante cachés nuevas.
AppReveal usa hijo estable y fundido breve, evitando entradas duplicadas durante
la transición de ruta. Mantener navegación/Atrás/guards/movimiento reducido.
Preparar APK profile para evaluar en móvil; no confundir compilación o test de
widgets con una medición de rendimiento real. Implementación en biblioteca App*.
Referencia, evidencia y pendientes: MOTION_PERFORMANCE_2026-11-02.md.

D129 — Laboratorio temporal antes de elegir animaciones (2026-11-03)

El usuario no está convencido por las animaciones y pide una pantalla de pruebas
con alternativas de rutas y botones; retirarla solo cuando indique qué adoptar.
Elige acceso visible en Inicio, debug/profile, oculto en release. Catálogo App*
aislado en design_system/lab, con códigos para rutas, botones y barras, duración
ajustable y estado efímero; no aplica ni persiste elecciones. No usa datos/SDKs,
no cambia guards y no incorpora la galería general a producción. Mantener tema,
texto ampliado y movimiento reducido. La estética D128 permanece provisional.
Entrar con código vuelve a llevar llave, dejando + en la creación. Este cambio
se conserva aunque luego se retire la pantalla experimental.
Evidencia y lista concreta de retirada: MOTION_LAB_2026-11-03.md.

D130 — Aplicar elecciones y conservar el laboratorio (2026-11-03)

El usuario confirma B07 para principales, B08 secundarios/iconos, B04 si faltan
datos y B05 cuando la acción no esté disponible; N01 para barra, P03 navegación
y P05 formularios. Pide onda de un segundo al entrar al grupo y zoom desde su
tarjeta, y entrada de las secciones por su lado según índice. La geometría es
efímera y no cambia accesos; los botones rechazados no ejecutan acciones. Usar
validación explícita, protección de envíos y movimiento reducido. La dirección
entre pestañas sustituye el estilo uniforme de D128. Decide conservar el
laboratorio por ahora: D129 no autoriza retirarlo automáticamente en esta entrega.
Implementación App*, evidencia y pendientes: SELECTED_MOTION_2026-11-03.md.

D131 — Separar carga/renderizado y transición de secciones (2026-11-03)

El usuario informa de tirones importantes dentro del grupo y pide resolver la
causa, mostrando carga cuando falten datos. Mantener efectos D130; aplazar montar
la feature hasta terminar la entrada propia/exterior, mostrar esqueleto estático
y congelar brevemente una página ya montada durante la salida. SnapshotWidget
permisivo y TickerMode, sin caché persistente ni conservar autoridad por pantalla.
La shell observa acceso fuera del árbol pausado y cambia una clave opaca para
descartar el cuadro por identidad/permisos. Curvas reversas acompasan la salida.
No certificar cero tirones con tests: profile puede habilitar TRACE_GROUP_MOTION
sin datos personales para medir en dispositivo. No sustituye el diagnóstico por
un indicador de red ni altera escrituras, Rules o las copias diarias.
Evidencia y pendientes: GROUP_NAVIGATION_PERFORMANCE_2026-11-03.md.
