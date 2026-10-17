import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';

/// Avoid flashing a transient notice. Hides immediately when resolved; the delay
/// is a feedback grace period, independent of reduced animation preferences.
class AppDelayedVisibility extends StatefulWidget {
  const AppDelayedVisibility({
    super.key,
    required this.visible,
    required this.child,
    this.delay = AppMotion.statusNoticeDelay,
  });
  final bool visible;
  final Widget child;
  final Duration delay;
  @override
  State<AppDelayedVisibility> createState() => _AppDelayedVisibilityState();
}

class _AppDelayedVisibilityState extends State<AppDelayedVisibility> {
  Timer? _timer;
  bool _shown = false;
  @override
  void initState() {
    super.initState();
    _update();
  }

  @override
  void didUpdateWidget(covariant AppDelayedVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible ||
        oldWidget.delay != widget.delay) {
      _update();
    }
  }

  void _update() {
    _timer?.cancel();
    if (!widget.visible) {
      _shown = false;
      return;
    }
    if (_shown) return;
    _timer = Timer(widget.delay, () {
      if (mounted && widget.visible) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _shown && widget.visible ? widget.child : const SizedBox.shrink();
}
