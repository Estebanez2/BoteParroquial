Configuración Firebase

Este documento registra configuración real.

No define el esquema de datos.

Para el esquema consultar:

FIREBASE_SCHEMA.md

Proyecto

Firebase project:

boteparroquial

Android Firebase App:

1:146917525912:android:19e9cd4589791d82a103ed

iOS Firebase App:

1:146917525912:ios:1ce7c8765b923fe3a103ed

FlutterFire generó:

lib/firebase_options.dart
firebase.json

Firebase Core utiliza:

DefaultFirebaseOptions.currentPlatform

Android

Package:

com.example.bote_parroquial

Google Sign-In está configurado.

SHA-1 debug:

79:BF:23:AC:79:C1:EF:C7:E1:ED:7A:F0:15:F3:4D:32:26:AE:5B:9E

SHA-256 debug:

FC:0D:85:72:2E:C4:62:C1:CB:D6:8B:8E:0E:66:BB:52:01:0E:61:6D:E3:2A:E5:87:BA:EA:4A:EB:79:59:D9:E7

Estas huellas pertenecen a la firma de desarrollo.

Una versión de publicación necesitará las huellas correspondientes a su propia firma.

iOS

Bundle ID:

com.example.boteParroquial

Info.plist contiene la configuración necesaria de Google Sign-In:

GIDClientID
CFBundleURLTypes

con valores obtenidos de la configuración real de Firebase.

La compilación y prueba iOS requieren Mac con Xcode.

Authentication

Firebase Authentication:

habilitado

Proveedor:

Google

Estado:

configurado

Pendiente:

completar la comprobación con dos cuentas reales y restauración de sesión.
El primer login y el perfil guardado ya se confirmaron en A059P (Android 16).
La segunda cuenta está aplazada por petición del usuario el 2026-10-15 porque no
dispone de otra cuenta actualmente. La restauración tras reinicio con sesión
abierta sigue sin comprobarse. No hay pruebas manuales en curso.
Seguimiento general en docs/ROADMAP.md y detalle en docs/PHASE1_VALIDATION.md.

Firestore

Firestore ha sido creado por el usuario.

Metadatos comprobados mediante Firebase CLI el 2026-10-15:

- Database ID: `(default)`.
- Región: `europe-southwest1` (Madrid).
- Edición: `STANDARD`.
- Tipo: `FIRESTORE_NATIVE`.

Reglas de Phase 1 verificadas inicialmente: el despliegue anterior denegaba todo.
Se publicaron las reglas de firestore.rules el 2026-10-15 tras superar cuatro
pruebas en el emulador local. Release cloud.firestore usa el ruleset
12d5f699-f471-4554-b804-2da6b040ce21.

Solo permiten get/create/update del propio users/{uid}, validan campos y tipos,
exigen timestamps de servidor y conservan createdAt. Se prohíben list/delete,
roles en perfiles y todas las operaciones de grupos/personas/movimientos.
Las reglas de Groups se incorporarán en Phase 2.

No crear otra base simplemente porque estos datos todavía no estén documentados.

No asumir que la configuración de la base garantiza autorización correcta.

CLI

Firebase CLI instalado.

FlutterFire CLI instalado.

Comandos utilizados:

firebase login

dart pub global run flutterfire_cli:flutterfire configure \
  --project=boteparroquial \
  --platforms=android,ios

Servicios todavía no utilizados

No activar salvo que una fase lo necesite:

Cloud Storage
Cloud Functions
Cloud Scheduler
Firebase Cloud Messaging
App Check
Crashlytics
