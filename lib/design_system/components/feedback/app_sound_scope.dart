import 'package:flutter/widgets.dart';
import '../../../models/ui_sound.dart';
export '../../../models/ui_sound.dart';

/// Visual feedback only; SDKs and preferences live outside the Design System.
class AppSoundScope extends InheritedWidget {
  const AppSoundScope({super.key, required this.onSound, required super.child});
  final ValueChanged<UiSound> onSound;
  static void emit(BuildContext context, UiSound sound) =>
      context.getInheritedWidgetOfExactType<AppSoundScope>()?.onSound(sound);
  @override
  bool updateShouldNotify(AppSoundScope oldWidget) => false;
}

/// Only actionable controls emit sounds; blank areas and scrolling stay silent.
class AppSoundSurface extends StatelessWidget {
  const AppSoundSurface({
    super.key,
    required this.onSound,
    required this.child,
  });
  final ValueChanged<UiSound> onSound;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      AppSoundScope(onSound: onSound, child: child);
}
