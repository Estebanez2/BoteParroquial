Configuración Firebase

Este documento registra configuración real.

Publicación vigente, 2026-10-20: preferencias económicas e informativas,
ruleset projects/boteparroquial/rulesets/b74cba9c-8221-4c48-9226-5ab95ea716c3,
release 2026-10-20T09:23:23.193385Z, SHA-256 remoto/local
c9e4cb547e11c5053f8814eea7ca3622a39eef6e45e7af1b02608532516d3c55.
Hosting https://boteparroquial.web.app publicado para invitaciones. Identidad IAM
dedicada y credencial autorizadas expresamente para el segundo Supabase aislado;
worker/cron activos, sin Blaze ni cambio de facturación. Respaldo externo nuevo,
metadatos y validaciones: [informe vigente](PHASE9_NOTIFICATIONS_AND_LINKS_VALIDATION.md).
Push y App Links en dispositivo, APNs/iOS y firma Android release pendientes.

Publicación anterior, 2026-10-19: devoluciones y alta con primer mes opcional
(D082–D086). Ruleset projects/boteparroquial/rulesets/38c2c77a-c18c-4c51-a8a9-f43e9dfa5702,
actualizado 2026-10-19T17:33:36.670521Z. SHA-256 remoto/local coincidente:
5c776e8d4b9b965ca4fe19a9e14f3564378e5461767a69c59d628098e20c3520.
Nuevo respaldo externo de reglas activas anteriores, código local y APK anterior,
sin sobrescribir copias previas; no incluye documentos ni fotos. Publicación solo
firestore:rules, sin modificar datos, índices, Auth Console o Supabase. Informe:
docs/PHASE8_REFUNDS_VALIDATION.md.

Publicación anterior, 2026-10-19: asignaciones de cuotas (D079–D081). Ruleset
projects/boteparroquial/rulesets/19c7a8f8-7ff2-4b94-b7dc-4264df8cc585,
actualizado 2026-10-19T09:50:45.107352Z. SHA-256 remoto/local coincidente:
b98fa4c4356da632aab553ab33d3ef92a5c69dbf70c9d647eb136a11a16886c8.
Sin cambios de documentos remotos, Auth Console, índices o Supabase. Evidencia y copia
externa de permisos anterior: docs/PHASE8_ALLOCATIONS_VALIDATION.md.

Publicación anterior, 2026-10-19: cuotas y periodos (D077/D078). Ruleset
projects/boteparroquial/rulesets/b7d039b7-06c4-4e20-a947-557342332195,
actualizado 2026-10-19T09:15:51.925178Z. SHA-256 remoto/local coincidente:
e268187755291c0c5fa8bb4d78325f36b02459e0e1fd6ae8b7d1989bfbf48f4a.
Sin cambios de Auth Console, Supabase o documentos remotos. Evidencia y respaldo:
docs/PHASE8_QUOTAS_PERIODS_VALIDATION.md. Los registros siguientes son históricos.

Publicación anterior, 2026-10-18: roles y transferencia con reautenticación Google,
grupo y membresías auditados atómicamente. Ruleset activo
projects/boteparroquial/rulesets/b71e918a-cec6-4593-9560-2e88387e755d,
actualizado 2026-10-18T10:19:39.169901Z. Fuente remota/local coincidente, SHA-256
cf818683961a26ef5416d257e7b1e620ad03d0aac6e72a3d1faf876b5b647019.
Sin cambios en Auth Console, Supabase ni documentos. Evidencia y copia externa
anterior: docs/PHASE7_ROLES_TRANSFER_VALIDATION.md. Los despliegues que siguen
se conservan como historial, no como descripción completa de permisos vigentes.

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
Este párrafo registra el despliegue histórico de Phase 1.

Phase 2 (2026-10-15): reglas actualizadas y publicadas tras nueve pruebas de
emulador. Ruleset dd2fe98e-7d08-4003-996e-ebf411ed4672. Se permite descubrir
membresías propias filtrando uid y leer grupo/miembros con membresía activa y
grupo activo. Todas las escrituras cliente de grupos/membresías siguen denegadas;
personas y dinero permanecen cerrados. Índice collection-group members.uid en
firestore.indexes.json. No había índices personalizados anteriores.
Prueba1 creado mediante commit atómico de grupo y owner con timestamps de servidor.
Detalle, herramienta de aprovisionamiento y validación: docs/PHASE2_VALIDATION.md.

