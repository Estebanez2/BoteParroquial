Arquitectura

Ampliación autorizada para fotos (2026-10-15): Supabase Storage como proveedor de
archivos; Firebase Authentication y Firestore conservan su responsabilidad.
El flujo obligatorio se aplica también a Supabase: UI → Provider → Repository →
Service → SDK externo. Conexión diferida en core/supabase y services; no exponer
SupabaseClient en widgets o modelos. Autorización mediante Edge Function que
verifica JWT Firebase y consulta Firestore REST con el token del usuario. Roles
no duplicados; Storage privado solo accesible por backend autorizado. Función
desplegada y UI integrada: photos/providers → PhotoRepository → servicios de SDK
y selección/preparación de imagen. Modelos PhotoTarget/PhotoAccess independientes.
PhotoRepository coordina caché acotada y privada por cuenta (memoria/disco temporal)
y lecturas condicionales; widgets consumen photoPresentationProvider. Las imágenes
se conservan durante revalidación y se purgan por sesión/acceso. AppImageCropper
encapsula el SDK visual nativo; no aparece su API en las features. Ningún campo nuevo
en Firestore: una ruta privada por destino en Storage. Ver docs/SUPABASE_SETUP.md.
Editar la imagen guardada sigue Controller → Repository → PhotoPickerService.edit;
el servicio prepara un archivo temporal privado para el mismo editor nativo.
AppDelayedVisibility controla únicamente el tiempo de presentación de avisos;
no transforma estados de conectividad ni autoriza operaciones económicas.

Dirección de dependencias

UI
↓
Provider
↓
Repository
↓
Service
↓
Firebase

Presentation / UI

Responsabilidad:

mostrar información;

recibir interacción;

mostrar carga y errores;

llamar acciones de providers.

No puede:

consultar Firestore;

utilizar FirebaseAuth directamente;

calcular reglas financieras;

decidir permisos.

Ubicación:

lib/features/*/presentation/

Providers

Utilizar Riverpod.

Responsabilidad:

estado de la feature;

coordinación de operaciones;

exposición de datos a UI;

estados loading/data/error.

Ubicación:

lib/features/*/providers/

Los providers utilizan repositories.

No construyen consultas Firestore directamente.

Repositories

Responsabilidad:

operaciones del dominio;

coordinación entre uno o varios services;

reglas del caso de uso;

devolver modelos de dominio.

Ubicación:

lib/repositories/

Ejemplos futuros:

AuthRepository
GroupRepository
PersonRepository
MovementRepository

Services

Responsabilidad:

encapsular SDK externos;

Firebase Authentication;

Google Sign-In;

Firestore;

serialización técnica;

traducción inicial de errores externos.

Ubicación:

lib/services/

Firebase no debe propagarse hacia UI.

Tipos como:

DocumentSnapshot
Timestamp
FirebaseAuthException
User

no deberían formar parte de los contratos de UI.

Models

Ubicación:

lib/models/

Representan conceptos de dominio.

Ejemplos:

AppUser
Group
GroupMember
Person
Movement

No dependen de widgets ni de Firebase.

Estructura objetivo

lib/
├── main.dart
├── app.dart
├── firebase_options.dart
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── routing/
│   ├── theme/
│   └── utils/
│
├── models/
│
├── services/
│
├── repositories/
│
├── features/
│   ├── auth/
│   │   ├── presentation/
│   │   └── providers/
│   │
│   ├── home/
│   │   ├── presentation/
│   │   └── providers/
│   │
│   ├── groups/
│   │   ├── presentation/
│   │   └── providers/
│   │
│   ├── persons/
│   │   ├── presentation/
│   │   └── providers/
│   │
│   └── movements/
│       ├── presentation/
│       └── providers/
│
└── shared/
    ├── widgets/
    └── providers/

No crear carpetas ni archivos vacíos únicamente para imitar esta estructura.

Crear cada zona cuando tenga una implementación real.

Grupos

Todas las operaciones de datos pertenecientes a un grupo reciben:

groupId

explícitamente.

No utilizar un singleton global como identidad persistente del grupo.

