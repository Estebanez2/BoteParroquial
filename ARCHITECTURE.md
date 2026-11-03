Arquitectura

Ingreso y cuota inicial, D132 (2026-11-03)

MovementEditorForm abre InitialQuotaPicker; AllocationController coordina la
revisión pura de InitialQuotaRepository (etapa, importe, sobrepago). La selección
es InitialQuotaAssignment, sin Firebase/Flutter. MovementController y
MovementSubmissionRepository conservan el plan en PendingMovement/journal v3.
MovementRepository usa la capacidad InitialQuotaMovementService para el commit
único; FirestoreInitialQuotaMutation prepara lecturas y escrituras junto al alta
económica. No encadenar dos llamadas de guardar ni esconder un fallo parcial.
La recuperación relee ingreso y testigo inmutable de reparto antes de limpiar
el journal. La elección solo aplica al alta; correcciones conservan revisión
posterior, devoluciones su plan específico. Sin campos nuevos en movements.

Renderizado de navegación, 2026-11-03 (D131)

appRoute entrega un builder diferido a AppDeferredSection para las secciones.
El componente no consulta providers/Firebase: espera al fin del movimiento y
presenta un esqueleto compartido mientras tanto. GroupNavigationShell observa
identidad, membresía y disponibilidad del grupo fuera del árbol pausado; publica
en AppSectionRenderScope una clave opaca y autorización de congelación visual.
Cambios de acceso invalidan el cuadro temporal inmediatamente. SnapshotWidget
es una imagen efímera de GPU, nunca respaldo ni almacenamiento entre cuentas.
TickerMode pausa animaciones y suscripciones Consumer durante ese intervalo.
El router de copias usa el mismo mecanismo dentro de su contenedor sin SDKs.
GroupMotionMetrics solo diagnostica en profile con TRACE_GROUP_MOTION=true;
registra índices/tiempos y no identificadores ni contenido del usuario.

Selección integrada de movimiento, 2026-11-03 (D130)

Las features declaran intentos y validadores UI en AppButton; AppControlFeedback
anima/rechaza sin calcular dominio. Los controllers conservan validación económica,
roles y escritura. JoinGroupController reutiliza parse del repositorio para un
rechazo local de formato, sin consulta remota ni nueva regla de invitaciones.
AppGroupEntry pasa AppGroupOrigin efímero a AppMotionPage; GroupNavigationShell
publica orden de secciones en AppSectionMotionScope para las rutas entrantes y
salientes. Nada se guarda o mezcla con providers de permisos. AppBottomSheet usa
modalContextOf del host actual para cubrir la barra permaneciendo dentro del
router/ProviderContainer propio del visor. Laboratorio conservado por petición
expresa. Evidencia: docs/SELECTED_MOTION_2026-11-03.md.

Laboratorio temporal de presentación, 2026-11-03 (D129)

Home enlaza a la ruta autenticada de pruebas solo en debug/profile. Los
renderizadores y el Navigator local viven en design_system/lab, sin SDKs ni
providers/repositorios del dominio. Su estado local es exclusivamente visual
(categoría, duración y códigos probados), no una preferencia del producto.
La galería general no se incorpora al router. Al elegir, trasladar únicamente
los efectos aprobados a App* y retirar el laboratorio según su informe:
docs/MOTION_LAB_2026-11-03.md. AppFloatingActions admite iconos explícitos por
opción; no deduce el significado de textos ni conoce las acciones de negocio.

Movimiento por contexto y barra persistente, 2026-11-02 (D128)

appRoute crea AppMotionPage (MaterialPage SDK) con intención visual explícita.
La shell de grupo crea su página Material y conserva AppNavigationHost fuera del
Navigator de secciones. GroupBottomNavigation sigue comprobando membresía en sus
providers; las pantallas y guards existentes no se sustituyen por estado visual.
El router del visor compone la misma shell dentro de su contenedor aislado.
Los editores manuales de personas/fotos se abren en el Navigator raíz para cubrir
la barra durante la edición y conservar el guardia de cambios sin guardar.
La biblioteca define transiciones y suprime slots inferiores duplicados; no
consulta SDKs ni guarda datos. No hay nueva caché ni precarga de historia para
animar. Estado/evidencia: docs/MOTION_PERFORMANCE_2026-11-02.md.

Continuación de movimiento/color, 2026-11-02

