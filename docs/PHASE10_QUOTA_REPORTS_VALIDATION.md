# Dashboard e informes de cuotas — 2026-10-19

Implementación terminada dentro del alcance de este bloque. El usuario elige
completar estos resúmenes antes de notificaciones (D087), con estado actualizado
de pagos/devoluciones hasta hoy (D088) y previsión futura separada (D089).
No completa todo el producto ni las comprobaciones físicas pendientes del MVP.

## Entregado

- Inicio de grupo: pendiente acumulado hasta el mes actual, estados de personas,
  cuota esperada/asignado neto/pendiente del mes e ingresos/retiradas de ese mes.
  Distingue caja por fecha efectiva de cuotas por mes asignado.
- Informes: misma selección de mes/trimestre/año, resumen de cuotas del periodo
  hasta el mes actual, porcentaje de cumplimiento y sobrepago conocido.
- Meses futuros: bloque de previsión aparte, con esperado/pagos/importe previsto
  aún por cubrir. No se suma a pendiente actual ni se presenta como atraso.
- Evolución mensual desplegable, con barras accesibles de esperado conocido y
  cuota cubierta, y pendiente o previsión pendiente por mes. Marca meses incompletos.
- Detalle por persona, estados y vínculo a su ficha. Incluye personas inactivas
  conforme a su historia de participación, sin generar meses por isActive/createdAt.
- Crédito actual sin asignar y asignado a meses futuros del conjunto del grupo,
  identificado como estado global actual, distinto del periodo seleccionado.
- Pagos atrasados posteriores actualizan el mes asignado; devoluciones active
  descuentan pagos, y anular/corregir usa las reglas ya entregadas. No guarda ni
  reconstruye cierres contables de otra fecha.
- Cobertura por obligación: min(cuota, pago neto) por persona/mes antes de sumar.
  Sobrepago no compensa otros meses/personas. Ratio entero en puntos básicos y
  representación a una décima; BigInt evita desbordamiento intermedio.
- Configuración incompleta: esperado conocido es subtotal, pendiente/porcentaje
  quedan sin determinar. Cuota esperada cero no inventa 100 % ni persona pagada.
  Se diferencian al día, parcial, pendiente, sin configurar y sin cuota computable.

## Cambios técnicos

QuotaReportSection → quota_report_providers → QuotaReportRepository →
GroupQuotaService / FirestoreGroupQuotaService. Modelos puros en quota_report.dart.
El repository valida grupo/integridad, agrupa por persona y compone la proyección
existente; no se duplican las reglas de pagos/devoluciones en widgets.

Dos streams de contenido de grupo para participationPeriods/allocations, compartidos
por dashboard e informes. Se reutilizan personas/reglas/movimientos/reloj. Cambiar
selección no abre una consulta por persona. La ficha individual conserva consultas
acotadas previas. Adaptadores SDK comparten los mismos parseadores de periodos y
asignaciones; no se usan auditEvents ni allocationBalances como pagos agregados.

QuotaSettlementRepository admite ampliar su rango de proyección para cubrir los
meses seleccionados antes de la primera participación. Sus valores por defecto,
asignaciones y devoluciones se conservan. El informe de un mes anterior a una
etapa explícita conoce que no era computable; sin etapas sigue siendo incompleto.
Sumas agregadas detectan desbordamiento en lugar de presentar importes envueltos.

La pérdida de membresía retira contenido y las lecturas nuevas devuelven listas
vacías. Se corrigió el selector de informes existente, que lanzaba un error al
reconstruirse sin grupo durante una revocación. Usa una selección inerte mientras
el acceso falta; la pantalla/proyección no la utiliza como informe válido.
La prueba verifica contenido retirado y lecturas vacías, no una cancelación
instantánea de todos los listeners del SDK ni una prueba remota de permisos.

