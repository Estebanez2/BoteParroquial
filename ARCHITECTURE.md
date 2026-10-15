Arquitectura

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
usan App*. Login mantiene su composición anterior con el tema común.

Groups & Membership

Modelos Group y GroupMember en models; GroupRepository usa GroupService y su
adaptador FirestoreGroupService. La consulta de membresías propias filtra uid
en collectionGroup('members'); las lecturas de grupo/miembros reciben groupId.
El contexto del grupo es el parámetro de ruta /groups/:groupId, sin singleton
ni ID de grupo hardcodeado. Los providers vuelven a comprobar membresía al cambiar
sesión o acceso. La UI no muestra los datos anteriores durante carga o error.
Las reglas son la autoridad de permisos; el guard de UI solo mejora la navegación.
Las escrituras cliente de grupos/membresías siguen cerradas hasta Phase 7.