appRoute (core/routing) crea MaterialPage SDK con pageKey/parámetros/padres
conservados. Evita NoTransitionPage por la detección material_ui de go_router 18
sin cambiar dependencias. Router principal y del visor comparten adaptación;
AppTheme/AppPageTransitions poseen estilo/tiempo, no los archivos de features.
El contenedor de copia sigue independiente, con SDKs/operaciones bloqueados.

AppPressFeedback ejecuta el callback vigente después de presión/retorno y lo
cancela al desmontar/deshabilitar; con movimiento reducido es inmediato. Las
validaciones de actor, permiso y envío siguen en providers/repositories. ColorPlane
y HueSlider solo editan borrador visual y sincronizan AppColorField/hex; guardado
y preferencias conservan la cadena existente. Identificadores de paleta estables,
nombres/colores centralizados. Evidencia: docs/COLOR_PICKER_PALETTES_MOTION_2026-11-02.md.

Biblioteca y apariencia local, continuación del 2026-11-02

AppearanceScreen/CustomPaletteEditor → AppearanceController →
AppearanceRepository → FileAppearanceService. AppearanceSettings v2 añade AppFont,
CustomPalette (RGB entero sin Flutter) y selección local. Lee versiones anteriores,
conserva IDs al editar y fuente/modo al borrar una paleta. Nada se escribe a Firebase.
AppTheme deriva superficies/contraste y AppTypography propaga letra; el visor
recibe ThemeData sin enlazar su ProviderContainer al de producción.

AppSkeleton/AppShimmer, AppMenuRow, AppColorField y AppThemePreview son presentación
compartida sin proveedores de datos ni permisos. Features solo eligen variantes
y callbacks. Home declara acciones flotantes en AppScaffold. La carga no confirma
datos ni oculta errores/autorización. Evidencia: docs/VISUAL_LIBRARY_2026-11-02.md.

Ampliación 2026-11-02

Primeros meses: panel/pantalla → first_month_setup_providers →
ParticipationRepository → ParticipationService/Firestore existente. Candidatos
desde personas/periodos compartidos por grupo; selección y mes explícitos.
Una transacción auditada por persona, con revisión de actor/permisos entre ellas;
resultado parcial explícito, sin atomicidad global ni sobrescritura de etapas.
AppFormGuard solo protege la presentación, no guarda ni calcula reglas.

Notificaciones iniciales: PushDeviceController → PushDeviceRepository →
PushConsentService/FilePushConsentService y adaptadores nativos/Firestore ya
existentes. Primera entrada autenticada solicita permiso una vez por UID/móvil;
booleano local sin tokens. Journal privado y retirada confirmada se conservan.
Paletas se amplían en tokens centrales, manteniendo persistencia existente.
Recorte por destino viaja por provider → repository → picker service → cropper.
Sin nuevo acceso directo a SDK desde widgets. Evidencia:
docs/UX_IMPROVEMENTS_2026-11-02.md.

Apariencia y navegación v0.4 (2026-10-30)

Ajustes de apariencia → AppearanceController → AppearanceRepository →
AppearanceService/FileAppearanceService → archivo local en application support.
AppearanceSettings, AppPalette y AppearanceMode son Dart puro. Preferencia por
instalación/móvil, independiente de UID y sin Firestore ni nuevos SDKs. Escrituras
serializadas con temporal/rename; lectura ausente/corrupta usa valores iniciales.
La UI aplica la selección al momento, anuncia error de guardado y permite reintentar.
Una carga antigua no puede sobrescribir una selección posterior.

BoteParroquialApp observa el estado y compone ambos ThemeData desde AppTheme.
El router no se reconstruye al cambiar apariencia. SnapshotBrowser pasa ThemeData
al visor; no enlaza su ProviderContainer aislado al vivo ni habilita SDKs allí.

Las rutas principales se anidan bajo Inicio → resumen del grupo → sección. Así
Atrás tiene páginas reales que recuperar tras context.go y en entrada directa a
una sección. ParticipantsScreen abre Personas/Miembros mediante push; conservan
sus guards y providers. MovementActions comparte presentación y callbacks de las
dos acciones económicas, manteniendo permisos en sus providers existentes.
Portada panorámica adapta PhotoCover/AppCover, sin cambiar permisos o binarios.
Evidencia: docs/VISUAL_REDESIGN_V04_VALIDATION.md.

Copias diarias locales (2026-10-23)