No se añaden dependencias, API, índices, colecciones, campos ni escrituras. No
cambia Firestore Rules y no se despliega Firebase/Supabase. Se conserva la fuente
local de reglas de devoluciones, SHA-256:
5c776e8d4b9b965ca4fe19a9e14f3564378e5461767a69c59d628098e20c3520.
Su última publicación/verificación está en PHASE8_REFUNDS_VALIDATION.md; en esta
entrega solo se comprueba el hash local, sin afirmar otra verificación remota.
El respaldo externo anterior de código/reglas/APK permanece intacto. No se crea
otra copia porque no hay nuevo despliegue ni cambios de datos.

## Comprobaciones realizadas

15 casos distintos dirigidos aprobados, sin suite completa:

- quota_reports_test: 3. Mes/trimestre/año, futuro separado, pagos posteriores,
  personas inactivas, devoluciones y sustitutos, crédito, sobrepago, cuota cero,
  periodo anterior a primera etapa, configuración incompleta, grupo incorrecto,
  persona ausente y porcentaje con importes grandes.
- quota_report_flow_test: 1 flujo. Dashboard → informe anual → detalle mensual y
  persona; comparte streams al cambiar periodo; datos actualizados sin consultas
  nuevas; membresía revocada retira cifras y entrega listas vacías. Ambos temas,
  360 px, texto 160 % y movimiento reducido, sin excepciones de renderizado.
- quota_allocations_test: 4 y refunds_test: 4. Regresiones necesarias porque se
  amplía la proyección compartida; confirma sus reglas previas y recuperación.
- Regresiones seleccionadas de dashboard_test (2) y full_product_progress_test
  (1, «Informes»): caja, periodos y aislamiento existentes.

Se corrigieron fallos iniciales de sintaxis/estilo y el caso de revocación; las
iteraciones fallidas no se cuentan como aprobadas. Una expectativa inicial de
cancelación inmediata de listeners se sustituyó por la comprobación observable
de acceso (UI retirada/lecturas vacías). Solo se repitieron los casos afectados.

- dart format de archivos afectados y flutter analyze --no-pub: sin incidencias.
- flutter build apk --debug --no-pub: aprobado, APK en
  build/app/outputs/flutter-apk/app-debug.apk.
- git diff --check: sin errores de espacios; no se cambian finales de línea a la fuerza.
- No se ejecutan suites de Rules: la fuente/permisos no cambian. No son pruebas
  de conexión real, otros roles reales ni sincronización entre móviles.

Logs ignorados en .dart_tool: quota-reports-tests.log, quota-report-flow.log,
quota-reports-regressions.log, quota-reports-analyze-final.log,
quota-reports-build.log y quota-reports-whitespace.log.

## Datos remotos y pendientes

Cero documentos remotos creados/modificados/borrados, sin nuevas DEMO ni migración.
No se instala ni arranca la app; el usuario lo hará. Google físico, segunda cuenta,
dos móviles e iOS siguen pendientes según los informes anteriores. No se reanudan.

Guía de revisión pendiente: entrar en el grupo, consultar acumulado/mes, abrir
«Ver informe de cuotas», elegir mes/trimestre/año y desplegar meses/personas.
Probar un pago atrasado y una devolución para ver cambiar su mes de cuota y
comprobar que los meses futuros permanecen separados. Esto no es evidencia móvil.

Siguen pendientes del producto completo: notificaciones/recordatorios y su
backend, enlaces de invitación con dominio real, comparaciones entre periodos,
agregados/optimización para volumen, auditoría general/papelera/eliminación segura,
PDF/Excel/exportaciones grandes. CSV actual exporta movimientos, no este informe
de cuotas. Los informes usan los datos completos del grupo, sin agregados remotos;
no se afirma que esa estrategia sea adecuada para cualquier volumen.

Referencia de estado general: ROADMAP.md. No interpretar este informe como cierre
de Phase 9, de la validación física del MVP o de todo Phase 10.
