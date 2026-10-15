import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

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
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          AppTypography.of(context).labelSmall,
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? c.primary
                : c.textSecondary,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: items
            .map(
              (item) => NavigationDestination(
                label: item.label,
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon ?? item.icon),
              ),
            )
            .toList(),
      ),
    );
  }
}