App/lifecycle → DailyCopyController → DailySnapshotRepository →
FirestoreSnapshotService/SnapshotRestTransport (solo JWT del usuario) y
FileSnapshotStorage (AES-GCM + almacenamiento seguro de clave del dispositivo).
Se comprueban accesos antes/después y se capturan consultas paginadas bajo el mismo
readTime. No usar caché como descarga completa ni claves privilegiadas. JSON/cifrado
en isolate; I/O serializada y publicación tras relectura autenticada. Podar a siete
capturas satisfactorias después de guardar; conservar anteriores ante fallos.

DailyCopiesScreen → controller → repositorio/archivo privado. SnapshotBrowserScreen
abre un ProviderContainer independiente, nunca hijo del contenedor en vivo.
SnapshotDataRepository decodifica modelos puros; SnapshotMovementService y
SnapshotQuotaService alimentan los providers/cálculos existentes. SDKs bloqueados,
adaptador económico rechaza escrituras, edición no enrutada y permisos de gestión
desactivados. No montar el pipeline de avisos ni el journal de movimientos dentro
del visor. Calendario de grupo y selección de informes usan el instante copiado.

Copias solo de ámbitos autorizados de la cuenta y fotos según caché existente;
sin dispositivos/tokens/estado privado del worker. Al confirmar pérdida/cambio de
acceso se retira el grupo de archivos y vista; sin red la revocación es desconocida.
Cerrar sesión invalida descargas tardías y limpia ese UID. La clave no va en JSON,
Git o Flutter config. No se instala un cron ni se reactiva la copia semanal aplazada.
Evidencia: docs/DAILY_OFFLINE_COPIES_VALIDATION.md.

Consulta de auditoría, 2026-10-20: GroupAuditScreen/controles/detalle →
audit_history_providers → AuditHistoryRepository → AuditHistoryService →
FirestoreAuditHistoryService. Modelo separado de GroupInput; crear/editar grupos
ya no incorpora el contrato de lectura de auditoría. Sin alterar escrituras.
Cursor de timestamp completo e ID, ligado al grupo. Cabecera reactiva hasta
paginar; después conserva frontera y anuncia novedades para actualizar. Filtros
solo sobre cargados. Estado y respuestas pendientes aislados por UID/acceso;
detalle abierto no conserva valores al revocar. Evidencia y límites:
docs/PHASE11_AUDIT_HISTORY_VALIDATION.md.

Comparaciones de informes, 2026-10-20: UI → reportComparisonProvider →
ReportComparisonRepository → repositorios económicos/cuotas puros sobre los datos
ya compartidos por servicios/providers. Sin consultas adicionales ni persistencia.
Cortes civiles desde el calendario del grupo; dinero en enteros y ratios BigInt.
El bloque desplegable solo monta el consumidor al abrirse. Dominio de pagos y
devoluciones reutilizado; widgets presentan valores/fechas, sin recalcular reglas.
Ver docs/PHASE10_PERIOD_COMPARISONS_VALIDATION.md y D103.

Servidor vigente 2026-10-20: cron → endpoint autenticado → dominio de cuotas o
actividad → adaptador REST de Firestore → bandeja/reserva → FCM. Recalcula desde
datos y permisos actuales; Flutter no autoriza destinatarios ni envíos. Lectura de
cuotas coherente y escritura condicional limitada en código a avisos, entregas,
cuarentena y estado técnico. IAM tiene mayor alcance por limitaciones de Firestore;
la identidad dedicada y sus secretos están exclusivamente en un segundo Supabase,
qngrmxfjckrrfiyioyzl, separado de photo-access. Sin claves de servidor en cliente.
El router preserva solo códigos válidos del host HTTPS acordado durante login.
Despliegue, reservas, límites y validación real:
[informe](docs/PHASE9_NOTIFICATIONS_AND_LINKS_VALIDATION.md).
Las preparaciones descritas a continuación son históricas; ahora hay worker/cron.

Preparación de servidor de recordatorios (2026-10-20): módulos Deno privados
`_shared/quota_reminders.ts` (dominio puro) y `reminder_reader.ts` (adaptador REST
de solo lectura). El lector obtiene un snapshot readOnly coherente por grupo;
el dominio proyecta cuotas actuales y resuelve candidatos/destinatarios sin SDK.
Fixtures compartidos contrastan ese resultado con los informes reales de Dart.
Sin endpoint, envío, credenciales, persistencia de reservas o cron todavía.
No se incorporan a photo-access. El futuro worker debe releer permisos/datos antes
de entregar y no aceptar destinatarios/importes enviados por el cliente.
Ver docs/PHASE9_REMINDER_SERVER_CALCULATION.md.

