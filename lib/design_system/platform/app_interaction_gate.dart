import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Ephemeral visual lock only. Never caches permissions or waits for network I/O.
class AppInteractionGate extends ChangeNotifier {
  final _leases = <Object>{};
  bool _disposed = false, _handoff = false, _queued = false;
  bool get busy => _leases.isNotEmpty;
  AppInteractionLease? tryAcquire() => busy && !_handoff ? null : hold();
  AppInteractionLease hold() {
    final token = Object();
    _leases.add(token);
    _changed();
    return AppInteractionLease._(this, token);
  }

  void _release(Object token) {
    if (_leases.remove(token)) _changed();
  }

  void _changed() {
    if (_disposed) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_queued) return;
      _queued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _queued = false;
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  /// Keep the current frame blocked while a callback starts the next animation.
  void handoff(AppInteractionLease lease, VoidCallback callback) {
    _handoff = true;
    try {
      callback();
    } finally {
      _handoff = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => lease.release());
      WidgetsBinding.instance.scheduleFrame();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _leases.clear();
    super.dispose();
  }
}

class AppInteractionLease {
  AppInteractionLease._(this._gate, this._token);
  final AppInteractionGate _gate;
  final Object _token;
  bool _released = false;
  void release() {
    if (!_released) {
      _released = true;
      _gate._release(_token);
    }
  }
}

class AppInteractionScope extends InheritedWidget {
  const AppInteractionScope({
    super.key,
    required this.gate,
    required super.child,
  });
  final AppInteractionGate gate;
  static AppInteractionGate? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppInteractionScope>()?.gate;
  @override
  bool updateShouldNotify(AppInteractionScope oldWidget) =>
      gate != oldWidget.gate;
}

class AppInteractionHost extends StatefulWidget {
  const AppInteractionHost({super.key, required this.child});
  final Widget child;
  @override
  State<AppInteractionHost> createState() => _AppInteractionHostState();
}

class _AppInteractionHostState extends State<AppInteractionHost> {
  final gate = AppInteractionGate();
  @override
  void dispose() {
    gate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppInteractionScope(
    gate: gate,
    child: AnimatedBuilder(
      animation: gate,
      child: widget.child,
      builder: (_, child) => AbsorbPointer(
        absorbing: gate.busy,
        child: ExcludeSemantics(excluding: gate.busy, child: child!),
      ),
    ),
  );
}

class AppInteractionRouteGuard extends StatelessWidget {
  const AppInteractionRouteGuard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final gate = AppInteractionScope.maybeOf(context);
    if (gate == null) return child;
    return AnimatedBuilder(
      animation: gate,
      child: child,
      builder: (_, child) => PopScope(
        canPop:
            !gate.busy ||
            Navigator.maybeOf(context)?.userGestureInProgress == true,
        child: child!,
      ),
    );
  }
}

class AppRouteInteractionLock extends StatefulWidget {
  const AppRouteInteractionLock({
    super.key,
    required this.animation,
    required this.child,
  });
  final Animation<double> animation;
  final Widget child;
  @override
  State<AppRouteInteractionLock> createState() =>
      _AppRouteInteractionLockState();
}

class _AppRouteInteractionLockState extends State<AppRouteInteractionLock> {
  AppInteractionGate? _gate;
  AppInteractionLease? _lease;
  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_status);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _gate = AppInteractionScope.maybeOf(context);
    _status(widget.animation.status);
  }

  @override
  void didUpdateWidget(AppRouteInteractionLock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeStatusListener(_status);
      widget.animation.addStatusListener(_status);
      _status(widget.animation.status);
    }
  }

  void _status(AnimationStatus status) {
    if (status == AnimationStatus.forward ||
        status == AnimationStatus.reverse) {
      _lease ??= _gate?.hold();
    } else {
      _lease?.release();
      _lease = null;
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_status);
    _lease?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
