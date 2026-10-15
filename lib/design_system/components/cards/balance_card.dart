import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_gradients.dart';
import '../display/money_text.dart';

/// Displays supplied values. It never calculates or persists a group balance.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balanceCents,
    required this.currency,
    this.title = 'SALDO DISPONIBLE',
    this.incomeCents,
    this.withdrawalCents,
    this.caption,
  });
  final int balanceCents;
  final String currency, title;
  final int? incomeCents, withdrawalCents;
  final String? caption;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTypography.of(context);
    return ClipRRect(
      borderRadius: AppRadius.hero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.hero(context),
          borderRadius: AppRadius.hero,
          border: Border.all(color: c.outline),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _CommunityRings(c.onHero)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: t.labelSmall.copyWith(color: c.onHero),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: c.onHero,
                        size: AppSpacing.iconLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MoneyText(
                    balanceCents,
                    currency: currency,
                    size: MoneyTextSize.hero,
                    color: c.onHero,
                    animate: true,
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      caption!,
                      style: t.bodySmall.copyWith(color: c.onHero),
                    ),
                  ],
                  if (incomeCents != null || withdrawalCents != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Divider(color: c.onHero.withValues(alpha: .2)),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xxl,
                      runSpacing: AppSpacing.lg,
                      children: [
                        if (incomeCents != null)
                          _metric(
                            context,
                            'Ingresos del mes',
                            incomeCents!,
                            Icons.south_west_rounded,
                          ),
                        if (withdrawalCents != null)
                          _metric(
                            context,
                            'Retiradas del mes',
                            withdrawalCents!,
                            Icons.north_east_rounded,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    int amount,
    IconData icon,
  ) {
    final c = AppColors.of(context);
    final t = AppTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: t.bodySmall.copyWith(color: c.onHero.withValues(alpha: .85)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.icon, color: c.onHero),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: MoneyText(amount, currency: currency, color: c.onHero),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommunityRings extends CustomPainter {
  const _CommunityRings(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: .08);
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(size.width * .96, size.height * .12),
        70 + i * 30,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CommunityRings oldDelegate) => oldDelegate.color != color;
}