Cliente de notificaciones (2026-10-19): perfil/bandeja → providers →
PushDeviceRepository o NotificationRepository → FirebasePushMessagingService /
FirestoreNotificationService / FilePushRegistrationService. El token de entrega
no aparece en widgets o modelos de UI. El journal privado solo guarda UID,
huellas e intención; se escribe antes de registrar/retirar y permite resolver
resultados inciertos. Cola por repositorio serializa alta, refresh y retirada.
AuthRepository coordina retirada antes del SDK de logout, sin dependencia de
widgets. Sin registro no invoca Messaging para cerrar sesión.

La app mantiene la restauración consentida y las escuchas de token/tap. Las
aperturas solo aceptan groupId/recipientUid, nunca una ruta arbitraria; verifican
la cuenta actual y membresía, y la pantalla vuelve a aplicar GroupAccessBody.
Los providers retiran avisos al perder cuenta/grupo. La bandeja consulta solo el
UID propio y los últimos 50 por createdAt; marcar leído usa transacción online,
sin alterar el contenido. Preferencias solo de la membresía propia. La generación
pertenece al futuro servidor; el cliente no crea avisos ni calcula sus destinatarios.
Ver docs/PHASE9_NOTIFICATION_CLIENT_VALIDATION.md para despliegue y límites.

Preparación de notificaciones (2026-10-19): QuotaReminderRepository consume un
QuotaReport mensual actual ya calculado y devuelve únicamente candidatos de
obligación, sin resolver destinatarios ni enviar. Modelos puros; exige groupId,
calendario civil del grupo e informe del mismo mes/grupo. No crea providers,
pantallas o servicios vacíos. No está conectado a un flujo visible todavía.
El futuro servidor debe recalcular y autorizar con datos actuales; una proyección
del cliente nunca es una orden de envío ni prueba de permisos. El cálculo Dart
no se ejecuta automáticamente en Supabase: faltan su adaptación y validación allí.

supabase/functions/_shared/fcm.ts es un adaptador de servidor sin endpoint público.
Intercambia una credencial de servicio por OAuth de alcance firebase.messaging y
encapsula FCM HTTP v1. El constructor recibe el secreto, no lo lee del cliente;
no existe aún ninguna clave configurada. Valida por defecto, no reintenta envíos
inciertos y no registra tokens ni cuerpos técnicos. No integra ni modifica la
función photo-access, que sigue usando exclusivamente el JWT del usuario.
Supabase + FCM y 10:00 elegidos en D091. Sin trabajador, cron ni despliegue aún;
estado exacto: docs/PHASE9_NOTIFICATIONS_FOUNDATION.md.

Avance del producto completo (2026-10-17):

- GroupEditor → GroupManagementController → GroupManagementRepository →
  FirestoreGroupManagementService. Separado de las lecturas de GroupRepository,
  sin ampliar artificialmente sus dobles de pruebas. Transacciones online para
  creación/edición y auditoría getAfter. El ID de creación se conserva por formulario.
- Informes/ficha → providers → EconomicReportRepository puro → flujos existentes
  de Movements/Persons. ReportSelection determina periodos civiles; los widgets
  reciben saldos y series ya calculados. No se añade saldo persistido ni agregados.
- Perfil → ProfileEditorController → ProfileEditorRepository →
  FirestoreProfileEditorService. Control de UID/versión; Auth conserva nombre propio.
- CSV → CsvExportController → CsvExportRepository → NativeFileSharingService →
  share_plus/path_provider. La consulta de movimientos de servidor sigue pasando
  por MovementRepository/Service. Formato y permisos de generación fuera de la UI.
  Directorios temporales propios por hash de UID, hasta 10 envíos recientes con
  limpieza por edad al compartir y purga propia al cambiar de cuenta. El SDK
  puede mantener su caché de compartición; no se promete revocar copias exportadas.

Estas ampliaciones no implementan roles editables ni cuotas. Las invitaciones
se añaden en la entrega posterior descrita al final de este documento.

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
En el avance parcial de Phase 7, GroupManagementRepository y su Service separado
permiten crear grupo/membresía owner inicial/persona opcional/auditoría de forma
atómica y editar nombre/descripción con auditoría. No se abre gestión general
de roles. Entradas/bajas de membresías se añaden en el bloque posterior.
Rules valida el conjunto con getAfter.

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

