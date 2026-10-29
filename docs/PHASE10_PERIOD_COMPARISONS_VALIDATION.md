# Comparaciones de informes — 2026-10-20

Continuación acotada del producto completo, apartados 59–63. No cierra todo el
producto ni acredita las pruebas móviles pendientes. El usuario ejecuta la app.

## Entregado

En grupo → Informes → «Comparar con el periodo anterior», la selección existente
de mes/trimestre/año muestra ambos tramos con fechas explícitas y:

- Ingresos, retiradas y neto de caja, con importes actuales, anteriores y diferencia.
- Cuota esperada, pagos asignados netos y pendiente de cuota.
- Cumplimiento de cada tramo y diferencia en puntos porcentuales.
- Variación relativa para importes con base anterior positiva. Sin dividir por
  cero ni inventar un porcentaje sobre una base cero, negativa o desconocida.
  El neto de caja solo muestra diferencia absoluta, no crecimiento relativo.

D103: el usuario elige **mismo tramo transcurrido** para periodos en curso.
Ejemplos: 1–20 de octubre frente a 1–20 de septiembre; cuarto trimestre hasta
20 de octubre frente al tercero hasta 20 de julio; año hasta 20 de octubre frente
al anterior hasta esa fecha. Si el mes de destino es más corto, se usa su último
día; 29 de febrero frente a 28 de febrero en el año anterior no bisiesto.
Los periodos ya terminados comparan sus intervalos completos.

«Hoy» es fecha civil de la zona del grupo, recibida del repositorio de calendario.
Caja incluye el día actual y excluye los días posteriores al corte, movimientos
cancelled y corrected. Las retiradas incluyen devoluciones active como en el
informe económico existente. El neto del tramo es ingresos menos retiradas;
no se presenta como saldo acumulado del bote.

Cuotas conserva D088–D090: cada mes computable se cuenta completo, sin prorrateo
diario, con pagos/devoluciones actualizados hasta hoy en ambos lados. Para un
trimestre/año parcial, solo se incluyen los meses hasta el corte equivalente;
meses futuros se quedan en la previsión del informe principal, fuera de esta
comparación. Comparar pagos de mayo no reconstruye lo conocido el 15 de mayo:
un atraso de junio asignado a mayo sigue contando y una devolución lo reduce.
Sobrepagos no compensan obligaciones ajenas y cobertura no supera el 100 %.

Configuración incompleta conserva esperado/pendiente/cumplimiento desconocidos.
Los pagos asignados conocidos pueden seguir mostrándose. Esperado cero no crea
un 100 %. No hay comparación de hechos para periodos futuros ni cuando el anterior
queda antes del límite 2000; la pantalla explica que se elija otro periodo.
No se califica automáticamente una subida de retiradas o pendiente como mejora.

## Arquitectura y coste

ReportComparisonSection → reportComparisonProvider → ReportComparisonRepository →
EconomicReportRepository / QuotaReportRepository → datos ya compartidos por los
providers y sus servicios. El modelo es Dart puro; los widgets solo presentan.
No abre consultas adicionales para comparar ambos lados. El bloque desplegable
monta su consumidor al abrirse, evitando calcularlo si no se consulta.
Sin nuevas dependencias ni componentes paralelos: AppExpandableRow, AppReveal,
AppHeroPanel, AppCard y AppAdaptiveRow respetan tokens y movimiento reducido.

EconomicReportRepository admite un corte civil opcional; sin corte mantiene el
periodo completo existente. Sus sumas y saldo derivado se comprueban exactamente
con BigInt antes de devolver enteros; diferencias y ratios tampoco usan double.
QuotaReportRepository combina meses ya proyectados con las mismas reglas de
pagos, sobrepagos y devoluciones, sin duplicar esas reglas en la UI.

Sin cambios de esquema, permisos, Rules, índices, SDK o despliegues remotos.
Cero documentos creados/modificados/borrados. No se ejecutan suites de Rules ni
se crea otro respaldo remoto: no hay publicación o cambio de seguridad/datos.
La copia externa de la entrega de notificaciones permanece intacta.

## Evidencia

Cinco casos distintos dirigidos, sin suite general:

- Tres casos de `report_comparison_test.dart`: diferencias enteras/ratios grandes
  y bases cero/negativas/desconocidas; mes/trimestre/año, fronteras y bisiestos;
  caja frente a cuotas con devoluciones, cortes, anulaciones, grupos ajenos,
  configuración incompleta y detección de desbordamiento.
- Un flujo ampliado de `quota_report_flow_test.dart`: abrir comparación de mayo,
  cambiar al año parcial y comprobar cortes; ambos temas, 360 px, texto 160 % y
  movimiento reducido; mantiene una lectura de periodos y otra de asignaciones;
  los cambios compartidos actualizan datos y la pérdida de acceso retira contenido.
- Una regresión existente de `full_product_progress_test.dart`, «Informes»:
  saldos, mes/trimestre/año, estados e aislamiento, tras ampliar el repositorio.

Un dato simulado inicialmente incompatible con su devolución se corrigió; no se
cuenta como prueba superada. Se repiten solo los casos afectados por ese ajuste
y por aplicar la decisión D103. Un análisis intermedio durante esa adaptación
detectó referencias antiguas de pruebas; corregidas antes de la verificación final.

Formato aplicado a archivos afectados. Análisis final sin incidencias (5,4 s).
Los cuatro casos nuevos/ampliados pasan juntos tras D103; la regresión anterior
también pasó. Logs ignorados: `.dart_tool/report-comparisons-*.log`.
APK debug compilado correctamente (23,2 s), sin instalación ni arranque. El plugin
mantiene advertencias de migración Kotlin; no impiden la compilación.

Archivo: `build/app/outputs/flutter-apk/app-debug.apk`, 242.958.814 bytes.
SHA-256: `812d9a3b2ba4b486fc0247eebf839812761ecbc04546d017d48f671ac5edb292`.

## Revisión manual pendiente

Entrar en Informes, elegir mes/trimestre/año y desplegar «Comparar con el periodo
anterior». Revisar fechas de ambos lados y distinguir caja de cuotas. Seleccionar
un periodo pasado, el actual, uno futuro y una cuota incompleta. Un cambio o
anulación posterior debe actualizar el informe histórico, sin afirmar cierre.
La [guía móvil](GUIA_PRUEBAS_MOVILES.md) incorpora estos pasos.

Siguen pendientes: agregados/paginación para volumen, otras ampliaciones de
informes individuales, auditoría general/papelera/eliminación segura, PDF/Excel y
exportaciones grandes. Push, enlaces físicos, varias cuentas e iOS mantienen los
pendientes de sus informes; no se reanudan ni se dan por aprobados aquí.
