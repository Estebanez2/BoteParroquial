import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../layout/app_adaptive_row.dart';
import 'app_dropdown.dart';

/// Calendar presentation only; callers decide which months are permitted.
class AppMonthField extends StatelessWidget {
  const AppMonthField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.label = 'Mes',
    this.firstYear = 2000,
    this.lastYear = 2100,
  });
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;
  final String label;
  final int firstYear, lastYear;
  @override
  Widget build(BuildContext context) => AppAdaptiveRow(
    children: [
      AppDropdown<int>(
        label: label,
        value: value.month,
        options: {
          for (var m = 1; m <= 12; m++)
            m: DateFormat.MMMM(
              Localizations.localeOf(context).toLanguageTag(),
            ).format(DateTime(2000, m)),
        },
        onChanged: enabled
            ? (m) {
                if (m != null) onChanged(DateTime.utc(value.year, m));
              }
            : null,
      ),
      AppDropdown<int>(
        label: 'Año',
        value: value.year,
        options: {for (var y = firstYear; y <= lastYear; y++) y: '$y'},
        onChanged: enabled
            ? (y) {
                if (y != null) onChanged(DateTime.utc(y, value.month));
              }
            : null,
      ),
    ],
  );
}
