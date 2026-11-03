Reglas de código

Espacio de acciones: AppButton ya reserva su margen. Componer por tokens y no
duplicar separadores entre controles sin necesidad; conservar espacios de sección.
Los wrappers de animación deben propagar las restricciones del padre: la zona
pulsable ha de cubrir la superficie visible incluso en Expanded/etiquetas cortas.
No afirmar registro/envío/recepción como equivalentes en avisos. Resolver el
destinatario actual por la cuenta/grupo que indique el usuario, no por nombres
visibles iguales ni UID DEMO históricos. No imprimir tokens para diagnosticar.

Alta con cuota: usar InitialQuotaAssignment y un commit único del servicio.
Validar antes de escribir journal; recuperar ambos testigos antes de limpiarlo.
No inferir cuota por fecha efectiva ni ejecutar una segunda escritura desde UI.
El ID del intento y su reparto se mantienen en reintentos, sin duplicar dinero.

Navegación de grupo: no construir nuevas features ni iniciar sus suscripciones
dentro del deslizamiento; reutilizar AppDeferredSection y esqueletos compartidos.
No usar keepAlive/caché persistente para ocultar tirones. Cualquier congelación de
pantalla exige invalidación reactiva de cuenta/permisos fuera del árbol pausado,
y liberación al acabar/desmontar. Respetar visor aislado y movimiento reducido.
Los tiempos de widgets/build no acreditan fluidez física; medir en profile.

Animaciones elegidas: reutilizar AppControlFeedback/AppButton.validate; no
validar automáticamente toda acción por encontrar un Form, ni animar envíos
ocupados como si fueran reintentos. B04/B05 nunca conceden acción/permisos.
AppGroupOrigin y los índices de AppSectionMotionScope son solo geometría/estado
visual efímero, no datos persistidos. Alojar paneles mediante el contexto modal
de AppNavigationHost, sin escapar del ProviderContainer de una copia.

Carga/apariencia: componer AppSkeleton/AppShimmer sin inventar datos ni animar
cifras financieras. Conservar fotos disponibles y respetar movimiento reducido.
Fuentes y contraste de paletas propias se derivan en AppTheme/AppTypography,
no en features. RGB de colores son enteros del modelo visual, sin relación con
céntimos. AppThemePreview usa App* y no dispara acciones de dominio. Apariencia
v2 local lee preferencias anteriores; mantener ID al editar y fuente/modo al
eliminar. Menús compartidos no resuelven permisos ni llaman a SDKs.

Copias locales: solo lectura del ámbito de cuenta, readTime consistente, int64 y
timestamps originales. No publicar capturas parciales, mezclar caché/servidor/copia,
ni permitir escrituras porque la membresía archivada tenía rol admin. Separar el
contenedor de consulta y denegar SDKs/operaciones, además de ocultar acciones.
El reloj de cálculo se congela al instante del archivo. Clave por UID en almacenamiento
seguro, nunca junto al contenido; JSON/cifrado fuera de UI mediante isolate. Limpiar
por sesión con generación y verificar el destino antes de borrado recursivo.

Ampliación 2026-10-20: agregados REST de dinero deben aceptar exclusivamente
`integerValue` int64 y detectar desbordamiento; no convertir `sum()` flotante a
céntimos mediante redondeo. Mantener un readTime coherente entre sumas y mostrar
fecha de confirmación; caché temporal por cuenta, purgada al salir, no respaldo.
No presentar caché como confirmación actual ni leer todo el historial para la caja.

Exportaciones: revalidar sesión/rol antes de compartir; datos inmutables al generar
en isolate. Escapar XML, neutralizar fórmulas CSV y usar texto exacto para enteros
que Excel no puede representar sin pérdida. No truncar filas/celdas silenciosamente.

Ciclo de vida: no usar borrado ordinario para historia económica. Papelera solo
para personas protegidas y sin historia, periodos ni vínculo; plazo validado por
servidor. Borrar grupo es excepción irreversible y explícita con Google/nombre.
Conservar progreso ante interrupciones y ampliar su registro de subcolecciones al
añadir datos. Baja propia conserva la historia de otros grupos. Intención de foto
y confirmación son eventos distintos; no fingir atomicidad Storage/Firestore.

Idioma

Código:

inglés

Interfaz visible:

español

Nombres

Archivos:

snake_case.dart

Clases y enums:

UpperCamelCase

Variables, métodos y campos Firestore:

lowerCamelCase

Ejemplos:

movement_repository.dart

MovementRepository

amountCents

Dart

Mantener null safety.

Cuotas: YearMonth para meses civiles de dominio y ordinal entero solo en la
adaptación Firestore documentada. No inferir periodos de createdAt/isActive ni
pagos de ingresos sin allocations. monthlyFeeCents admite cero según D077;
los importes de movimientos siguen positivos. Configuración desconocida no es cero.

Preferir:

final
const

cuando corresponda.

Evitar:

dynamic
!

salvo situaciones justificadas.

Los modelos deben ser preferentemente inmutables.

Dinero

Nunca utilizar double para persistencia o cálculos financieros.

20,50 € = 2050

Persistir:

int amountCents

El importe de un movimiento siempre es positivo.

