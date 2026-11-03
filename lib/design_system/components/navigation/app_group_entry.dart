import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';

/// Geometry only: never persisted or used to authorize access.
class AppGroupOrigin {
  const AppGroupOrigin(this.rect);
  final Rect rect;
}

class AppGroupEntry extends StatefulWidget {
  const AppGroupEntry({super.key, required this.builder, required this.onOpen});
  final Widget Function(BuildContext, VoidCallback) builder;
  final ValueChanged<AppGroupOrigin> onOpen;
  @override
  State<AppGroupEntry> createState() => _AppGroupEntryState();
}

class _AppGroupEntryState extends State<AppGroupEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: AppMotion.durationGroupWave,
  );
  bool _opening = false;
  Future<void> _open() async {
    if (_opening) return;
    _opening = true;
    try {
      if (!MediaQuery.disableAnimationsOf(context)) {
        await _wave.forward(from: 0).orCancel;
      }
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final card = context.findRenderObject();
      final overlay = Navigator.of(context).overlay?.context.findRenderObject();
      if (card is! RenderBox || overlay is! RenderBox || !card.hasSize) return;
      final topLeft = overlay.globalToLocal(card.localToGlobal(Offset.zero));
      widget.onOpen(AppGroupOrigin(topLeft & card.size));
    } on TickerCanceled {
      // Removing the card cancels pending entry.
    } finally {
      _opening = false;
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _GroupWavePainter(
      _wave,
      AppColors.of(context).primary,
      reduced: MediaQuery.disableAnimationsOf(context),
    ),
    child: widget.builder(context, _open),
  );
}

class _GroupWavePainter extends CustomPainter {
  _GroupWavePainter(this.animation, this.color, {required this.reduced})
    : super(repaint: animation);
  final Animation<double> animation;
  final Color color;
  final bool reduced;
  @override
  void paint(Canvas canvas, Size size) {
    if (reduced || animation.value == 0 || animation.value == 1) return;
    final t = animation.value;
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(AppRadius.card.toRRect(rect));
    final radius =
        math.sqrt(size.width * size.width + size.height * size.height) * .5 * t;
    canvas.drawCircle(
      rect.center,
      radius,
      Paint()..color = color.withValues(alpha: .14 * (1 - t)),
    );
    canvas.drawCircle(
      rect.center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 * (1 - t) + 2
        ..color = color.withValues(alpha: .7 * (1 - t)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GroupWavePainter oldDelegate) =>
      animation != oldDelegate.animation ||
      color != oldDelegate.color ||
      reduced != oldDelegate.reduced;
}
