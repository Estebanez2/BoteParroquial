import 'package:flutter/material.dart';
import '../feedback/app_sound_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class AppNavigationItem {
  const AppNavigationItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });
  final List<AppNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final duration = AppMotion.duration(
                  context,
                  AppMotion.durationSection,
                );
                final width = constraints.maxWidth / items.length;
                final alignment = AlignmentDirectional(
                  items.length == 1
                      ? 0
                      : -1 + 2 * selectedIndex / (items.length - 1),
                  -1,
                );
                return Stack(
                  children: [
                    Positioned.fill(
                      top: AppSpacing.xs,
                      child: AnimatedAlign(
                        key: const ValueKey('navigation-indicator'),
                        alignment: alignment,
                        duration: duration,
                        curve: AppMotion.curveStandard,
                        child: SizedBox(
                          width: width,
                          height: AppSpacing.iconLarge + 2 * AppSpacing.sm,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.primaryContainer,
                                borderRadius: AppRadius.control,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var index = 0; index < items.length; index++)
                          Expanded(
                            child: Semantics(
                              selected: index == selectedIndex,
                              button: true,
                              child: InkWell(
                                onTap: index == selectedIndex
                                    ? null
                                    : () {
                                        AppSoundScope.emit(
                                          context,
                                          UiSound.tap,
                                        );
                                        onSelected(index);
                                      },
                                borderRadius: AppRadius.control,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: AppSpacing.xs,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height:
                                            AppSpacing.iconLarge +
                                            2 * AppSpacing.sm,
                                        child: Icon(
                                          index == selectedIndex
                                              ? items[index].selectedIcon ??
                                                    items[index].icon
                                              : items[index].icon,
                                          size: AppSpacing.iconLarge,
                                          color: index == selectedIndex
                                              ? c.primary
                                              : c.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      AnimatedDefaultTextStyle(
                                        duration: duration,
                                        style: AppTypography.of(context)
                                            .labelSmall
                                            .copyWith(
                                              letterSpacing: 0,
                                              color: index == selectedIndex
                                                  ? c.primary
                                                  : c.textSecondary,
                                            ),
                                        child: Text(
                                          items[index].label,
                                          textAlign: TextAlign.center,
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
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
