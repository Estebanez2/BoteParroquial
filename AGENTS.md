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

Durante el prototipo, el usuario autoriza crear datos ficticios en Firestore para
comprobar casos funcionales (2026-10-15). Etiquetarlos como DEMO/[Prueba] y registrar
lo generado. No sobrescribir datos existentes para sembrar ejemplos. El usuario
indica que borrará los datos al empezar el uso real: no es una petición de borrar
ni reiniciar la base ahora. Revisar esta autorización cuando indique uso real.

Preferencia explícita del usuario (2026-10-15): no dar decisiones por entendidas.
Cuando algo admita varias formas de hacerse, preguntar cuál prefiere antes de
elegir o implementar la alternativa. Explicar brevemente las diferencias y
recomendar una opción. No interpretar el silencio como respuesta. Consultar las
decisiones ya acordadas para no volver a preguntar lo que el usuario ha resuelto.

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

Preferencia del usuario (2026-10-15): ejecutar solo las pruebas necesarias para
el cambio, sin multiplicar casos ni repetir suites completas sin motivo. Priorizar
permisos, integridad de datos y el flujo afectado; análisis y compilación pertinentes.
Las listas siguientes son referencias generales, no una obligación de ejecutar
toda la suite en cada cambio. Registrar exactamente qué se ha comprobado.

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
No incorporarla a la navegación de producción. En Phase 2 el usuario solicita
avanzar usando esta base: AppTheme está conectado y home/grupos componen App*.
Actualización visual (2026-10-15): las ocho imágenes aportadas por el usuario son
la referencia de estética. Base v0.2 con verde oscuro, menta, degradados, bordes y
títulos serif. Tema oscuro predeterminado; mantener también el tema claro y la
accesibilidad. Login ya compone App*. Personas se edita en pantalla completa según
la nueva referencia, sustituyendo el panel elegido en Phase 3.
El usuario decide hacer ahora solo el rediseño de funciones existentes con iniciales;
subidas de fotos, Storage, invitaciones, notificaciones y estadísticas avanzadas
siguen pendientes. No mostrar controles de esas funciones como si estuvieran listas.
Permisos de futuras fotos acordados en docs/DECISIONS.md; no confundirlos con Rules
implementadas. Estado y evidencia: docs/VISUAL_REDESIGN_VALIDATION.md.
Actualización posterior: el usuario elige Supabase Storage y autoriza preparar la
conexión. Sustituye el aplazamiento anterior: función y bucket privado desplegados,
UI de cámara/galería integrada; usuario confirma fotos de personas y de cuenta.
Actualización: foto de cuenta por defecto con excepción por grupo, caché privada
por cuenta y editor de recorte/zoom/rotación. Ver D057/D058; no copiar fotos entre
grupos ni permitir cambiar la foto global de otra cuenta.
El usuario confirma en A059P la foto en Miembros, navegación sin parpadeo y editor
funcionando; esto no acredita otros roles, otros móviles ni iOS.
Firebase mantiene login y datos. Consultar docs/SUPABASE_SETUP.md antes de tocar
fotos. La función comprueba JWT y roles actuales; no exponer acceso directo a Storage.
Personas internas tienen foto independiente;
sincronización automática prohibida. No confundir pruebas locales con red real.
Petición del usuario: UI distintiva y animaciones siempre que encajen, con propósito
y respetando movimiento reducido; no animar por animar ni sacrificar accesibilidad.
