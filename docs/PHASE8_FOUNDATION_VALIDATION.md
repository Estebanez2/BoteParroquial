# Base de cuotas mensuales — 2026-10-19

Informe histórico del primer bloque. Las tres preguntas iniciales y otras dos
sobre cuota cero/versiones futuras se resuelven después en D077. Integración
posterior y estado vigente: [PHASE8_QUOTAS_PERIODS_VALIDATION.md](PHASE8_QUOTAS_PERIODS_VALIDATION.md).
No reabrir esas cinco preguntas por las menciones históricas que siguen.

Inicio acotado de Phase 8, siguiendo los apartados 18–25 del producto. La función
de cuotas todavía no está disponible en la app: esta entrega prepara su dominio
mientras se resuelven decisiones de aplicación expresamente preguntadas al usuario.

## Realizado

- YearMonth: mes civil inmutable, formato YYYY-MM, comparación y desplazamientos
  mensuales seguros entre años. Intervalo 2000–2100, coherente con las fechas de
  dominio actuales. No consulta el reloj del dispositivo ni aplica una zona propia.
- QuotaRule: importe en céntimos de una regla temporal perteneciente a un grupo.
  La regla se aplica desde su primer mes hasta la siguiente; la proyección no
  reescribe reglas históricas. Es modelo de dominio, no documento publicado.
- ParticipationPeriod: primer mes y último mes inclusivo opcional de una persona
  y grupo explícitos. Representa varios periodos con huecos, sin derivarlos de
  fecha de creación o estado actual. Aún no se conecta al flujo de inactivación.
- QuotaExpectationRepository: cálculo puro de importes esperados por mes, aislado
  de widgets, Firebase, Riverpod y movimientos. Valida grupo/persona, importes
  no negativos en céntimos, IDs únicos, reglas de inicio no duplicado y periodos
  sin solaparse. Ordena copias y devuelve resultados inmutables.
- Distingue participación sin configurar, mes sin precio, mes no computable y mes
  con precio. Sin periodos, el importe es desconocido e isComplete=false; no se
  interpreta como deuda cero. knownExpectedCents suma únicamente meses conocidos.

Ejemplo comprobado: cuota de 20,50 hasta junio y 25 desde julio, con participación
enero–mayo y septiembre en adelante. Esperado anual: 202,50; junio–agosto no computan.
No significa que falte pagar esa cantidad: no hay asignaciones/pagos en este cálculo.

El motor acepta un precio cero como valor aritmético; esta entrega no decide si
se ofrecerá como cuota configurable, exención o suspensión en la futura interfaz.
No se ofrece ninguna de esas opciones ni se modifica la política del grupo.

## Comprobado

- dart format en los seis archivos Dart nuevos.
- flutter test test/quota_expectation_test.dart: dos casos dirigidos superados.
  Meses/años/bisiesto, reglas sucesivas, huecos/reincorporación, céntimos exactos,
  entradas/resultados inmutables, configuración incompleta, duplicados,
  solapamientos e intentos de mezclar personas o grupos.
- flutter analyze: sin incidencias.
- Logs: .dart_tool/quota-foundation-tests.log y quota-foundation-analyze.log.

Sin suite completa, emulador ni nueva compilación APK: no cambian dependencias,
Android, UI o arranque; se comprueba directamente el dominio Dart afectado.
No se instala ni se ejecuta la app. Las pruebas físicas aplazadas siguen pendientes.

## Decisiones solicitadas, todavía pendientes

1. Cambios de cuota: desde el mes siguiente (recomendación) o permitir cambios
   retroactivos confirmados. La primera regla permitiría elegir su mes inicial.
2. Personas existentes: elegir expresamente el primer mes de cada persona
   (recomendación) o comenzar todas automáticamente en el mes actual.
3. Inactivación: elegir último mes computable, proponiendo el actual
   (recomendación), o cerrar siempre automáticamente al terminar el mes actual.

No se toma silencio por respuesta. Estas recomendaciones no están aceptadas.
No se construyen pantallas ni operaciones de escritura que dependan de ellas.
La decisión anterior sobre devoluciones y allocations elegidas (D064) permanece.

## Sin cambios remotos

Cero documentos de Firestore creados, editados o borrados; sin migración ni nuevos
ejemplos DEMO. Sin despliegue o cambio en firestore.rules, Authentication o Supabase.
El ruleset vigente sigue siendo el verificado en PHASE7_ROLES_TRANSFER_VALIDATION.md.
No se han generado deudas, periodos ni asignaciones para personas actuales.

## Continuación

Tras recibir las tres decisiones: contrato de persistencia y permisos, gestión de
reglas temporales/periodos, conexión UI → Provider → Repository → Service y cálculo
visible de importes esperados. Después: allocations, pagos parciales/atrasados/
adelantados, crédito y reversión de asignaciones en devoluciones. No sumar ingresos
a cuotas pagadas sin asignaciones explícitas. Notificaciones siguen en Phase 9.
