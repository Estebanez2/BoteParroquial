import 'year_month.dart';

final class RefundPart {
  const RefundPart({required this.month, required this.amountCents});
  final YearMonth month;
  final int amountCents;
}

/// A withdrawal's explicit return of money from one income, independent of UI/SDK.
final class RefundPlan {
  RefundPlan({
    required this.incomeId,
    required this.unallocatedCents,
    required Iterable<RefundPart> parts,
  }) : parts = List.unmodifiable(
         List<RefundPart>.of(parts)..sort((a, b) => a.month.compareTo(b.month)),
       );
  final String incomeId;
  final int unallocatedCents;
  final List<RefundPart> parts;
  int get assignedCents => parts.fold(0, (sum, p) => sum + p.amountCents);
  int get amountCents => unallocatedCents + assignedCents;
  int atMonth(YearMonth month) =>
      parts.where((p) => p.month == month).firstOrNull?.amountCents ?? 0;
  bool sameAs(RefundPlan? other) =>
      other != null &&
      incomeId == other.incomeId &&
      unallocatedCents == other.unallocatedCents &&
      parts.length == other.parts.length &&
      parts.every((p) => p.amountCents == other.atMonth(p.month));
  Map<String, Object?> toMap() => {
    'incomeId': incomeId,
    'unallocatedCents': unallocatedCents,
    'parts': {for (final p in parts) '${p.month.ordinal}': p.amountCents},
  };
  static RefundPlan? fromMap(Object? value) {
    if (value == null) return null;
    if (value is! Map ||
        value['incomeId'] is! String ||
        value['unallocatedCents'] is! int ||
        value['parts'] is! Map) {
      throw const FormatException('Plan de devolución no válido.');
    }
    final parts = <RefundPart>[];
    for (final part in (value['parts'] as Map).entries) {
      final month = part.key is String ? int.tryParse(part.key) : null;
      if (month == null ||
          '$month' != part.key ||
          month < 24000 ||
          month > 25211 ||
          part.value is! int ||
          part.value <= 0) {
        throw const FormatException('Parte de devolución no válida.');
      }
      parts.add(
        RefundPart(
          month: YearMonth(month ~/ 12, month % 12 + 1),
          amountCents: part.value,
        ),
      );
    }
    final plan = RefundPlan(
      incomeId: value['incomeId'],
      unallocatedCents: value['unallocatedCents'],
      parts: parts,
    );
    if (plan.incomeId.isEmpty ||
        plan.incomeId.contains('/') ||
        plan.unallocatedCents < 0 ||
        plan.parts.length > 4 ||
        plan.parts.map((p) => p.month).toSet().length != parts.length ||
        plan.amountCents <= 0 ||
        plan.amountCents > 99999999999999) {
      throw const FormatException('Importe de devolución no válido.');
    }
    return plan;
  }
}
