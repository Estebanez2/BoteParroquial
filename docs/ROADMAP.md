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
| Etapa visual previa a Phase 2 | Base histórica v0.1 y galería implementadas | Sustituida visualmente por v0.2; ver rediseño durante Phase 6 |
| Phase 2 — Groups & Membership | Implementada y validada: Prueba1 en A059P, aislamiento probado en emulador | Segunda cuenta real e iOS sin probar; gestión completa de grupos permanece en Phase 7 |
| Phase 3 — Persons | Implementada; usuario confirma que funciona en móvil | Sincronización entre móviles sin comprobar |
| Phase 4 — Movements | Implementada; reglas, flujo visual y operaciones nativas verificadas | Hardening y pruebas con varios móviles en fases posteriores |
| Phase 5 — Dashboard | Implementada; cálculos y flujos dirigidos comprobados; usuario confirma funcionamiento en móvil | Estado compartido entre dos administradores sin comprobar |
| Phase 6 — MVP Hardening | En curso: caché señalizada y recuperación persistente de envíos | Validación física de los cambios, revisión final y comprobaciones de cierre del MVP |
| Rediseño por referencias, durante Phase 6 | Base visual v0.2 y pantallas actuales adaptadas; iniciales | Aprobación visual del usuario; fotos/subidas y funciones futuras aplazadas |
| Phase 7–12 | No iniciadas | Ampliaciones posteriores al MVP |

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
Esta etapa visual inicial no implementó grupos ni lógica financiera. Después,
el usuario pidió continuar Phase 2 usando esta base: home/grupos ya componen App*
y AppTheme está conectado a la app; login conservaba su composición anterior en
aquella etapa. El rediseño posterior v0.2 también lo migra a App*.
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

Estado:

implementada y validada en su alcance inicial: Prueba1 aprovisionado desde terminal
por elección del usuario, con su cuenta de la app como owner; grupo y membresía
comprobados en A059P. Lista de grupos propios y miembros, contexto por ruta y reglas
de acceso en tiempo real. 26 pruebas Flutter y 9 de reglas superadas; analyze sin
incidencias y APK compilado. Índice y reglas publicados y verificados.
La segunda cuenta real sigue aplazada; aislamiento y roles admin/member se han
probado en emulador y con repositorios simulados. iOS sin probar.
Ver docs/PHASE2_VALIDATION.md. No se ha adelantado CRUD de personas o dinero.

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

Estado:

implementada el 2026-10-15. Listado en tiempo real por grupo, alta/edición mediante
panel inferior elegido por el usuario, activar/inactivar con confirmación y sin
borrado. Reglas publicadas para owner/admin autorizado y lectura de miembros.
Una prueba Flutter de flujo y tres pruebas de reglas superadas; analyze limpio,
APK compilado e instalado en A059P. No se ha repetido la suite completa por petición
del usuario. No se han creado personas ficticias en la base real.
Pendiente validar CRUD con datos reales y sincronización entre móviles; no dar
por cumplido todavía el criterio de cierre. Ver docs/PHASE3_VALIDATION.md.

Actualización posterior: el usuario confirma «funciona» al iniciar Phase 4.
No se especifican operaciones concretas ni se confirma un segundo móvil, por lo que
ese criterio de cierre sigue pendiente. Autoriza crear datos ficticios en Firestore.

Incluye:

listado;

creación;

edición;

activar;

inactivar.

Cierre:

los administradores comparten las mismas personas desde varios móviles.

Phase 4 — Movements

Estado:

implementada el 2026-10-15. Ingresos, retiradas, historial, validaciones, motivos,
anulación y corrección atómica. Enteros en céntimos, conservación de originales,
IDs de envío para reintentos y advertencias elegidas por el usuario.
Cuatro pruebas dirigidas de Rules y una del flujo visual pasan. SDK Android en A059P
contra Firestore real confirma crear/reintentar, corregir/reintentar y anular/reintentar
sin duplicar documentos. Datos DEMO autorizados en tres grupos. No se ha repetido la
suite completa ni se han reanudado pruebas aplazadas de auth. Ver docs/PHASE4_VALIDATION.md.

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

Estado:

