Roadmap

El proyecto debe avanzar por fases pequeñas.

Mantener siempre una versión compilable.

Seguimiento general — actualizado el 2026-10-15

Este archivo es el registro general de avance del proyecto. Actualizarlo al
completar trabajo o aplazar comprobaciones. Los detalles de cada validación se
registran en su documento específico, sin cambiar los criterios de cierre.

| Fase | Estado actual | Pendiente |
| --- | --- | --- |
| Phase 0 — Foundation | Completada y arranque comprobado en A059P | Sin pendientes de cierre Android |
| Phase 1 — Authentication | Implementada; validación parcial en móvil | Segunda cuenta aplazada y restauración con sesión abierta sin comprobar |
| Etapa visual previa a Phase 2 | Design System v0.1 y galería implementados | Aprobación de identidad visual y posterior migración de pantallas |
| Phase 2 — Groups & Membership | No iniciada | Implementación y validación de su alcance |
| Phase 3–12 | No iniciadas | Desarrollo según las fases descritas más abajo |

Prueba aplazada por el usuario el 2026-10-15:

No dispone de una segunda cuenta Google actualmente. Dejar la prueba para más
adelante y no solicitarla de nuevo ni reanudarla hasta que el usuario lo indique.
La implementación de Phase 1 está terminada, pero su criterio de dos cuentas
reales todavía no está cumplido. La restauración tras reinicio con sesión abierta
tampoco se ha comprobado en dispositivo y se mantiene como pendiente separado.
No hay una prueba manual actualmente en curso.

Ver docs/PHASE1_VALIDATION.md para la evidencia y los pasos para retomarlas.

Etapa visual previa a Phase 2 — Design System

Tokens, componentes App*, fuentes locales, temas claro/oscuro y galería debug
independiente implementados. La suite completa pasa 22 pruebas; las vistas se han
exportado y revisado visualmente. Ver DESIGN_SYSTEM.md desde la raíz.
Esta etapa no implementa grupos ni lógica financiera. La identidad visual v0.1
es una propuesta pendiente de aprobación; login/home siguen sin migrar.
No cambia el aplazamiento de pruebas manuales de Phase 1.

Phase 0 — Foundation

Objetivo:

base técnica.

Incluye:

Flutter.

Android/iOS.

Firebase Core.

Riverpod.

go_router.

documentación.

estructura inicial.

Estado:

completada: análisis, pruebas y APK correctos; arranque Android comprobado en A059P
(Android 16, API 36) el 2026-10-15.

Cierre:

flutter analyze correcto;

tests correctos;

APK debug correcto;

arranque Android probado.

Phase 1 — Authentication

Estado:

implementada. Ocho pruebas Flutter y cuatro pruebas de reglas pasan. Login y perfil
con una primera cuenta real confirmados en A059P. Cierre de sesión observado en
registros. Restauración tras reinicio con sesión abierta pendiente; segunda cuenta
aplazada por petición del usuario porque no dispone de otra cuenta actualmente.
Ver docs/PHASE1_VALIDATION.md; no dar por cerrado el criterio de dos cuentas todavía.

Incluye:

Google Sign-In;

Firebase Authentication;

sesión;

login;

logout;

creación/lectura del perfil users/{uid}.

Cierre:

dos cuentas reales pueden iniciar sesión correctamente en Android.

Phase 2 — Groups & Membership

Incluye:

primer grupo;

owner;

admin;

member;

membresías;

contexto de grupo;

reglas Firestore correspondientes.

Para el MVP se puede aprovisionar inicialmente el primer grupo de forma controlada.

Cierre:

solo miembros autorizados pueden acceder al grupo.

Phase 3 — Persons

Incluye:

listado;

creación;

edición;

activar;

inactivar.

Cierre:

los administradores comparten las mismas personas desde varios móviles.

Phase 4 — Movements

Incluye:

ingresos;

retiradas;

historial;

validación de dinero;

autor;

fechas;

estados;

corrección/anulación básica.

Cierre:

movimientos persistidos de forma segura sin doble contabilización.

Phase 5 — Dashboard

Incluye:

saldo;

total ingresado;

total retirado;

personas;

actividad reciente.

Cierre:

dos administradores ven el mismo estado actualizado.

Phase 6 — MVP Hardening

Incluye:

reglas Firestore completas;

pruebas;

errores;

validaciones;

concurrencia;

UX;

accesibilidad;

pruebas en dispositivos.

Cierre:

MVP estable.

Phase 7 — Full groups

Incluye:

crear grupos;

unirse;

códigos;

enlaces;

aprobación;

gestión completa de miembros;

transferencia de propiedad.

Phase 8 — Monthly quotas

Incluye:

cuota mensual;

historial de cambios;

periodos de participación;

pagos atrasados;

pagos adelantados;

allocations;

crédito.

Phase 9 — Notifications

Incluye:

Firebase Cloud Messaging;

aviso 7 días antes;

aviso 1 día antes;

vinculaciones pendientes;

cambios de roles;

movimientos asociados.

Aquí se evaluará Cloud Functions y Cloud Scheduler.

Phase 10 — Reports

Incluye:

mensual;

trimestral;

anual;

por persona;

gráficas;

comparaciones.

Phase 11 — Audit & recovery

Incluye:

auditEvents;

historial administrativo;

papelera de 10 días;

confirmaciones fuertes;

transferencia y eliminación segura.

Phase 12 — Export

Incluye:

PDF;

CSV;

Excel;

historial completo.
