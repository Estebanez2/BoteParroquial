BoteParroquial

Aplicación Flutter para gestionar botes de dinero compartidos.

El proyecto comienza con un MVP pequeño para pocos administradores, pero su arquitectura está diseñada desde el principio para evolucionar hacia una aplicación con múltiples grupos, miembros, cuotas mensuales, estadísticas, notificaciones e historial completo.

Stack

Flutter

Dart

Firebase Core

Firebase Authentication

Google Sign-In

Cloud Firestore

Riverpod

go_router

Android es la primera plataforma de desarrollo.

La arquitectura debe mantenerse compatible con iOS.

Documentación

AGENTS.md
    Reglas principales para Codex/agentes.

PRODUCT_SPEC.md
    Alcance del MVP actual.

ARCHITECTURE.md
    Arquitectura y dependencias.

FIREBASE_SCHEMA.md
    Contrato de persistencia Firestore.

CODING_RULES.md
    Convenciones de implementación.

DESIGN_SYSTEM.md
    Identidad propuesta, tokens, componentes, galería y evaluación de librerías.

docs/DECISIONS.md
    Decisiones técnicas y funcionales ya tomadas.

docs/ROADMAP.md
    Registro general de avance: fases completadas, pendientes y pruebas aplazadas.

docs/PHASE1_VALIDATION.md
    Evidencia y lista de comprobaciones de autenticación, incluidas las pendientes.

docs/FULL_PRODUCT_SPEC.md
    Especificación funcional de la aplicación completa.

docs/firebase-setup.md
    Estado y configuración real de Firebase.

Estado actual

Fecha de referencia: 2026-10-15.

Actualmente:

El proyecto Flutter existe.

Android e iOS están configurados como plataformas.

Firebase Core está integrado.

Firebase Authentication está añadido.

Google Sign-In está añadido.

Cloud Firestore está añadido.

Riverpod está añadido.

go_router está añadido.

FlutterFire generó firebase_options.dart.

Firebase está configurado para Android e iOS.

Google Authentication está habilitado.

Firestore ha sido creado.

Base `(default)`, edición Standard, región `europe-southwest1` (Madrid).
Metadatos comprobados con Firebase CLI el 2026-10-15.

Reglas vigentes publicadas en Phase 6, conservando los permisos de Phase 4:
cada cuenta mantiene privado su perfil users/{uid}.
Puede descubrir sus membresías por uid y leer grupos activos y miembros si tiene
membresía activa. No puede asignarse roles ni escribir grupos/membresías.
Personas admite lectura de miembros activos y gestión de owner/admin autorizado.
Movimientos permite lectura de miembros y escritura controlada de owner/admin válido:
registro, anulación y corrección atómica, sin borrar ni editar importes históricos.
Ver docs/PHASE4_VALIDATION.md.

Login con Google y perfil guardado comprobados con una primera cuenta real en
A059P (Android 16, API 36). El cierre de sesión también está confirmado en registros.
La prueba con segunda cuenta está aplazada por petición del usuario: no dispone
de otra cuenta ahora. La restauración tras reinicio con sesión abierta sigue
pendiente de comprobar. No hay pruebas manuales en curso.

Phase 1 implementa login, logout, restauración de sesión, rutas protegidas,
creación/lectura del perfil, estados de carga, errores y reintento explícito.
El último acceso del perfil registra el inicio de una sesión autenticada de la app,
incluida su restauración; createdAt se conserva mediante transacción.

La feature auth ya sigue UI → Provider → Repository → Service → Firebase.
Su modelo está en lib/models/, los repositories en lib/repositories/, los services
en lib/services/ y los providers en lib/features/auth/providers/.
No se ha realizado una reorganización global de las demás features.

Detalle de verificaciones y comprobaciones pendientes:
docs/PHASE1_VALIDATION.md.

Phase 2 implementa lista de grupos propios, contexto por ruta, roles y lectura
de miembros en tiempo real. Prueba1 está aprovisionado con la cuenta de la app
confirmada por el usuario como propietaria. La creación desde UI y gestión de
membresías siguen en Phase 7.

Phase 3 implementa listado de personas en tiempo real, creación y edición de
nombre/notas en panel inferior, activar e inactivar con confirmación, sin borrado.
Datos separados por grupo, validación de autor/fechas y protección ante edición
concurrente. Comprobaciones dirigidas: una prueba Flutter de flujo, tres pruebas
de reglas, análisis sin incidencias y APK compilado e instalado en A059P.
El rediseño v0.2 posterior sustituye el panel de edición por pantalla completa.
El usuario confirma que Personas funciona el 2026-10-15. La sincronización entre dos
móviles sigue sin comprobarse; esa confirmación no se extiende a pruebas no realizadas.