implementada el 2026-10-15. El usuario elige que sea el inicio de cada grupo y que
actividad reciente muestre los últimos cambios registrados, incluidas correcciones
y anulaciones. Totales históricos de active, personas activas/inactivas y cinco
cambios recientes; sustituto activo no duplicado en actividad.
Cálculos en DashboardRepository puro y coordinación en providers; la UI no calcula.
El usuario aprueba reutilizar los flujos completos del MVP y optimizar agregados después.
Sin cambios de Firebase, reglas, índices ni dependencias. Ocho pruebas dirigidas pasan;
análisis sin incidencias y APK debug generado. Se corrige una lectura diferida de Ref al cerrar providers.
El usuario ha desconectado el móvil: no se instala ni se afirma validación física
del Dashboard. El criterio de dos administradores actualizados sigue pendiente.
Detalle: docs/PHASE5_VALIDATION.md.

Actualización posterior: el usuario vuelve a conectar el móvil y confirma «he
comprobado que todo funciona». Se registra como confirmación de uso del Dashboard,
sin atribuirle casos concretos no descritos ni pruebas con una segunda cuenta.

Incluye:

saldo;

total ingresado;

total retirado;

personas;

actividad reciente.

Cierre:

dos administradores ven el mismo estado actualizado.

Phase 6 — MVP Hardening

Rediseño solicitado durante esta fase:

El usuario aporta ocho referencias y decide aplicar su estética solo a funciones
actuales, con iniciales y sin activar Storage. Tema oscuro de referencia, menta,
degradados, contornos y serif; cabecera común por grupo, resumen, historial por días,
formulario financiero, Personas en pantalla completa, Miembros e inicio/login.
Los cálculos financieros siguen en repositories y el agrupado del historial se
proyecta en MovementHistoryRepository; no cambia el orden por fecha efectiva.
Los permisos de fotos quedan acordados para después, no se abren Rules ahora.
Evidencia y límites: docs/VISUAL_REDESIGN_VALIDATION.md. No cierra los pendientes
de conectividad/recuperación, segunda cuenta, dos móviles ni iOS.

Avance del 2026-10-15:

- El usuario elige consultar datos guardados con aviso y exigir conexión para
  confirmar operaciones económicas. Metadata de Firestore se adapta en Service;
  las pantallas no consultan Firebase. El aviso no es un detector de conexión física.
- El usuario elige conservar envíos pendientes al cerrar la app. Se escribe un
  archivo privado por cuenta/grupo antes del envío; al volver al grupo se consulta
  el servidor. Resultado confirmado limpia el intento local, ausencia permite
  reintento explícito con el mismo ID y datos. Nunca se reenvía automáticamente.
- El inicio muestra grupos aunque actualizar el perfil falle; providers de Groups
  seleccionan streams sin usar Ref dentro de generadores diferidos.
- El usuario permite descartar solo el intento local tras revisar/confirmar y
  elige el calendario de la zona del grupo para «hoy». Implementados en repository
  y Service; zona desconocida bloquea la operación, sin fallback silencioso.
- Rules exige occurredAt a medianoche UTC, coherente con el esquema. Cuatro pruebas
  económicas pasan y la regla se publica. Sin nuevos datos financieros reales.
  Ver docs/PHASE6_VALIDATION.md para evidencia y límites.
- Tras instalar el APK, el usuario activa la conexión del A059P y confirma que ya
  aparecen los grupos. Se resuelve la comprobación online pendiente del arranque;
  no se da por validada la consulta offline ni la recuperación de envíos tras cierre.

Qué falta para cerrar el MVP después de Phase 5:

Las funcionalidades básicas ya están implementadas. Falta esta fase de cierre,
no las ampliaciones de Phase 7–12:

- Comprobar físicamente los cambios nuevos de Phase 6, incluidos caché, cierre
  durante un envío y recuperación. El usuario ya confirma el funcionamiento del Dashboard.
- Configurar una segunda cuenta real como administrador autorizado, vinculada a
  persona activa, y comprobar personas, movimientos y resumen desde dos móviles.
  Retomar las pruebas de auth aplazadas solo cuando el usuario lo solicite.
- Completar la validación física de recuperación/conexión y la revisión de cierre.
  Calendario del grupo implementado en app, pero el instante depende del reloj del
  dispositivo y Rules mantiene margen de 24 h; validación exacta IANA en servidor
  no resuelta. Transacciones, reglas y recuperación tienen evidencia dirigida.
- Revisión final de UX/accesibilidad y corrección de incidencias encontradas;
  acordar el procedimiento de pasar de los datos DEMO al uso real.

Si el MVP se va a utilizar también en iOS, compilar y validar allí requiere Mac/Xcode.
Invitaciones completas, gestión libre de grupos, cuotas, notificaciones, estadísticas
avanzadas, auditoría y exportaciones continúan fuera de este MVP.

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
