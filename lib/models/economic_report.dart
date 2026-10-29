import 'movement.dart';
import 'person.dart';

enum ReportPeriod { month, quarter, year }

class ReportSelection {
  const ReportSelection({
    required this.year,
    required this.month,
    this.period = ReportPeriod.month,
  });
  final int year, month;
  final ReportPeriod period;
  int get startMonth => switch (period) {
    ReportPeriod.month => month,
    ReportPeriod.quarter => ((month - 1) ~/ 3) * 3 + 1,
    ReportPeriod.year => 1,
  };
  int get monthCount => switch (period) {
    ReportPeriod.month => 1,
    ReportPeriod.quarter => 3,
    ReportPeriod.year => 12,
  };
}

class MonthEconomics {
  const MonthEconomics({
    required this.month,
    required this.incomeCents,
    required this.withdrawalCents,
  });
  final DateTime month;
  final int incomeCents, withdrawalCents;
}

class PersonEconomics {
  const PersonEconomics({
    required this.personId,
    required this.name,
    required this.isActive,
    required this.incomeCents,
    required this.withdrawalCents,
  });
  final String? personId;
  final String name;
  final bool isActive;
  final int incomeCents, withdrawalCents;
  int get netCents => incomeCents - withdrawalCents;
}

class EconomicReport {
  const EconomicReport({
    required this.start,
    required this.endExclusive,
    required this.openingCents,
    required this.incomeCents,
    required this.withdrawalCents,
    required this.months,
    required this.persons,
    required this.activeMovementsCount,
  });
  final DateTime start, endExclusive;
  final int openingCents, incomeCents, withdrawalCents, activeMovementsCount;
  final List<MonthEconomics> months;
  final List<PersonEconomics> persons;
  int get closingCents => openingCents + incomeCents - withdrawalCents;
}

class PersonFinancialSummary {
  const PersonFinancialSummary({
    required this.person,
    required this.incomeCents,
    required this.withdrawalCents,
    required this.movements,
  });
  final Person person;
  final int incomeCents, withdrawalCents;
  final List<Movement> movements;
  int get netCents => incomeCents - withdrawalCents;
}
