import 'dart:io';
import 'dart:ui' as ui;

import 'package:bote_parroquial/design_system/showcase/design_system_showcase.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opt-in screenshot export; never writes artifacts during ordinary test runs.
void main() {
  testWidgets(
    'Exporta vistas para revisión visual',
    (tester) async {
      await tester.runAsync(() async {
        for (final (family, asset) in [
          ('Manrope', 'assets/fonts/Manrope-Variable.ttf'),
          ('Newsreader', 'assets/fonts/Newsreader-Variable.ttf'),
          ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
        ]) {
          await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
        }
      });
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final output = Directory('.dart_tool/design_system_preview');
      output.createSync(recursive: true);
      for (final (name, size, dark, section) in [
        ('mobile-light', const Size(412, 1000), false, 0),
        ('mobile-dark', const Size(412, 1000), true, 0),
        ('desktop-light', const Size(1280, 1000), false, 0),
        ('controls-light', const Size(1000, 1100), false, 1),
        ('feedback-dark', const Size(1000, 1100), true, 2),
        ('tokens-light', const Size(1000, 1100), false, 3),
      ]) {
        tester.view.physicalSize = size;
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: DesignSystemShowcase(
              initialSection: section,
              initialDark: dark,
            ),
          ),
        );
        // Some sections intentionally contain an indeterminate loader.
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final snapshot = await boundary.toImage(pixelRatio: 1.5);
          final data = await snapshot.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await File(
            '${output.path}/$name.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          snapshot.dispose();
        });
      }
    },
    skip: !const bool.fromEnvironment('EXPORT_DESIGN_PREVIEWS'),
  );
}