Decisión histórica del MVP: reutilizar los datos completos sin persistir saldos.
D109 sustituye esa fuente de caja por sumas agregadas y actividad acotada;
el contrato puro y la prohibición de calcular negocio en UI se conservan.
La proyección de cuotas aún necesita sus ingresos/devoluciones, periodos y repartos.

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
en aquel MVP leían los flujos completos. Desde D109 reciben caja agregada,
actividad acotada y personas, sin convertir una falta de datos en cero.

Ampliación del historial (2026-10-17): MovementHistoryControls envía criterios a
MovementFilterController mediante Riverpod. movementHistoryProvider combina esos
criterios con el stream existente y las etiquetas de Personas/Miembros, y delega
búsqueda, validación de rango, orden e aislamiento a MovementHistoryRepository.
MovementHistoryFilter/MovementHistoryOptions son modelos puros sin Flutter/Firebase.
El formulario mantiene solo un borrador visual hasta Aplicar. La búsqueda/filtros
no tocan movementsProvider, operaciones financieras, Dashboard ni persistencia.
La vista focus por ID omite los criterios; agrupación por día continúa en repository.
Los filtros se eliminan al salir del historial, cambiar cuenta o perder membresía.

El aplazamiento inicial de fotos es histórico: se implementaron con Supabase y
wrappers de providers descritos al inicio y en docs/SUPABASE_SETUP.md.
No se sustituyen el aislamiento por grupo ni Rules por opciones visuales.

Invitaciones y accesos (Phase 7 parcial, 2026-10-17)

GroupInvitationsScreen / JoinGroupScreen / acciones de GroupMembersScreen →
providers de invitación → GroupInvitationRepository → GroupInvitationService →
FirestoreGroupInvitationService → Firebase. Códigos, ajustes, preview y solicitudes
son modelos puros. Clipboard/compartición de texto pasan por FileSharingService,
cuya implementación nativa encapsula Flutter/SharePlus.

Providers coordinan autenticación, permisos y acciones, bloquean doble envío y
descartan respuestas de entrada de otra sesión. Repository valida formato,
aislamiento y owner protegido. Service hace lecturas de servidor y transacciones
con control de versión. Rules exige el conjunto coherente y auditoría en el mismo
commit. Guard visual no sustituye autorización. No se crean perfiles globales
legibles ni un índice global de grupos o permisos.

La auditoría conserva compatibilidad con eventos group sin entityType. El modelo
admite payloads planos de string/bool/null para invitaciones, solicitudes y bajas.
No es todavía auditoría general de todas las entidades.
La readmisión posterior sigue el mismo flujo: preview consulta membresía propia
en servidor con UID explícito y comunica aprobación obligatoria; submit vuelve
a comprobarla, decide reactiva la misma membresía solo por gestión autorizada.
Conserva personId/joinedAt y fija rol member. No se habilitan roles generales ni
transferencia. Contrato de datos y límites: FIREBASE_SCHEMA.md,
docs/PHASE7_INVITATIONS_VALIDATION.md y docs/PHASE7_READMISSION_VALIDATION.md.

Vinculación de cuentas/personas (2026-10-18)

MemberLinkButton/Editor → providers de vínculos → MemberLinkRepository →
MemberLinkService/FirestoreMemberLinkService → Firebase. Providers filtran
ocupación, pendientes y permisos; el formulario conserva solo su borrador.
Repository valida grupo, reserva, propietario y alcance. Service comprueba
versiones y actualiza membresía, persona anterior/nueva y auditoría en transacción.
Rules exige ambas direcciones y rechaza reclamaciones dobles. Person.linkedUid
es dominio puro opcional, no otra cuenta autenticada global.

FirestorePersonService inactiva la persona y, cuando corresponde, degrada su admin
vinculado con auditoría en el mismo commit. Sin Functions/Scheduler, traslado de
dinero ni sincronización de imágenes. La preparación de vínculos anteriores es
una herramienta operativa separada, auditada y con precondiciones; no se ejecuta
como reparación silenciosa al leer. Esa entrega no implementó promociones ni transferencia.
Ver docs/PHASE7_LINKS_VALIDATION.md.

Roles y transferencia (entrega posterior, 2026-10-18)

MemberRoleButton / OwnershipTransferScreen → providers de roles →
MemberRoleRepository → MemberRoleService / FirestoreMemberRoleService → Firebase.
El repository puro determina requisitos de persona/rol y valida la confirmación;
los providers exponen candidatos/permisos y coordinan la reautenticación mediante
AuthRepository → AuthService → FirebaseAuthService. Los widgets solo conservan
selección y texto del formulario. No contienen transacciones ni SDK de Google.

