import 'package:bote_parroquial/features/offline/providers/daily_snapshot_providers.dart';

export 'package:bote_parroquial/features/offline/providers/daily_snapshot_providers.dart'
    show dailyCopyControllerProvider;

/// UI fixtures have no Firebase or secure storage. Snapshot tests exercise the
/// real implementation separately; screen tests must not start that lifecycle.
class IdleDailyCopies extends DailyCopyController {
  @override
  DailyCopyState build() => const DailyCopyState();
  @override
  void foreground(bool active) {}
  @override
  Future<void> refresh() async {}
}
