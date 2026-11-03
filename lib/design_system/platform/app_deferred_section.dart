import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../components/feedback/app_skeleton.dart';
import '../components/layout/app_scaffold.dart';
import '../components/navigation/app_top_bar.dart';
import 'app_section_render_scope.dart';

/// Avoid mounting data listeners/layout during a route's entrance. A live page
/// is frozen only for the short transition, never cached across access changes.
class AppDeferredSection extends StatefulWidget {
  const AppDeferredSection({
    super.key,
    required this.identity,
    required this.sectionIndex,
    required this.builder,
  });
  final Object identity;
  final int sectionIndex;
  final WidgetBuilder builder;
  @override
  State<AppDeferredSection> createState() => _AppDeferredSectionState();
}

class _AppDeferredSectionState extends State<AppDeferredSection> {
  final _snapshot = SnapshotController();
  final _animations = <Animation<double>>[];
  ModalRoute<Object?>? _route;
  AppSectionRenderScope? _scope;
  Object? _accessKey;
  Widget? _page;
  bool _moving = false, _scheduled = false;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = AppSectionRenderScope.maybeOf(context);
    _route = ModalRoute.of(context);
    if (_accessKey != _scope?.accessKey) {
      _accessKey = _scope?.accessKey;
      _reset();
    }
    for (final animation in _animations) {
      animation.removeStatusListener(_status);
    }
    _animations
      ..clear()
      ..addAll([
        ?_route?.animation,
        ?_route?.secondaryAnimation,
        ...?_scope?.outerAnimations,
      ]);
    for (final animation in _animations) {
      animation.addStatusListener(_status);
    }
    _refresh(notify: false);
  }

  @override
  void didUpdateWidget(AppDeferredSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.identity != widget.identity) _reset();
    _refresh(notify: false);
  }

  void _reset() {
    _generation++;
    _scheduled = false;
    _page = null;
    _snapshot.allowSnapshotting = false;
    _snapshot.clear();
  }

  void _status(AnimationStatus _) => _refresh();

  void _refresh({bool notify = true}) {
    if (!mounted) return;
    final canFreeze = _scope?.canFreeze ?? true;
    final moving =
        !MediaQuery.disableAnimationsOf(context) &&
        _animations.any((animation) => animation.isAnimating);
    final changed = _moving != moving;
    _moving = moving;
    _snapshot.allowSnapshotting =
        !kIsWeb && canFreeze && moving && _page != null;
    if (!canFreeze) {
      // Mount the existing access guard immediately, never a stale frozen frame.
      _page ??= widget.builder(context);
    } else if (!moving &&
        (_route?.isCurrent ?? true) &&
        _page == null &&
        !_scheduled) {
      _scheduleContent();
    }
    if (notify && changed) setState(() {});
  }

  void _scheduleContent() {
    _scheduled = true;
    final generation = _generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Give the placeholder a complete frame before starting data/layout work.
      if (!mounted || generation != _generation) return;
      _scheduled = false;
      if (_moving || !(_route?.isCurrent ?? true)) return;
      setState(() => _page = widget.builder(context));
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _generation++;
    for (final animation in _animations) {
      animation.removeStatusListener(_status);
    }
    _snapshot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SnapshotWidget(
    controller: _snapshot,
    mode: SnapshotMode.permissive,
    child: TickerMode(
      enabled: !_moving || !(_scope?.canFreeze ?? true),
      child: _page ?? _SectionPlaceholder(index: widget.sectionIndex),
    ),
  );
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) => MediaQuery(
    // Static while sliding: the real asynchronous loading UI can shimmer later.
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: AppScaffold(
      appBar: AppTopBar(
        title: switch (index) {
          0 => 'BoteParroquial',
          1 => 'Movimientos',
          2 => 'Participantes',
          _ => 'Informes',
        },
      ),
      child: AppSkeleton(
        layout: switch (index) {
          0 => AppSkeletonLayout.summary,
          1 => AppSkeletonLayout.movements,
          2 => AppSkeletonLayout.people,
          _ => AppSkeletonLayout.content,
        },
        label: 'Preparando sección…',
      ),
    ),
  );
}
