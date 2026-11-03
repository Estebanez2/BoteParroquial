import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/initial_quota_assignment.dart';
import '../../../models/year_month.dart';
import '../providers/allocation_providers.dart';
import '../providers/quota_providers.dart';

class InitialQuotaPicker extends ConsumerStatefulWidget {
  const InitialQuotaPicker({
    super.key,
    required this.groupId,
    required this.personId,
    required this.incomeCents,
    required this.currency,
    this.initial,
  });
  final String groupId, personId, currency;
  final int incomeCents;
  final InitialQuotaAssignment? initial;
  @override
  ConsumerState<InitialQuotaPicker> createState() => _InitialQuotaPickerState();
}

class _InitialQuotaPickerState extends ConsumerState<InitialQuotaPicker> {
  final _guard = GlobalKey<AppFormGuardState>();
  late YearMonth _month;
  late final TextEditingController _amount;
  late final String _initialText;
  late final YearMonth _initialMonth;
  String? _error;
  bool _reviewing = false;
  @override
  void initState() {
    super.initState();
    _month =
        widget.initial?.month ?? ref.read(quotaMonthProvider(widget.groupId));
    final cents = widget.initial?.amountCents ?? widget.incomeCents;
    _initialText =
        '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';
    _initialMonth = _month;
    _amount = TextEditingController(text: _initialText);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    if (_reviewing) return;
    setState(() => _reviewing = true);
    try {
      final review = ref
          .read(allocationControllerProvider(widget.groupId).notifier)
          .reviewInitial(
            widget.personId,
            _month,
            parseMoneyCents(_amount.text),
            widget.incomeCents,
          );
      if (review.overpaymentCents > 0 || review.expectedCents == null) {
        final confirmed = await AppDialog.show(
          context,
          title: 'Revisar cuota del mes',
          description: review.expectedCents == null
              ? 'Este mes no tiene una cuota configurada. Podrás registrar el pago, pero su cumplimiento quedará sin determinar.'
              : 'Este mes quedará con un sobrepago de ${formatMoneyCents(review.overpaymentCents, currency: widget.currency)}. No cubrirá otros meses automáticamente.',
          confirmLabel: 'Usar este reparto',
          variant: AppDialogVariant.warning,
        );
        if (!mounted || !confirmed) return;
      }
      if (!mounted) return;
      _guard.currentState?.saved();
      Navigator.of(context).pop(review.assignment);
    } catch (error) {
      if (mounted) setState(() => _error = failureMessage(error));
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settlement = ref.watch(
      personQuotaSettlementProvider((widget.groupId, widget.personId)),
    );
    final periods = ref.watch(
      participationPeriodsProvider((widget.groupId, widget.personId)),
    );
    final rules = ref.watch(quotaRulesProvider(widget.groupId));
    final ready =
        !settlement.isLoading &&
        settlement.hasValue &&
        !settlement.hasError &&
        !periods.isLoading &&
        periods.hasValue &&
        !periods.hasError &&
        !rules.isLoading &&
        rules.hasValue &&
        !rules.hasError;
    return AppFormGuard(
      key: _guard,
      busy: _reviewing,
      changes: _amount,
      isDirty: () => _amount.text != _initialText || _month != _initialMonth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'El ingreso y esta cuota se guardarán juntos. El resto quedará recibido, sin asignar. Puedes cambiar el reparto después.',
            style: AppTypography.of(context).bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppMonthField(
            value: _month.firstDayUtc,
            onChanged: (date) =>
                setState(() => _month = YearMonth.fromDate(date)),
            enabled: !_reviewing,
          ),
          const SizedBox(height: AppSpacing.md),
          AppMoneyField(
            label: 'De este ingreso, para ese mes',
            currency: widget.currency,
            controller: _amount,
            prominent: false,
            enabled: !_reviewing,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_error != null)
            Text(_error!, style: AppTypography.of(context).bodySmall),
          if (settlement.hasError || periods.hasError || rules.hasError)
            Text(
              'No se pudieron comprobar las cuotas. Cierra este panel y vuelve a intentarlo.',
              style: AppTypography.of(context).bodySmall,
            )
          else if (!ready)
            const LoadingIndicator(
              label: 'Comprobando cuotas y participación…',
            ),
          AppButton(
            label: 'Usar este mes',
            loading: _reviewing,
            onPressed: ready && !_reviewing ? _choose : null,
          ),
        ],
      ),
    );
  }
}
