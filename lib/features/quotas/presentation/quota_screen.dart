import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/quota_rule.dart';
import '../../../models/year_month.dart';
import '../../groups/presentation/group_access_body.dart';
import '../../persons/providers/person_providers.dart';
import '../providers/quota_providers.dart';

class QuotaScreen extends ConsumerWidget {
  const QuotaScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: AppTopBar(
      title: 'El ritmo del grupo',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver al grupo',
        onPressed: () => context.go('/groups/$groupId'),
      ),
    ),
    child: GroupAccessBody(
      groupId: groupId,
      builder: (group, _) => ref
          .watch(quotaRulesProvider(groupId))
          .when(
            skipLoadingOnReload: false,
            skipLoadingOnRefresh: false,
            loading: () => const LoadingIndicator(label: 'Consultando cuotas…'),
            error: (e, _) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Cuotas no disponibles',
              description: failureMessage(e),
              actionLabel: 'Reintentar',
              onAction: () => ref.invalidate(quotaRulesProvider(groupId)),
            ),
            data: (rules) => _QuotaBody(
              key: ValueKey(groupId),
              id: groupId,
              currency: group.currency,
              rules: rules,
            ),
          ),
    ),
  );
}

class _QuotaBody extends ConsumerStatefulWidget {
  const _QuotaBody({
    super.key,
    required this.id,
    required this.currency,
    required this.rules,
  });
  final String id, currency;
  final List<QuotaRule> rules;
  @override
  ConsumerState<_QuotaBody> createState() => _QuotaBodyState();
}

class _QuotaBodyState extends ConsumerState<_QuotaBody> {
  final _amount = TextEditingController();
  late YearMonth _month;
  @override
  void initState() {
    super.initState();
    final now = ref.read(quotaMonthProvider(widget.id));
    _month = widget.rules.isEmpty ? now : now.addMonths(1);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final cents = parseMoneyCents(_amount.text);
    final error = ref
        .read(quotaControllerProvider(widget.id).notifier)
        .validateAmount(cents);
    if (error != null) {
      AppSnackbar.show(context, error, variant: AppSnackbarVariant.error);
      return;
    }
    final observed = List<QuotaRule>.of(widget.rules);
    final confirmed = await AppDialog.show(
      context,
      title: '¿Confirmar esta cuota?',
      description:
          '${formatMoneyCents(cents!, currency: widget.currency)} al mes desde $_month, hasta la siguiente regla. Los meses actuales y pasados quedarán protegidos: revisa el inicio y el importe. Si ya hay una versión futura para ese mes, se conservará en el historial. No asigna pagos ni modifica el saldo.',
      confirmLabel: 'Guardar cuota',
    );
    if (!confirmed || !mounted) return;
    final saved = await ref
        .read(quotaControllerProvider(widget.id).notifier)
        .saveRule(_month, cents, observed);
    if (saved && mounted) {
      _amount.clear();
      AppSnackbar.show(
        context,
        'Cuota guardada.',
        variant: AppSnackbarVariant.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.id,
        action = ref.watch(quotaControllerProvider(widget.id));
    final current = ref.watch(currentQuotaRuleProvider(id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppReveal(
          child: AppHeroPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBadge(
                  'CUOTA MENSUAL',
                  icon: Icons.calendar_month_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  current == null
                      ? 'Una historia por acordar'
                      : formatMoneyCents(
                          current.monthlyFeeCents,
                          currency: widget.currency,
                        ),
                  style: AppTypography.of(context).editorialTitle,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  current == null
                      ? 'No hay una cuota vigente para este mes.'
                      : 'La misma cuota para cada persona durante sus meses computables.',
                  style: AppTypography.of(context).bodyLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (ref.watch(canManagePersonsProvider(id)))
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.rules.isEmpty
                      ? 'La primera cuota'
                      : 'El próximo cambio',
                  style: AppTypography.of(context).headingSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.rules.isEmpty
                      ? 'Elige expresamente desde qué mes empieza. Cada persona necesita también su periodo de participación.'
                      : 'Desde el mes siguiente. Los meses actuales y pasados se conservan. Una cuota de cero suspende temporalmente las obligaciones.',
                  style: AppTypography.of(context).bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppMoneyField(
                  label: 'Cuota mensual',
                  currency: widget.currency,
                  controller: _amount,
                  enabled: !action.isLoading,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppMonthField(
                  label: 'Desde el mes',
                  value: _month.firstDayUtc,
                  enabled: !action.isLoading,
                  onChanged: (value) =>
                      setState(() => _month = YearMonth.fromDate(value)),
                ),
                if (action.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(failureMessage(action.error!)),
                  ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Revisar cuota',
                  validate: () {
                    final error = ref
                        .read(quotaControllerProvider(widget.id).notifier)
                        .validateAmount(parseMoneyCents(_amount.text));
                    if (error != null) {
                      AppSnackbar.show(
                        context,
                        error,
                        variant: AppSnackbarVariant.error,
                      );
                    }
                    return error == null;
                  },
                  leadingIcon: Icons.calendar_month_outlined,
                  loading: action.isLoading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Las reglas de cada etapa',
          style: AppTypography.of(context).headingSmall,
        ),
        for (final rule in widget.rules.reversed)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: AppReveal(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Desde ${rule.effectiveFrom}',
                      style: AppTypography.of(context).headingSmall,
                    ),
                    MoneyText(rule.monthlyFeeCents, currency: widget.currency),
                    Text(
                      'Versión ${rule.revision} · Hasta la siguiente regla',
                      style: AppTypography.of(context).bodySmall,
                    ),
                    AppButton(
                      label: 'Ver versiones',
                      variant: AppButtonVariant.ghost,
                      onPressed: () => AppBottomSheet.show<void>(
                        context,
                        title: 'Historial de ${rule.effectiveFrom}',
                        builder: (_) => Consumer(
                          builder: (context, ref, _) => ref
                              .watch(quotaVersionsProvider((id, rule.id)))
                              .when(
                                loading: () => const LoadingIndicator(),
                                error: (e, _) => Text(failureMessage(e)),
                                data: (versions) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Últimas 20 versiones. Las anteriores permanecen guardadas.',
                                      style: AppTypography.of(
                                        context,
                                      ).bodySmall,
                                    ),
                                    for (final v in versions)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: AppSpacing.md,
                                        ),
                                        child: Text(
                                          'Versión ${v.revision} · ${formatMoneyCents(v.monthlyFeeCents, currency: widget.currency)}',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
