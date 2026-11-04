import 'dart:math';

enum UiSound { tap, menu, back, typing, success, photo, warning }

/// Small timbre variations, with no immediate repeat and bounded pool count.
class UiClickVariants {
  UiClickVariants({Random? random, this.prefix = 'press', this.count = 3})
    : assert(count >= 2),
      _random = random ?? Random();
  final Random _random;
  final String prefix;
  final int count;
  int? _last;
  String nextAsset() {
    final previous = _last;
    var next = _random.nextInt(previous == null ? count : count - 1);
    if (previous != null && next >= previous) next++;
    _last = next;
    return '${prefix}_${next + 1}';
  }
}