FirebaseAuthService usa reauthenticateWithCredential sobre el usuario existente,
comprueba UID y renueva el token. Cancelación, cuenta incorrecta o cambio de sesión
interrumpen el envío. El provider vuelve a comprobar versiones y permisos después
del await; Service lee grupo, ambas membresías y persona antes de escribir.
Rules es la autoridad final: promoción exige vínculo activo recíproco y transferencia
exige Google reciente y ambas transiciones junto a grupo/evento en el mismo commit.
La selección por acción de auditoría evita evaluar rutas de actualización ajenas.
No hay nuevo ownerUid mutable en groups: createdBy es histórico y owner sigue en
members. Tampoco hay un SDK de Firebase en los modelos ni una segunda fuente de roles.
Estado y límites: docs/PHASE7_ROLES_TRANSFER_VALIDATION.md.

Base de cuotas (2026-10-19)

YearMonth representa meses civiles sin convertirlos a instantes del móvil;
QuotaRule y ParticipationPeriod son modelos inmutables sin SDK. Repository puro
QuotaExpectationRepository valida ámbito grupo/persona y coherencia histórica,
selecciona la regla vigente por mes y proyecta importes esperados en céntimos.
Rechaza reglas con inicio duplicado y solapamientos interiores de periodos. D078
permite compartir solo el mes de frontera y computarlo una vez. Copia las listas antes
de ordenar, no modifica la historia de entrada y devuelve una lista inmutable.

Se diferencia ausencia de periodos, ausencia de precio, mes no computable y mes
con importe conocido. La suma conocida requiere consultar isComplete; no es deuda,
saldo ni un estado de pago. No recibe movimientos ni allocations y no deduce pagos.
Esta entrega no introduce Service/Repository vacíos, providers ni pantallas para
una persistencia pendiente. Es la base comprobable que compondrá esa feature al
resolver las decisiones de aplicación. Ver docs/PHASE8_FOUNDATION_VALIDATION.md.

Integración posterior de cuotas y participación (2026-10-19, Rules publicadas)

QuotaScreen / PersonQuotaSection / ParticipationEditor → providers de quotas →
QuotaRepository / ParticipationRepository → QuotaService / ParticipationService →
adaptadores Firestore. El provider proyecta importes mediante el repository puro;
la UI no calcula obligaciones ni consulta Firebase. AppMonthField es presentación
genérica mes/año y compone AppDropdown, sin modelos ni permisos. intl 0.20.2 pasa
de transitiva a directa, sin cambiar su versión, para nombres de meses locales.

Cada regla mensual tiene una versión vigente y versiones anteriores inmutables.
La sustitución futura y su auditoría se validan juntas. Los periodos conservan
etapas; Person.lastParticipationPeriodId apunta a la última. Empezar, cerrar e
inactivar con degradación de admin cuando corresponda son transacciones online.
FirestorePersonService impide el cambio antiguo de estado si hay un periodo
configurado; esa UI deriva al editor mensual. Editar nombre/notas no toca periodos.
Nuevas personas eligen su primer mes posteriormente desde la ficha; no hay alta
programada futura en este bloque. No se deduce participación de createdAt/isActive.
Rules calcula el mes de servidor para las seis zonas admitidas y rechaza las demás.
No se cambia la validación anterior de fechas efectivas de movimientos.
Estado de publicación y comprobaciones: docs/PHASE8_QUOTAS_PERIODS_VALIDATION.md.

Asignaciones y pagos (continuación de Phase 8)

IncomeAllocationScreen / PersonPaymentSummary → providers de allocations →
AllocationRepository / QuotaSettlementRepository → AllocationService /
FirestoreAllocationService. QuotaSettlementRepository es una proyección pura:
combina periodos, reglas, ingresos y asignaciones; no consulta Firebase ni modifica
listas. La ficha y el editor comparten ese cálculo. Propuestas, capacidad del ingreso,
advertencias por exceso y deuda están fuera de widgets. Separa pagos hasta el mes
actual, futuros y crédito sin asignar. Un sobrepago no compensa otro mes automáticamente.

Cada ajuste mensual guarda un total absoluto ingreso/mes, con revisión y un ID
de operación estable durante el envío. Transacción online: lee el movimiento,
asignación, contador del ingreso, etapa y evento previo; escribe asignación,
contador y auditoría juntos. El contador limita la suma, no representa saldo del
bote ni un agregado de cuotas pagadas. No permite dos asignaciones independientes
en un mismo commit usando ese contador. Se comprueban actor, versión y estado.
La respuesta incierta conserva la misma intención/ID en pantalla; reabrir consulta
el estado guardado. No crea otro ingreso ni aplica incrementos repetidos.