Las asignaciones mensuales usan amountCents >= 0: 0 libera el reparto sin borrar
historia. No son movimientos y nunca cambian el saldo del bote. Una asignación
solo paga meses mientras su ingreso fuente esté active. Ajustes absolutos,
versionados y transaccionales, nunca incrementos implícitos que dupliquen al reintentar.
Deuda de configuración incompleta es desconocida, no cero.

Las devoluciones son withdrawals positivos con RefundPlan explícito. Nunca
inferir devolución de la descripción ni alterar cuotas por una retirada normal.
Conservar reparto bruto y descontar solo devoluciones active al proyectar pagos.
Crédito libre = ingreso - reparto bruto - devuelto total + devuelto de cuotas.
No liberar el importe de cuotas ya devuelto para repartirlo otra vez. Confirmar
reparto y movimiento juntos mediante servicio y Rules, con auditoría inmutable.
Al anular se restaura el cómputo; al corregir se revisa el sustituto, sin copiarlo
automáticamente. Hasta cuatro meses distintos entre original y sustituto.
Conservar en el journal el plan completo de ambos, con ID/actor y versión 2.

Informes de cuotas: separar cobros por fecha efectiva de pagos por mes asignado.
El pendiente del periodo llega como máximo al mes actual del grupo; futuro es
previsión. Porcentaje de cumplimiento suma cobertura limitada a cada cuota de
cada persona/mes, no divide sin más todo lo ingresado entre lo esperado. Un
sobrepago no compensa otra obligación. Sin configuración o con esperado cero,
no inventar un porcentaje. Ratios enteros, con BigInt para evitar desbordamientos
intermedios; no usar double para calcular importes. El estado mostrado incorpora
pagos/devoluciones posteriores, sin afirmar cierre contable inmutable.

Comparaciones (D103): periodo en curso contra el mismo tramo civil del anterior,
con corte diario para caja y meses completos para cuotas. Periodos terminados
completos. Mostrar fechas; ajustar al último día cuando el mes previo sea más
corto. Diferencia de cumplimiento en puntos porcentuales, no crecimiento relativo.
No dividir por bases cero/desconocidas ni calcular reglas financieras en widgets.

El tipo indica el signo lógico:

income
withdrawal

No mezclar:

withdrawal + importe negativo

Entrada de cantidades

No utilizar simplemente:

double.parse(valor) * 100

Interpretar la entrada decimal de forma segura y convertirla a unidades enteras.

Aceptar como máximo los decimales admitidos por la moneda.

Para EUR:

máximo 2 decimales

Fechas

Dominio:

DateTime

Persistencia:

Firestore Timestamp

Metadatos como:

createdAt
updatedAt

deben utilizar hora del servidor cuando sea posible.

Separar:

occurredAt

fecha efectiva elegida para el movimiento,

de:

createdAt

momento real en que se registró.

Errores

No mostrar directamente errores técnicos de Firebase al usuario.

Capas:

Service
    interpreta error técnico

Repository
    lo transforma al dominio

Provider
    expone estado

UI
    muestra mensaje comprensible

Conservar información técnica útil para depuración sin mostrar:

tokens;

credenciales;

datos internos sensibles.

Asincronía

Esperar escrituras importantes:

await

Evitar dobles envíos mientras una operación está en progreso.

Conservar la intención económica antes de enviarla, separada por UID/grupo, y
comprobar resultados inciertos en servidor. Un reintento conserva ID y datos;
no borrar/sobrescribir otro pendiente ni reenviar automáticamente al abrir la app.
Limpiar el intento local solo por confirmación coincidente o descarte explícito.
«Hoy» se obtiene del calendario del grupo; no calcularlo directamente en widgets.

Después de un await, comprobar context.mounted antes de utilizar un BuildContext.

Persistencia

Paginación de auditoría: cursor con segundos/nanosegundos e ID ligado al grupo;
no convertir a DateTime antes de guardar la posición. Validar orden, duplicados
y alcance de cada página. No mezclar una cabecera móvil con páginas antiguas ni
presentar caché incompleta como final del historial. Revisar UID/permisos después
de cada await y descartar respuestas de una consulta anterior.

No cambiar nombres de campos Firestore sin plan de migración.

No borrar movimientos económicos.

No borrar personas con historial económico.

No permitir escrituras financieras parciales cuando una operación requiera varios cambios relacionados.

Cuando llegue la fase financiera, usar transacciones o batches cuando corresponda.

Calidad

Después de cambios Dart:

dart format lib test
flutter analyze
flutter test

Añadir pruebas especialmente para:

dinero;

permisos;

transiciones de estados;

fechas;

cálculos;

aislamiento entre grupos.

Reglas visuales

Usar los componentes de lib/design_system/design_system.dart en nuevas pantallas.
Consultar DESIGN_SYSTEM.md y buscar un componente equivalente antes de añadir otro.
No fijar Color(0xFF...), TextStyle, padding, radio o sombras arbitrarios en features.
Resolver AppColors y AppTypography desde el contexto; usar AppSpacing y AppRadius.
Envolver componentes externos complejos en App* cuando corresponda.
Los widgets específicos de feature reutilizan el Design System y permanecen en su feature.
No mezclar enums visuales de StatusChip con roles o estados de persistencia.
MoneyText y AppMoneyField solo presentan/convierten enteros: no calculan saldo,
validan permisos ni deciden la validez financiera de una operación.
Probar claro/oscuro, texto ampliado, interacción y movimiento reducido cuando se
cambien controles compartidos. No considerar aprobada la estética solo por compilar.
