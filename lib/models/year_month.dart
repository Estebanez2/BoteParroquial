/// Civil month, independent of the device's timezone and of an instant in time.
final class YearMonth implements Comparable<YearMonth> {
  YearMonth(this.year, this.month) {
    if (year < 2000 || year > 2100 || month < 1 || month > 12) {
      throw ArgumentError('Mes fuera del intervalo 2000–2100.');
    }
  }
  factory YearMonth.fromDate(DateTime date) => YearMonth(date.year, date.month);
  factory YearMonth.parse(String value) {
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(value)) {
      throw FormatException('El mes debe tener formato YYYY-MM.', value);
    }
    return YearMonth(
      int.parse(value.substring(0, 4)),
      int.parse(value.substring(5)),
    );
  }
  final int year, month;
  int get ordinal => year * 12 + month - 1;

  /// For presentation/civil-date interoperability, never a local timezone instant.
  DateTime get firstDayUtc => DateTime.utc(year, month);
  YearMonth addMonths(int count) {
    final next = ordinal + count;
    return YearMonth(next ~/ 12, next % 12 + 1);
  }

  @override
  int compareTo(YearMonth other) => ordinal.compareTo(other.ordinal);
  bool isBefore(YearMonth other) => compareTo(other) < 0;
  bool isAfter(YearMonth other) => compareTo(other) > 0;
  @override
  bool operator ==(Object other) =>
      other is YearMonth && year == other.year && month == other.month;
  @override
  int get hashCode => Object.hash(year, month);
  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}