Phase 3 (2026-10-15): reglas de Personas publicadas tras tres pruebas específicas
en emulador. Ruleset 462d2c3d-0f34-41b0-8ec2-cd607e26d0c9. Lectura para miembros
activos; alta/edición para owner o admin vinculado a persona activa del mismo grupo.
Autores, tipos, campos y timestamps validados; createdAt/createdBy inmutables;
borrado denegado. Sin índices nuevos ni cambios de configuración en Console.
Movimientos y demás colecciones futuras siguen cerrados.
Ver docs/PHASE3_VALIDATION.md para el alcance exacto y las comprobaciones pendientes.

Phase 4 (2026-10-15): reglas financieras publicadas y leídas de nuevo para comprobar
que coinciden con el fichero local. Ruleset final:
89e8c7fc-2898-4366-a310-139a8a2b26f7. Sin índices nuevos; el índice de memberships
continúa READY. Operaciones cliente reales en A059P verifican ingreso, reintento,
corrección y anulación; los datos DEMO se conservan por autorización del usuario.
Ver docs/PHASE4_VALIDATION.md para el estado actual. Los párrafos de Phase 1–3
anteriores registran sus despliegues históricos, no las reglas vigentes completas.

No crear otra base simplemente porque estos datos todavía no estén documentados.

Phase 6 (2026-10-15): cuatro pruebas económicas pasan en emulador y el despliegue
confirma compilación y publicación. Ruleset histórico de esa fase:
3a47ea62-c02e-47d8-ab82-deb95b2313ad. Añade occurredAt == occurredAt.date() para
exigir día civil UTC sin horas; mantiene los permisos y transiciones de Phase 4.
Sin nuevos índices, colecciones ni activaciones de servicios. El margen request.time+24 h
permanece: no implica validación exacta de «hoy» por zona IANA en servidor.
Ver docs/PHASE6_VALIDATION.md. Los rulesets anteriores son historial.

Phase 7 parcial (2026-10-17): el usuario autoriza publicar después del respaldo
externo. Publicadas primero las Rules de creación/identidad de grupos y perfil;
después códigos, solicitudes/aprobación y bajas con auditoría atómica. Versión
verificada de ese bloque: c4d4cdd5-23d6-4a9e-8cc3-30cbf1370d3b, actualización
2026-10-17T10:22:46.741797Z; hash remoto igual al local. No se cambian índices ni
servicios de Console. 14 documentos DEMO nuevos, grupo aislado y sin sobrescrituras.
En ese bloque, readmisiones y gestión general de roles seguían cerradas. Evidencia:
docs/PHASE7_INVITATIONS_VALIDATION.md. La copia anterior de Phase 6 sigue fuera
de Git; docs/FIRESTORE_RULES_BACKUP.md contiene su ubicación y restauración.

Readmisión posterior (D069): el usuario escoge aprobación obligatoria incluso en
entrada automática. Rules publicadas y verificadas de ese bloque:
546c76d7-8784-4565-8326-365182315b98, 2026-10-17T10:37:08.559634Z. Hash coincide
con la fuente local. Solo gestores autorizados reactivan la membresía como member
con vínculo/antigüedad conservados; no se escriben documentos reales. Pruebas y
límites: docs/PHASE7_READMISSION_VALIDATION.md. Roles generales siguen cerrados.

Vínculos (2026-10-18): versión activa b3d98bda-b2d0-4070-83f2-3765cf28cf69,
actualizada 2026-10-18T09:46:37.411830Z. SHA-256 remoto/local
305fe15bf4e83cf66fe205ff006a8cb105ef5948c7c6d1a52171f1b6b0279e31.
Vínculos únicos recíprocos y degradación automática de admin, sin promociones.
Preparados dos vínculos anteriores del grupo DEMO con auditoría y precondiciones;
sin cambios de roles ni dinero durante la preparación. No hay nuevos índices ni
activaciones de Console. Detalle: docs/PHASE7_LINKS_VALIDATION.md.

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
