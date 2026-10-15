import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

class AppAdaptiveRow extends StatelessWidget {
  const AppAdaptiveRow({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < children.length * AppSpacing.coverLarge ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i != 0) const SizedBox(height: AppSpacing.sm),
              children[i],
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i != 0) const SizedBox(width: AppSpacing.sm),
            Expanded(child: children[i]),
          ],
        ],
      );
    },
  );
}
