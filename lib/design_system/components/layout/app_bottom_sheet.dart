import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
  }) => showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    constraints: const BoxConstraints(maxWidth: AppSpacing.readingMax),
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.page + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.of(context).headingMedium),
              const SizedBox(height: AppSpacing.xl),
              builder(context),
            ],
          ),
        ),
      ),
    ),
  );
}