Los pagos solo cuentan si el ingreso fuente está active. Anular/corregir invalida
su cómputo sin barrer ni borrar asignaciones; el sustituto no las copia. Esta
primera proyección evita efectos parciales sin ampliar Movement ni su saldo
derivado; la ampliación posterior de devolución añade el plan a MovementInput.
Los ingresos nuevos se registran primero y se reparten expresamente después.
Una retirada ordinaria no revierte asignaciones; las devoluciones se incorporan
en el bloque posterior descrito a continuación.

La confirmación de actualización del grupo también observa cuotas, periodos y
asignaciones; conserva la presentación diferida del aviso. No autoriza escrituras
offline. Sigue la estrategia actual de datos completos por grupo: con volumen
habrá que acotar lecturas y usar agregados, sin trasladar cálculos a la UI.
Estado y comprobaciones: docs/PHASE8_ALLOCATIONS_VALIDATION.md.

Devoluciones y primer mes en alta (2026-10-19)

RefundEditorScreen → refund providers → RefundRepository (disponibilidad/reparto)
y MovementRepository/MovementSubmissionRepository → FirestoreMovementService y
FirestoreRefundMutation → Firestore. El editor conserva campos mientras se
actualiza la fuente; preparar y guardar siempre comprueban los datos actuales.
Actor capturado antes de confirmar, ID estable y journal persistente compartido
con los movimientos. No se incorporan cálculos económicos a widgets.

RefundPlan es dominio puro: ingreso, crédito sin asignar y hasta cuatro partes.
La serialización usa mapa de mes ordinal a céntimos para evitar índices
duplicados. Una corrección restaura el original y aplica el sustituto en una
transacción; no cambia el ingreso de origen y la unión de meses es como máximo
cuatro. Para otro ingreso o más meses, anular y registrar otra devolución.

Las asignaciones conservan sus importes brutos. QuotaSettlementRepository resta
las partes de devoluciones active al pago por mes y el crédito devuelto al
dinero libre. El contador por ingreso registra límites de devoluciones, incluidos
los retornos por mes; nunca es el saldo del bote. Un ajuste de reparto no puede
bajar de lo ya devuelto ni volver a repartir dinero retornado. No anular/corregir
el ingreso mientras haya devoluciones activas. Rules enlaza movimiento, contador
y evento inmutable, con validaciones distribuidas entre esas escrituras
obligatorias para cumplir el presupuesto de evaluación. No hay operaciones
parciales ni acceso privilegiado desde la app.

FilePendingMovementService escribe versión 2 cuando hay planes de devolución,
incluido el original de una corrección/anulación; sigue leyendo versión 1.
La recuperación compara el reparto completo, además de importe/fecha/persona.
Una app antigua no debe procesar un journal v2 como una retirada normal.

Alta opcional: PersonRepository valida el primer mes contra el calendario del
grupo; PersonService crea persona, etapa inicial y auditoría atómicamente con ID
estable. Sin mes mantiene la creación sin periodo. Sin cron ni migración.
Estado exacto y límites: docs/PHASE8_REFUNDS_VALIDATION.md.

Dashboard e informes de cuotas (2026-10-19)

QuotaReportSection / DashboardScreen → quota_report_providers →
QuotaReportRepository → GroupQuotaService / FirestoreGroupQuotaService.
Dos streams de contenido del grupo (periodos y allocations), compartidos por
dashboard e informes. Se reutilizan personas, reglas, movimientos y reloj del
grupo. No abrir una consulta por persona, ni leer auditEvents/allocationBalances
para calcular pagos. La ficha individual conserva sus consultas acotadas previas.
Las lecturas respetan la membresía actual; sin acceso devuelven conjuntos vacíos
y GroupAccessBody retira el contenido. El selector de periodo usa un valor inerte
durante la pérdida de acceso para evitar errores de reconstrucción, nunca como
fecha de un informe visible o como sustituto de permisos.

El repository agrupa datos por persona, valida grupo/integridad y compone
QuotaSettlementRepository. Este admite ampliar su intervalo de proyección para
periodos de informe anteriores al primer periodo de participación; su comportamiento
por defecto y las operaciones de asignación/devolución no cambian. No infiere
participación, pagos o deuda a partir de fechas de creación o dinero sin reparto.
Una persona inactiva permanece en el cálculo según sus periodos históricos.

