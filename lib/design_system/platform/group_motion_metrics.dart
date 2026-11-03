import 'dart:async';
import 'dart:convert';
import 'dart:ui' show FramePhase, FrameTiming;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Opt-in profile diagnostics. Logs timings and tab indices, never user data.
class GroupMotionMetrics {
  static const enabled =
      kProfileMode && bool.fromEnvironment('TRACE_GROUP_MOTION');
  GroupMotionMetrics() {
    if (enabled) SchedulerBinding.instance.addTimingsCallback(_receive);
  }
  final _windows = <_MotionWindow>[];
  void start(int from, int to, double refreshRate) {
    if (!enabled) return;
    final window = _MotionWindow(from, to, refreshRate > 0 ? refreshRate : 60);
    _windows.add(window);
    if (_windows.length > 16) _finish(_windows.first, partial: true);
    window.timer = Timer(
      const Duration(milliseconds: 1150),
      () => _finish(window),
    );
  }

  void _receive(List<FrameTiming> frames) {
    for (final frame in frames) {
      final wall = frame.timestampInMicroseconds(
        FramePhase.rasterFinishWallTime,
      );
      for (final window in _windows) {
        if (wall >= window.start &&
            wall <= window.start + 950000 &&
            window.frames.length < 512) {
          window.frames.add(frame);
        }
      }
    }
  }

  void _finish(_MotionWindow window, {bool partial = false}) {
    window.timer?.cancel();
    _windows.remove(window);
    if (window.frames.isEmpty) return;
    final build =
        window.frames.map((f) => f.buildDuration.inMicroseconds / 1000).toList()
          ..sort();
    final raster =
        window.frames
            .map((f) => f.rasterDuration.inMicroseconds / 1000)
            .toList()
          ..sort();
    final overhead =
        window.frames.map((f) => f.vsyncOverhead.inMicroseconds / 1000).toList()
          ..sort();
    final budget = 1000 / window.hz;
    double rounded(double value) => (value * 100).round() / 100;
    double p95(List<double> values) =>
        rounded(values[(values.length * .95).ceil() - 1]);
    debugPrint(
      'GROUP_MOTION ${jsonEncode({'from': window.from, 'to': window.to, 'frames': build.length, 'windowMs': 950, 'partial': partial, 'hz': rounded(window.hz), 'budgetMs': rounded(budget), 'buildP95Ms': p95(build), 'rasterP95Ms': p95(raster), 'buildMaxMs': rounded(build.last), 'rasterMaxMs': rounded(raster.last), 'vsyncMaxMs': rounded(overhead.last), 'overBudget': window.frames.where((f) => f.buildDuration.inMicroseconds / 1000 > budget || f.rasterDuration.inMicroseconds / 1000 > budget).length, 'lateStarts': overhead.where((value) => value > budget).length})}',
    );
  }

  void dispose() {
    if (!enabled) return;
    SchedulerBinding.instance.removeTimingsCallback(_receive);
    for (final window in List<_MotionWindow>.of(_windows)) {
      _finish(window, partial: true);
    }
  }
}

class _MotionWindow {
  _MotionWindow(this.from, this.to, this.hz);
  final int from, to;
  final double hz;
  final int start = DateTime.now().microsecondsSinceEpoch;
  final frames = <FrameTiming>[];
  Timer? timer;
}
