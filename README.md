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

Reglas de Phase 2 publicadas: cada cuenta mantiene privado su perfil users/{uid}.
Puede descubrir sus membresías por uid y leer grupos activos y miembros si tiene
membresía activa. No puede asignarse roles ni escribir grupos/membresías.
Personas y datos económicos siguen cerrados. Ver docs/PHASE2_VALIDATION.md.

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
membresías siguen en Phase 7; no existe todavía CRUD de personas o movimientos.

No existe todavía saldo ni dashboard financiero.

Design System v0.1 en uso por petición del usuario desde Phase 2.
Tokens y componentes en lib/design_system/; galería debug sin Firebase:

flutter run --debug -t lib/main_showcase.dart

La app habitual sigue en lib/main.dart con AppTheme claro/oscuro. Home y grupos
componen App* con entrada animada respetuosa con movimiento reducido; login
mantiene su composición previa con el tema común.
La galería muestra cifras y personas de ejemplo, sin implementar lógica financiera.
Las pruebas de segunda cuenta y restauración real aplazadas no se han reanudado.

Validación de la fase actual y aprovisionamiento: docs/PHASE2_VALIDATION.md.

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
