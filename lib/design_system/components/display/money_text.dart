import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_typography.dart';

enum MoneyTextVariant { balance, income, withdrawal }

enum MoneyTextSize { hero, large, medium }

/// Presentation only: does not calculate balances or change the persisted amount.
String formatMoneyCents(
  int amountCents, {
  String currency = 'EUR',
  bool showPositiveSign = false,
}) {
  final absolute = amountCents.abs();
  final whole = (absolute ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  final symbol = switch (currency) {
    'EUR' => '€',
    'USD' => r'$',
    'GBP' => '£',
    _ => currency,
  };
  final sign = amountCents < 0
      ? '-'
      : showPositiveSign && amountCents > 0
      ? '+'
      : '';
  return '$sign$whole,$fraction $symbol';
}

class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amountCents, {
    super.key,
    this.currency = 'EUR',
    this.variant = MoneyTextVariant.balance,
    this.size = MoneyTextSize.medium,
    this.color,
    this.animate = false,
  });
  final int amountCents;
  final String currency;
  final MoneyTextVariant variant;
  final MoneyTextSize size;
  final Color? color;
  final bool animate;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTypography.of(context);
    final value = variant == MoneyTextVariant.withdrawal
        ? -amountCents.abs()
        : amountCents;
    final text = formatMoneyCents(
      value,
      currency: currency,
      showPositiveSign: variant == MoneyTextVariant.income,
    );
    final style = switch (size) {
      MoneyTextSize.hero => t.moneyHero,
      MoneyTextSize.large => t.moneyLarge,
      MoneyTextSize.medium => t.moneyMedium,
    };
    final widget = Text(
      text,
      key: ValueKey(text),
      style: style.copyWith(
        color:
            color ??
            switch (variant) {
              MoneyTextVariant.income => c.success,
              MoneyTextVariant.withdrawal => c.danger,
              MoneyTextVariant.balance => c.textPrimary,
            },
      ),
    );
    return Semantics(
      label: switch (variant) {
        MoneyTextVariant.income => 'Ingreso: $text',
        MoneyTextVariant.withdrawal => 'Retirada: $text',
        MoneyTextVariant.balance => 'Saldo: $text',
      },
      excludeSemantics: true,
      child: animate
          ? AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.durationNormal),
              child: widget,
            )
          : widget,
    );
  }
}
