import 'package:flutter/material.dart';
import '../feedback/app_control_feedback.dart';
import '../feedback/app_sound_scope.dart';
import '../../theme/app_radius.dart';

/// Delegates opening to the native menu after shared B08 feedback.
class AppMenuSurface extends StatelessWidget {
  const AppMenuSurface({
    super.key,
    required this.child,
    required this.onPressed,
    this.enabled = true,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;
  @override
  Widget build(BuildContext context) => AppControlFeedback(
    enabled: enabled,
    onActivate: onPressed,
    sound: UiSound.menu,
    builder: (_, activate) => Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: AppRadius.control,
        onTap: enabled ? activate : null,
        child: child,
      ),
    ),
  );
}