Phase 4 incorpora ingresos, retiradas generales o por persona, historial en tiempo
real, anulación y corrección conservando originales. Formularios en pantalla completa,
advertencia por persona inactiva y confirmación de saldo negativo. Solo fechas de hoy
o anteriores. Reintentos del mismo envío sin crear otro documento.
Comprobaciones dirigidas: cuatro pruebas de reglas, una del flujo visual y una
comprobación nativa con la sesión real en A059P. No se repitió la suite completa.
Hay datos DEMO autorizados en Prueba1, «Prueba · Saldo negativo» y
«Prueba · Historial vacío». Ver docs/PHASE4_VALIDATION.md para cifras y límites.

Phase 5 incorpora el Dashboard como inicio del grupo: saldo, totales históricos de
movimientos activos, personas activas/inactivas y los cinco últimos cambios financieros.
Corregidos/anulados no suman; la actividad ordena por fecha de registro/cambio y no
duplica el sustituto activo. Personas y miembros tienen pantallas independientes.
Los cálculos viven en DashboardRepository, fuera de widgets; no hay saldo persistido.
Se reutilizan las suscripciones existentes por elección del usuario para el MVP;
optimizar agregados cuando crezca el historial sigue pendiente.

Análisis sin incidencias, ocho pruebas dirigidas superadas y APK debug compilado.
El usuario reconecta el móvil y confirma que funciona el 2026-10-15. Esta confirmación
del Dashboard no acredita una segunda cuenta ni sincronización entre dos móviles.
Ver docs/PHASE5_VALIDATION.md y el apartado de cierre de MVP en docs/ROADMAP.md.

Phase 6 en curso: consulta de caché con aviso de actualización sin confirmar y
operaciones económicas con confirmación de servidor. Los envíos se guardan antes
de escribir, en archivos privados por cuenta/grupo, y se comprueban al volver al
grupo. Si faltan, el reintento requiere confirmación y conserva datos e ID; no se
reenvían automáticamente. Cambiar de cuenta no expone pendientes de otra cuenta.
La lista de grupos no depende de poder actualizar el perfil al abrir sin red.
El usuario permite descartar el intento local tras revisar y confirmar; nunca se
borra dinero. «Hoy» usa la zona IANA del grupo y Rules exige medianoche UTC para
la fecha efectiva. El margen de 24 h de servidor sigue sin validación IANA exacta.
Detalle y pendientes de cierre: docs/PHASE6_VALIDATION.md.
Tras instalar el APK de Phase 6, el usuario confirma que al activar la conexión
vuelven a aparecer los grupos. Comprobación online confirmada; caché sin conexión
y recuperación tras cierre siguen pendientes de validación física.

Design System v0.2: rediseño basado en las ocho referencias del usuario.
Verde casi negro, acentos menta/coral, degradados, tarjetas con contorno y títulos
serif. Inicio, resumen, historial, formularios, Personas, Miembros y login usan App*.
Tema oscuro predeterminado; el tema claro se conserva y se revisa en vistas simuladas.
Personas pasa de panel a pantalla completa. Avatares e imágenes de grupo muestran
iniciales; subidas de fotos se aplazan expresamente, junto con Storage.
Los permisos de fotos futuras están acordados, pero no están implementados ni activos.
No se adelantan invitaciones, notificaciones ni estadísticas de las referencias.
Detalle: docs/VISUAL_REDESIGN_VALIDATION.md.
Tokens y componentes en lib/design_system/; galería debug sin Firebase:

flutter run --debug -t lib/main_showcase.dart

La app habitual sigue en lib/main.dart con AppTheme claro/oscuro y componentes App*,
con entrada animada respetuosa con movimiento reducido.
La galería muestra cifras y personas de ejemplo, sin implementar lógica financiera.
Las pruebas de segunda cuenta y restauración real aplazadas no se han reanudado.

Validación actual: docs/PHASE6_VALIDATION.md y docs/VISUAL_REDESIGN_VALIDATION.md.
Aprovisionamiento inicial: docs/PHASE2_VALIDATION.md.

No asumir que una funcionalidad está implementada simplemente porque aparezca documentada.

Firebase

Proyecto:

boteparroquial

Configuración detallada:

docs/firebase-setup.md

Arquitectura

Dirección objetivo:

UI
↓
Provider
↓
Repository
↓
Service
↓
Firebase

Ver:

ARCHITECTURE.md

Comandos habituales

flutter pub get

flutter analyze

flutter test

flutter devices

flutter run

flutter build apk --debug

Regla importante

Antes de empezar una nueva fase con Codex:

Lee AGENTS.md y los documentos que referencia.
Estamos trabajando en Phase X de ROADMAP.md.

No volver a explicar toda la arquitectura en cada conversación salvo que haya cambiado.
