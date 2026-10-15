BoteParroquial — Instrucciones para agentes

Este es el documento principal de instrucciones para Codex y otros agentes que trabajen en este repositorio.

Antes de realizar cambios:

Leer README.md para conocer el estado real del proyecto.

Leer PRODUCT_SPEC.md si el cambio afecta al producto.

Leer ARCHITECTURE.md si afecta a estructura o dependencias.

Leer FIREBASE_SCHEMA.md si afecta a datos.

Leer CODING_RULES.md antes de implementar código.

Consultar docs/DECISIONS.md para no contradecir decisiones ya tomadas.

Consultar docs/ROADMAP.md para respetar la fase actual.

Leer DESIGN_SYSTEM.md antes de crear o modificar UI.

Seguimiento del trabajo:

docs/ROADMAP.md es el registro general de fases completadas y pendientes.
Las comprobaciones detalladas de autenticación están en docs/PHASE1_VALIDATION.md.
Al terminar una tarea, actualizar el estado, la evidencia comprobada y los pendientes.
Mantener README.md y los documentos de validación coherentes con ese registro.
No confundir implementación terminada con validación completa ni dar por superadas
pruebas aplazadas. No reanudar una prueba manual aplazada sin que el usuario lo solicite.

Las instrucciones explícitas del usuario tienen prioridad.

Si algo no está decidido, no inventar comportamiento. Documentarlo como pendiente o preguntar cuando sea necesario.

Proyecto

Nombre: BoteParroquial

Tecnologías principales:

Flutter.

Dart.

Android como primera plataforma.

Mantener compatibilidad con iOS.

Firebase Authentication.

Google Sign-In.

Cloud Firestore.

Riverpod.

go_router.

El proyecto empieza como un MVP utilizado por pocos administradores, pero debe mantenerse preparado para evolucionar a la aplicación completa descrita en docs/FULL_PRODUCT_SPEC.md.

Arquitectura obligatoria

Dirección general:

UI → Provider → Repository → Service → Firebase

Reglas:

La UI no accede directamente a Firestore.

La UI no contiene lógica de negocio.

Los providers coordinan estado y acciones.

Los repositories representan operaciones del dominio.

Los services encapsulan Firebase y otros SDK externos.

Los modelos de dominio no dependen de Flutter ni de Firebase.

No extender patrones antiguos que contradigan esta arquitectura.

Si una zona existente todavía mezcla Repository y Service, migrar únicamente la parte afectada cuando sea necesario. No realizar refactors masivos no solicitados.

Datos y grupos

La aplicación debe soportar múltiples grupos.

Nunca crear colecciones globales:

persons

movements

admins

Estructura base:

users/{uid}

groups/{groupId}

groups/{groupId}/members/{uid}

groups/{groupId}/persons/{personId}

groups/{groupId}/movements/{movementId}

Futuras subcolecciones:

quotaRules
auditEvents
participationPeriods
allocations
notifications
joinRequests

Todas las operaciones relacionadas con personas, miembros o movimientos deben recibir groupId explícitamente.

No codificar un único grupo como supuesto permanente de la arquitectura.

Dinero

Nunca almacenar dinero como double.

Utilizar enteros en la unidad mínima de la moneda.

Ejemplo:

20,50 € = 2050

Nombres recomendados:

amountCents
balanceCents
monthlyFeeCents

Los importes de movimientos son siempre positivos.

El campo type determina su efecto:

income
withdrawal

Movimientos económicos

Los movimientos económicos no se eliminan directamente.

Estados previstos:

active
cancelled
corrected

Una corrección conserva el movimiento original y crea un movimiento sustituto.

El saldo deriva siempre de movimientos válidos.

Nunca modificar un importe histórico simplemente para corregir el saldo.

Personas

Las personas internas son distintas de los usuarios autenticados.

Una persona puede existir sin cuenta de Google.

Las personas con historial financiero no se eliminan.

Se marcan como:

active
inactive

La futura vinculación usuario/persona se realiza dentro de un grupo.

Roles

Los roles pertenecen a la membresía del grupo, no al usuario global.

Roles previstos:

owner
admin
member

Firebase Authentication identifica al usuario.

La membresía del grupo determina sus permisos.

Nunca permitir que el cliente se conceda un rol a sí mismo.

Seguridad

No confiar en esconder botones en Flutter.

Firestore Security Rules debe validar:

autenticación;

pertenencia al grupo;

rol;

campos permitidos;

transiciones de estado;

integridad básica de los datos.

No utilizar reglas públicas para datos reales.

Alcance

No implementar funcionalidades futuras simplemente porque estén documentadas.

Las fases están definidas en docs/ROADMAP.md.

Storage, Cloud Functions, Scheduler y notificaciones se añadirán cuando una fase realmente los necesite.

Validación

Para cambios Dart:

dart format lib test
flutter analyze
flutter test

Para cambios relevantes de Android:

flutter build apk --debug

Un APK compilado no demuestra que:

la app arranque correctamente;

Google Sign-In funcione;

Firebase esté accesible;

las reglas permitan las operaciones.

Para afirmar que algo funciona en dispositivo debe haberse probado realmente.

iOS requiere Mac y Xcode para compilar y probar.

Design System

Las futuras pantallas deben reutilizar lib/design_system/design_system.dart.
Buscar componentes existentes antes de crear uno nuevo.
No hardcodear colores ni estilos tipográficos en features.
No inventar paddings, radios o sombras arbitrarios: usar los tokens centrales.
Los componentes reutilizables van a lib/design_system/.
Los componentes específicos de una feature permanecen en ella y componen App*.
Envolver librerías visuales externas detrás de componentes propios cuando exista
o deba existir una abstracción equivalente; no exponer su API por todas las pantallas.

Los tokens visuales viven en design_system/theme, no duplicarlos en core/theme.
Los componentes no calculan reglas financieras ni permisos y no llaman a Firebase.
Respetar modo oscuro, texto ampliado y movimiento reducido.

La galería se ejecuta mediante lib/main_showcase.dart, solo en debug y sin Firebase.
No incorporarla a la navegación de producción. La identidad v0.1 está pendiente
de aprobación del usuario. Login/home actuales se migrarán después de esa aprobación;
su apariencia provisional no debe copiarse al crear nuevas pantallas.
