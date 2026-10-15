Reglas de código

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

El importe siempre es positivo.

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

Después de un await, comprobar context.mounted antes de utilizar un BuildContext.

Persistencia

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