Modelos puros QuotaReport/QuotaTotals separan periodo transcurrido, previsión
futura y acumulado hasta el mes actual. El informe usa el estado actual de los
pagos/devoluciones, no una foto del cierre. Cobertura es la suma de mínimos de
cuota/pago por persona y mes: un exceso no tapa otra obligación. Pendiente y
porcentaje son desconocidos si falta configuración en ese tramo; importe esperado
cero no tiene porcentaje. Ratio entero en puntos básicos, producto intermedio
con BigInt; sumas agregadas comprueban desbordamiento en lugar de mostrar importes
envueltos. No se persisten porcentajes, contadores de informe ni snapshots.

En aquella entrega, el dinero del mes reutilizaba EconomicReportRepository por fecha
efectiva; D109, descrito abajo, lo sustituye en el dashboard por agregados.
No lo equipara al pago de cuotas de ese mes. Crédito sin asignar/futuro
se presenta como estado actual de todo el grupo, no flujo del periodo seleccionado.
App* presenta cifras/estados preparados por providers, sin cálculos financieros
en widgets. Comparaciones se añadieron después en D103 y agregados de caja en D109;
la optimización completa de cuotas para gran volumen sigue abierta.
Evidencia: docs/PHASE10_QUOTA_REPORTS_VALIDATION.md.

Entrega 2026-10-20: exportaciones, ciclo de vida y caja agregada

EconomicReportScreen → export providers → ReportExportRepository →
ReportFileService/NativeReportFileService y NativeFileSharingService. La selección,
roles y scope se autorizan antes de capturar un snapshot inmutable; se vuelven a
comprobar cuenta/permisos antes de compartir. PDF y XLSX se generan en isolate,
con fuentes locales, sin SDK de Firebase en el codificador. CsvExportRepository
prepara el mismo conjunto económico. XLSX es OOXML de escritura, sin fórmulas ni
vínculos externos y con enteros largos preservados como texto; no usa automatización
de Excel ni sube informes a un servidor. No exporta tokens, cuentas o secretos.

PersonTrashScreen/GroupDeletionScreen/AccountDeletionScreen → providers →
repositories de ciclo de vida → services Firebase/Supabase. Las transacciones y
Rules garantizan elegibilidad, auditoría y transiciones. La UI muestra confirmaciones
y progreso, no decide permisos ni integridad. Papelera de diez días solo sin
historial/participación/vínculo y con marcador de protección; purga explícita.
Borrado de grupo con nueva autenticación Google/nombre exacto, bloqueo irreversible,
tarea privada reanudable y limpieza de subcolecciones antes de la raíz. Mantener el
registro de colecciones al ampliar el esquema. Baja propia retira accesos, barrera
de nuevas entradas y segunda consulta antes de limpiar identidad; historia de otros
grupos conservada. Mantener marcadores mínimos ante resultado incierto.

`lifecycle-cleanup`, solo proyecto Supabase de fotos: JWT Firebase del usuario y
Rules actuales, nunca clave Firebase privilegiada. Clave Supabase interna solo para
limpiar prefijos autorizados del bucket privado. Fotos y Firestore no forman una
transacción distribuida: auditoría distingue intención y confirmación. El worker
aislado lee la raíz en su transacción de escritura; no recrea grupos bloqueados.

Dashboard/Home → dashboard providers → MovementRepository → capacidad opcional
MovementDashboardSource de FirestoreMovementService → FirestoreCashAggregateService.
Cuatro sumas REST de caja comparten un readTime, se decodifican como int64 y se
actualizan al cambiar la escucha acotada de movimientos. Los agregados nativos no
tienen escucha/caché propios. FileCashCache mantiene la última confirmación privada
por UID/grupo/mes, la elimina al salir y evita escrituras tardías de la sesión previa;
es temporal, puede desalojarse y no constituye respaldo. UI usa resultados preparados.

Actividad reciente limitada a veinte movimientos y pares necesarios de correcciones;
el resumen muestra cinco cambios. Cuotas comparten fuentes de ingresos/devoluciones,
periodos y asignaciones, sin cargar retiradas ordinarias. La sincronización de snapshots
es del SDK, no una instantánea de cierre de informe. La proyección sigue creciendo con
esos documentos; informes/exportaciones explícitos aún solicitan historial. No afirmar
que todas las pantallas tienen coste constante ni introducir saldos como nueva verdad.

Estado, pruebas y limitaciones: docs/FULL_PRODUCT_COMPLETION_2026-10-20.md.
