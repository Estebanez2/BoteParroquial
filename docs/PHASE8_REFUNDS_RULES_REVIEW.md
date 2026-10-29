# Revisión de reglas de devoluciones — 2026-10-19

Estado final: el usuario autorizó expresamente crear otro respaldo del estado
actual, incorporar, publicar y validar. Respaldo creado, reglas incorporadas,
publicadas y verificadas. No queda aprobación pendiente. Informe final:
PHASE8_REFUNDS_VALIDATION.md. El resto conserva el registro de la propuesta.

La revisión automática rechazó sustituir `firestore.rules` y la prueba de
devoluciones por los candidatos completos: considera que el alcance de seguridad
persistente no está suficientemente autorizado y que los casos locales no
demuestran conservar toda la seguridad previa. No se ha eludido ese rechazo.

Archivos concretos para revisar, dentro del directorio ignorado `.dart_tool`:

- `refunds-candidate.rules`: propuesta de reglas completa.
- `refunds-candidate.test.cjs`: casos del contrato de devolución.
- `refunds-candidate-restored.log`: última ejecución, cuatro casos aprobados.

Contrato de esta propuesta:

- Un ingreso de origen por devolución; máximo cuatro meses y crédito sin asignar.
- `refund.parts` es un mapa de mes ordinal canónico a céntimos; claves únicas.
- `changes` contiene todas las claves afectadas, sin duplicados. El evento
  verifica que cubra tanto el reparto anterior como el sustituto.
- El movimiento, su evento de auditoría inmutable y el contador del ingreso se
  escriben juntos. El evento exige las transiciones y el contador; el contador y
  los movimientos exigen el evento nuevo del mismo actor y tiempo de servidor.
- Se mantienen comprobaciones explícitas de persona, ingreso y mes en cada
  asignación consultada, junto con actor, permisos y tiempo de servidor.
- Para no exceder el presupuesto de evaluación por escritura, el contador valida
  meses 0/1; el evento, el mes 2; el movimiento destino (o anulado), el mes 3.
  Todas esas escrituras son obligatorias en el mismo commit.
- Las asignaciones conservan sus importes brutos. El contador registra devoluciones
  activas totales, de cuotas y por mes; no permite devolver más de lo disponible.
- Anular restaura el cómputo; corregir restaura el original y aplica expresamente el
  sustituto, con como máximo cuatro meses distintos en la unión.
- No se permite anular/corregir el ingreso mientras tenga devoluciones activas.
- Las reglas previas de grupos, personas, roles y cuotas se conservan; hay además
  cambios locales de creación opcional de persona con primer periodo atómico.

Evidencia provisional: cuatro casos de emulador aprobados (parciales/crédito,
denegaciones y atomicidad, cuatro meses con admin al crear/corregir/anular,
concurrencia). Incluyen manipulaciones de mapas, importes y fechas.
Después se aprobaron las 14 regresiones de asignaciones/movimientos/cuotas,
análisis y compilación final. La ejecución final del contrato usa firestore.rules
directamente, con controles restaurados, tras la autorización y copia. Esto no
acredita dispositivo, otros roles reales ni iOS.

La condición de autorización anterior se satisfizo expresamente. Fuente final,
publicación remota, hashes y respaldo constan en PHASE8_REFUNDS_VALIDATION.md.