La UI puede mantener un grupo seleccionado, pero su ID debe pasarse a las operaciones correspondientes.

Migración desde código existente

El proyecto puede contener código anterior que todavía combine Service y Repository.

No extender ese patrón.

Cuando una feature existente se modifique de forma sustancial:

separar adaptación Firebase;

colocarla en Service;

dejar Repository como dominio;

actualizar providers;

mantener los cambios limitados a la feature afectada.

No realizar una migración total en una tarea no relacionada.

Arquitectura visual

Flutter / Material / librería externa → Design System → componentes App* → features.

La presentación utiliza la API pública lib/design_system/design_system.dart.
Tokens de color, tipografía, spacing, radio, sombras y movimiento se centralizan
en lib/design_system/theme/. Esta carpeta sustituye la ubicación prevista
core/theme/ para los tokens visuales; no mantener dos fuentes de estilos.
Componentes reutilizables en design_system/components/. Componentes específicos
como PersonListTile se crearán en su feature componiendo esos componentes.

La galería vive en design_system/showcase/ y tiene entrypoint debug independiente
lib/main_showcase.dart, sin Firebase ni rutas de producción. Los valores que muestra
son ejemplos de presentación y no implementan Groups, Persons, Movements o Dashboard.

Ver DESIGN_SYSTEM.md para APIs, reglas de uso y evaluación de dependencias.
En Phase 2 se conecta AppTheme a la app por petición del usuario; home y grupos
usan App*. Login mantuvo su composición anterior en aquella fase; el rediseño
posterior v0.2 lo migra también a App*.

Groups & Membership

Modelos Group y GroupMember en models; GroupRepository usa GroupService y su
adaptador FirestoreGroupService. La consulta de membresías propias filtra uid
en collectionGroup('members'); las lecturas de grupo/miembros reciben groupId.
El contexto del grupo es el parámetro de ruta /groups/:groupId, sin singleton
ni ID de grupo hardcodeado. Los providers vuelven a comprobar membresía al cambiar
sesión o acceso. La UI no muestra los datos anteriores durante carga o error.
Las reglas son la autoridad de permisos; el guard de UI solo mejora la navegación.
Las escrituras cliente de grupos/membresías siguen cerradas hasta Phase 7.

Personas (Phase 3)

PersonsSection y PersonEditor → providers de Personas → PersonRepository →
PersonService/FirestorePersonService → Firestore. Person es un modelo de dominio.
Cada operación recibe groupId explícito; el repository rechaza personas de otro
grupo y valida/normaliza los campos. Los providers coordinan sesión, permisos y
envíos, y la UI consume esa información. Rules vuelven a comprobar los permisos.
Las actualizaciones usan transacciones y la versión updatedAt leída; un conflicto
pide reabrir el panel. No hay API de borrado. El listado escucha cambios remotos.

Movimientos (Phase 4)

Historial y pantallas completas de registro/corrección/anulación → providers de
Movements → MovementRepository → MovementService/FirestoreMovementService → Firebase.
Movement/MovementInput son modelos independientes del SDK. Toda operación recibe
groupId. La UI no calcula saldo ni decide reglas financieras: el repository valida
y prepara revisiones; providers coordinan permisos y acciones; la UI confirma avisos.
El ID se asigna una vez por formulario. Save/cancel usan transacciones con comprobación
de versión y reintentos idempotentes del mismo envío. Las reglas getAfter validan la
corrección atómica y sus enlaces; no se actualiza un saldo mutable ni se borran registros.
Desde Phase 5 el saldo también se muestra en el Dashboard, siempre derivado.

Dashboard (Phase 5)

DashboardScreen → dashboardProvider → DashboardRepository.summarize → DashboardSummary.
El provider coordina los flujos existentes de Movements y Persons, que ya siguen
Repository → Service → Firebase. No se crea un service vacío ni otro acceso paralelo
a Firestore. El repository de Dashboard es una proyección pura, sin Flutter/Firebase:
totales, conteos, actividad, orden y deduplicación están fuera de los widgets.

