import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Presentation source, never a grant of server permissions.
final offlineReadOnlyProvider = Provider<bool>((ref) => false);
