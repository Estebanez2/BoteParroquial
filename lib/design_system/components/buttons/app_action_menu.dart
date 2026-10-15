import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class AppActionMenu<T> extends StatelessWidget {
  const AppActionMenu({
    super.key,
    required this.label,
    required this.items,
    required this.onSelected,
    this.enabled = true,
  });
  final String label;
  final Map<T, String> items;
  final ValueChanged<T> onSelected;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return PopupMenuButton<T>(
      tooltip: label,
      enabled: enabled,
      onSelected: onSelected,
      icon: const Icon(Icons.more_vert_rounded),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(AppSpacing.compactHeight),
        backgroundColor: c.surfaceVariant.withValues(alpha: .65),
        foregroundColor: c.textPrimary,
        side: BorderSide(color: c.outline.withValues(alpha: .4)),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      itemBuilder: (context) => [
        for (final entry in items.entries)
          PopupMenuItem<T>(value: entry.key, child: Text(entry.value)),
      ],
    );
  }
}