La UI solo presenta DashboardSummary y usa los providers de permisos para acciones.
Cambiar su composición no cambia el cálculo ni las operaciones de Personas/Movements.
El inicio del grupo es el Dashboard; personas y miembros tienen rutas independientes.
GroupAccessBody concentra el guard visual compartido, sin sustituir Security Rules.
Los listeners de personas/movimientos se seleccionan sin Ref después de await ni
dentro de un generador diferido; esto evita accesos a providers ya cerrados.

Decisión explícita del usuario para el MVP: reutilizar los datos actuales completos.
No se escribe ningún saldo ni agregado. Con más volumen se sustituirá esta fuente
por consultas/resúmenes acotados manteniendo el contrato del Dashboard; la prohibición
de leer todo el historial de la especificación completa sigue siendo el objetivo
de escalabilidad, no algo ya resuelto por esta fase.

Robustez del MVP (Phase 6)

MovementController → MovementSubmissionRepository → PendingMovementService /
FilePendingMovementService y MovementRepository → MovementService → Firebase.
PendingMovement es dominio puro. La persistencia técnica de JSON/archivos y
path_provider queda en Service; la intención se escribe y cierra antes de enviar.
Archivo temporal y rename, operaciones serializadas y limpieza condicionada al ID
evitan sobrescribir o borrar otro pendiente. El repository bloquea un envío distinto
mientras exista uno pendiente y comprueba el resultado contra lecturas de servidor.
La recuperación requiere confirmación antes de repetir; ninguna apertura reenvía dinero.

GroupSyncNotice → groupServerConfirmedProvider → GroupSyncRepository →
FirestoreGroupSyncService. Metadata de grupo, membresía propia, personas, miembros
y movimientos distingue datos confirmados y caché. Los listeners de las mismas
consultas son compartidos por el SDK; la membresía propia añade una lectura de
documento. El aviso es conservador: todas las fuentes deben estar confirmadas.
No sustituye a Rules ni afirma disponibilidad de Internet. Una lectura previa
confirmada no reserva permisos o saldo para la siguiente escritura.

MovementController → GroupCalendarRepository → GroupClockService /
TimeZoneGroupClockService adapta timezone/IANA y devuelve un día civil. Widgets
usan today() del controller para selector e inicio; validación y envío usan la
misma referencia del grupo. El modelo no importa timezone ni fija Europe/Madrid.
La hora de dispositivo puede estar mal: este cambio no sincroniza su reloj.

El descarte local requiere confirmación y una lectura de servidor; nunca escribe
movimientos. No equivale a cancelar una solicitud que siguiera en curso.

Home muestra la lista de grupos independientemente de actualizar el perfil; esto
permite consultar caché con sesión existente sin completar esa escritura online.

Rediseño visual v0.2 (2026-10-15)

AppGradients centraliza fondos, superficies, paneles y botones. AppHeroPanel,
AppCover, AppNavigationTile, AppAdaptiveRow, AppChoiceBar, AppExpandableRow,
AppAvatarMenu y AppActionMenu amplían la API común. Widgets de features componen
estas piezas; no contienen consultas Firebase ni cálculos de saldo.
GroupIdentityHeader comparte la identidad de grupo en las pantallas existentes.
PersonEditor abre una pantalla completa con transición que respeta movimiento
reducido. Login migra a App* sin cambiar AuthRepository ni el acceso Google.

El historial consume movementDaysProvider → MovementHistoryRepository.groupByDay,
una proyección pura por fecha efectiva que conserva todos los estados y el groupId.
Detalles, correcciones y anulaciones siguen accesibles al desplegar cada fila;
los enlaces de actividad abren el movimiento concreto ya desplegado.
Las tarjetas de inicio reutilizan dashboardProvider para el saldo de cada grupo:
el MVP lee los flujos completos también allí; no son agregados ni ceros ficticios.

Las fotos se aplazan explícitamente. AppAvatar/AppCover pueden recibir ImageProvider,
pero no se implementan almacenamiento, subida ni permisos de imagen en esta tarea.
No se sustituyen el aislamiento por grupo ni Rules por opciones visuales.
