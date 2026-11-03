import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Presentation only. Never displays invented names, money or permissions.
class AppShimmer extends StatefulWidget {
  const AppShimmer({
    super.key,
    required this.child,
    this.label = 'Cargando',
    this.color,
  });
  final Widget child;
  final String label;
  final Color? color;
  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.shimmerDuration,
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final base = widget.color ?? colors.surfaceVariant;
    final highlight = Color.lerp(base, colors.primary, .26)!;
    return Semantics(
      label: widget.label,
      liveRegion: true,
      excludeSemantics: true,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: MediaQuery.disableAnimationsOf(context)
              ? widget.child
              : AnimatedBuilder(
                  animation: _controller,
                  child: widget.child,
                  builder: (context, child) {
                    final offset = _controller.value * 4 - 2;
                    return ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment(offset - .45, -.4),
                        end: Alignment(offset + .45, .4),
                        colors: [base, highlight, base],
                        stops: const [0, .5, 1],
                      ).createShader(rect),
                      child: child,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class AppSkeletonBlock extends StatelessWidget {
  const AppSkeletonBlock({
    super.key,
    this.width,
    this.height = AppSpacing.lg,
    this.circle = false,
  });
  final double? width;
  final double height;
  final bool circle;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.of(context).surfaceVariant,
      borderRadius: circle ? null : AppRadius.control,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
    ),
  );
}

enum AppSkeletonLayout {
  content,
  group,
  groups,
  people,
  movements,
  summary,
  form,
}

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.layout = AppSkeletonLayout.content,
    this.label = 'Cargando',
  });
  final AppSkeletonLayout layout;
  final String label;
  @override
  Widget build(BuildContext context) => AppShimmer(
    label: label,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (layout) {
        AppSkeletonLayout.group => [_group()],
        AppSkeletonLayout.groups => [
          _group(),
          const SizedBox(height: AppSpacing.lg),
          _group(),
        ],
        AppSkeletonLayout.people || AppSkeletonLayout.movements => [
          for (var i = 0; i < 3; i++) ...[
            _panel(
              Row(
                children: [
                  const AppSkeletonBlock(
                    width: AppSpacing.avatarLarge,
                    height: AppSpacing.avatarLarge,
                    circle: true,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: _lines()),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
        AppSkeletonLayout.summary => [
          _panel(
            const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSkeletonBlock(width: AppSpacing.coverLarge),
                SizedBox(height: AppSpacing.md),
                AppSkeletonBlock(height: AppSpacing.avatarLarge),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _panel(_lines()),
          const SizedBox(height: AppSpacing.lg),
          _panel(_lines()),
        ],
        AppSkeletonLayout.form => [
          for (var i = 0; i < 3; i++) ...[
            const AppSkeletonBlock(height: AppSpacing.controlHeight),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
        AppSkeletonLayout.content => [_panel(_lines())],
      },
    ),
  );
  static Widget _lines() => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: .6,
        child: AppSkeletonBlock(),
      ),
      SizedBox(height: AppSpacing.md),
      AppSkeletonBlock(height: AppSpacing.md),
      SizedBox(height: AppSpacing.sm),
      FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: .8,
        child: AppSkeletonBlock(height: AppSpacing.md),
      ),
    ],
  );
  static Widget _panel(Widget child) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: const BoxDecoration(borderRadius: AppRadius.card),
    child: child,
  );
  static Widget _group() => _panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AspectRatio(
          aspectRatio: AppSpacing.coverAspectRatio,
          child: AppSkeletonBlock(height: AppSpacing.ornamentSize),
        ),
        const SizedBox(height: AppSpacing.lg),
        _lines(),
        const SizedBox(height: AppSpacing.lg),
        const FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: .4,
          child: AppSkeletonBlock(height: AppSpacing.xxl),
        ),
      ],
    ),
  );
}
