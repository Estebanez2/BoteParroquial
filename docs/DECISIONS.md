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

Decisiones todavía pendientes

Aprobación visual del rediseño v0.2 según las referencias del usuario; la apariencia
puede iterarse tras revisar la instalación. No afirmar coincidencia exacta sin revisión.

Política concreta de generación de exportaciones grandes.

Momento exacto en que introducir Cloud Functions.

Estrategia definitiva para agregados de estadísticas.

Caché y confirmación económica del MVP decididas en D046; reevaluar la política
si una fase futura introduce escrituras económicas offline.

Reglas exactas para una futura baja completa de cuenta de usuario.

Añadir nuevas decisiones con ID y motivo.

No eliminar decisiones anteriores sin dejar constancia del cambio.
