# Entrega del 2026-10-17 — Revisión del MVP e historial

## Estado del MVP

Las funciones básicas del MVP están implementadas. La revisión de README,
PRODUCT_SPEC, ROADMAP y las validaciones de autenticación/Phase 6 coincide con
las rutas, providers, repositories, servicios y reglas presentes en el proyecto.
No se declara el MVP totalmente validado: Phase 6 continúa abierta.

| Área | Estado de implementación | Evidencia y pendiente |
| --- | --- | --- |
| Google, sesión y perfil | Implementada | Primera cuenta y logout comprobados anteriormente; restauración física y segunda cuenta pendientes |
| Grupos y miembros | Lectura y roles implementados; aprovisionamiento controlado | Prueba1 confirmado en A059P; crear/unirse/gestionar miembros pertenece a Phase 7 |
| Personas | Crear, editar, activar/inactivar implementado | Uso confirmado anteriormente; sincronización entre dos móviles pendiente |
| Movimientos | Ingresos, retiradas, historial, anulación/corrección e idempotencia implementados | Evidencia previa de reglas/operaciones; recuperación tras cierre real pendiente |
| Dashboard | Saldo y resumen derivados implementados | Confirmación anterior del usuario; dos administradores reales sin comprobar |
| Robustez | Caché señalizada y diario local de envíos implementados | Faltan validación física offline/recuperación y revisión final de UX/accesibilidad |
| Fotos | Supabase y editor implementados | Confirmación anterior de foto en Miembros, caché y editor; botón de edición actual del día 16 y otros roles pendientes de validación física |

El móvil está desconectado. No se instala ni ejecuta la app. No se retoman las
pruebas aplazadas con otra cuenta ni se borran datos DEMO. El cambio a uso real
requiere acordar ese procedimiento. La validación iOS requiere Mac/Xcode.
Se conserva el límite ya documentado de calendario IANA/reloj del dispositivo
y margen de fecha de servidor; esta entrega no lo resuelve.

## Qué se añade de la especificación completa

Alcance acotado de los apartados 56, 85 y 86: encontrar movimientos sin cambiar
las operaciones económicas ni depender de configuración remota nueva.

- Buscador por palabras en persona, creador, descripción y motivos de corrección/
  anulación; ignora mayúsculas, acentos y espacios sobrantes.
- Filtros combinables de tipo, estado, persona y creador. Incluye personas
  inactivas, referencias históricas no disponibles y retiradas sin persona.
- Intervalo de fechas efectivas, con ambos extremos incluidos. No usa createdAt
  para decidir el periodo. Permite un solo extremo; rechaza intervalos invertidos.
- Panel de criterios con Aplicar, Cancelar, Restablecer y Quitar fechas.
- Contador de resultados, estado sin coincidencias y limpieza de búsqueda/filtros.
- Conservación del orden por fecha efectiva descendente y de los tres estados
  financieros. Los totales y el saldo del Dashboard siguen usando los datos completos.
- Actualizaciones del stream reaplican los criterios. Los enlaces directos a
  originales/sustitutos ignoran filtros para conservar la trazabilidad.
- Estado temporal separado por grupo y reiniciado al cambiar de cuenta/perder
  acceso o al liberarse la pantalla. No se guarda una preferencia privada en Firestore.

La UI compone App* y tokens existentes, con entrada animada del panel respetuosa
con movimiento reducido. Se mantiene la variante clara y el texto ampliado.

## Arquitectura y alcance técnico

MovementHistoryControls → MovementFilterController/providers →
MovementHistoryRepository → flujo existente de MovementRepository/Service/Firestore.
Los criterios y opciones viven en modelos puros. Las pantallas no acceden a Firebase
ni calculan importes o coincidencias. El repository rechaza cualquier fila de otro
grupo incluso si no coincide con los filtros.

Archivos principales:

- lib/models/movement_history_filter.dart
- lib/repositories/movement_history_repository.dart
- lib/features/movements/providers/movement_providers.dart
- lib/features/movements/presentation/movement_history_controls.dart
- lib/features/movements/presentation/movements_screen.dart

No se modifican Rules, esquema, índices, dependencias, backend desplegado ni datos.
Se filtra el historial ya cargado por el MVP. No es una búsqueda paginada de servidor;
la optimización de grandes historiales sigue pendiente. Crear grupos, invitaciones,
cuotas, informes, notificaciones y exportaciones quedan para próximas entregas.

## Comprobaciones de esta entrega

`dart format` en los siete archivos Dart modificados/nuevos: correcto.

`flutter test --no-pub test/movement_history_test.dart test/dashboard_test.dart`:
cinco pruebas superadas (tres del historial y dos del Dashboard).

- Coincidencia combinada, búsqueda sin acentos y límites inclusivos por fecha
  efectiva, incluso con createdAt de otro mes.
- Preservación de estados/saldo y listas inmutables; rechazo de otro grupo
  aunque su fila no coincida con los filtros, rango inválido y referencias antiguas.
- Flujo visual de buscar, limpiar, aplicar, cancelar y actualizar por stream;
  foco por ID y estado separado por grupo, sin escrituras. 360 px, texto al 160 %,
  movimiento reducido y apertura del panel en temas oscuro/claro, sin excepciones.
- Regresión existente del Dashboard: cálculos y navegación, streams, errores,
  revocación y aviso con el margen de presentación acordado.

`flutter analyze --no-pub`: sin incidencias. `git diff --check`: correcto.

Se limita la comprobación a estos cinco casos, sin repetir la suite completa.
Se actualiza la aserción antigua del Dashboard al aviso y margen de
presentación acordados el 16; no se modifica su lógica financiera.
Sin compilación de APK (no hay cambios nativos), instalación, arranque ni validación
física. No se ejecutan emuladores de Rules porque no cambian reglas ni escrituras.

## Qué comprobar después en el móvil

Cuando el usuario ejecute la app: abrir Movimientos, buscar una persona o concepto,
aplicar/limpiar criterios y seguir un enlace de corrección. Esta es una comprobación
pendiente, no una prueba realizada. Los pendientes físicos del MVP permanecen en
ROADMAP y PHASE6_VALIDATION; no es necesario retomarlos para leer este informe.
