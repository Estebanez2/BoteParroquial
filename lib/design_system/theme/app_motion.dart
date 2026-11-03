import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const durationFast = Duration(milliseconds: 140);
  static const durationPress = Duration(milliseconds: 80);
  static const durationControl = Duration(milliseconds: 320);
  static const durationGroupWave = Duration(seconds: 1);
  static const durationPage = Duration(milliseconds: 240);
  static const durationSection = Duration(milliseconds: 180);
  static const shimmerDuration = Duration(milliseconds: 1450);
  static const durationNormal = Duration(milliseconds: 220);
  static const durationSlow = Duration(milliseconds: 320);
  static const durationEntrance = Duration(milliseconds: 540);
  static const durationAtmosphere = Duration(milliseconds: 900);
  static const staggerInterval = Duration(milliseconds: 65);
  static const double pressedScale = .97;
  static const double revealOffset = 18;
  static const statusNoticeDelay = Duration(seconds: 2);
  static const curveStandard = Curves.easeOutCubic;
  static const curveEmphasized = Curves.easeInOutCubic;
  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}

/// Brief content fade; route entrances own motion. Never animates a money value.
class AppReveal extends StatefulWidget {
  const AppReveal({super.key, required this.child, this.order = 0});
  final Widget child;
  final int order;
  @override
  State<AppReveal> createState() => _AppRevealState();
}

class _AppRevealState extends State<AppReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.durationSection,
  );
  late final Animation<double> _opacity = _controller.drive(
    CurveTween(curve: AppMotion.curveStandard),
  );
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final route = ModalRoute.of(context);
    // A route already animates the whole page. Do not also animate every card.
    final entering = route?.animation?.isAnimating ?? false;
    if (MediaQuery.disableAnimationsOf(context) || entering) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? widget.child
      : FadeTransition(opacity: _opacity, child: widget.child);
}

/// Shared full tap feedback; controls retain their native focus and semantics.
class AppPressFeedback extends StatefulWidget {
  const AppPressFeedback({super.key, required this.child, this.enabled = true})
    : builder = null,
      onActivate = null;
  const AppPressFeedback.builder({
    super.key,
    required this.builder,
    required this.onActivate,
    this.enabled = true,
  }) : child = null;
  final Widget? child;
  final Widget Function(BuildContext, VoidCallback)? builder;
  final VoidCallback? onActivate;
  final bool enabled;
  @override
  State<AppPressFeedback> createState() => _AppPressFeedbackState();
}

class _AppPressFeedbackState extends State<AppPressFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.durationPress,
      reverseDuration: AppMotion.durationPress,
    );
    _scale = Tween<double>(
      begin: 1,
      end: AppMotion.pressedScale,
    ).chain(CurveTween(curve: AppMotion.curveStandard)).animate(_controller);
  }

  bool _activating = false;
  bool get _reduced => MediaQuery.disableAnimationsOf(context);
  Future<void> _activate() async {
    if (!widget.enabled || _activating || widget.onActivate == null) return;
    if (_reduced) {
      widget.onActivate?.call();
      return;
    }
    _activating = true;
    try {
      await _controller.forward().orCancel;
      await _controller.reverse().orCancel;
      if (mounted && widget.enabled) widget.onActivate?.call();
    } on TickerCanceled {
      // Disposal or disabled access cancels the pending action.
    } finally {
      _activating = false;
    }
  }

  @override
  void didUpdateWidget(AppPressFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pointer(bool down) {
    if (!widget.enabled || _activating || _reduced) return;
    if (down) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _pointer(true),
    onPointerUp: (_) => _pointer(false),
    onPointerCancel: (_) => _pointer(false),
    child: ScaleTransition(
      scale: _reduced ? const AlwaysStoppedAnimation(1) : _scale,
      child: widget.builder?.call(context, _activate) ?? widget.child,
    ),
  );
}
