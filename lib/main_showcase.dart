import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'design_system/showcase/design_system_showcase.dart';

/// Development-only entrypoint, independent of authentication and Firebase.
void main() {
  if (!kDebugMode) {
    throw UnsupportedError(
      'La galería solo está disponible en compilaciones debug.',
    );
  }
  runApp(const DesignSystemShowcase());
}
