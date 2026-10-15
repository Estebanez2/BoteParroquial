import 'dart:io';
import 'dart:ui' as ui;
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_flow_test.dart' as auth;
import 'groups_test.dart' as groups;

void main() {
  testWidgets(
    'Exporta grupos para revisión visual',
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
      tester.view.physicalSize = const Size(412, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final session = auth.FakeAuthRepository(auth.alice);
      final repository = groups.FakeGroups();
      final container = ProviderContainer(
        overrides: [
          firebaseStartupProvider.overrideWithValue(
            FirebaseStartup.ready(auth.FakeApp()),
          ),
          authRepositoryProvider.overrideWithValue(session),
          userProfileRepositoryProvider.overrideWithValue(
            auth.FakeProfileRepository(),
          ),
          groupRepositoryProvider.overrideWithValue(repository),
          personsProvider.overrideWith(
            (ref, groupId) => Stream.value(const []),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await session.changes.close();
        await repository.changes.close();
      });
      final key = GlobalKey();
      final output = Directory('.dart_tool/groups_preview')
        ..createSync(recursive: true);
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: UncontrolledProviderScope(
            container: container,
            child: const BoteParroquialApp(),
          ),
        ),
      );
      for (final (name, route, dark) in [
        ('home-light', '/', false),
        ('group-light', '/groups/a', false),
        ('group-dark', '/groups/a', true),
      ]) {
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? ui.Brightness.dark
            : ui.Brightness.light;
        container.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1.5);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${output.path}/$name.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    },
    skip: !const bool.fromEnvironment('EXPORT_GROUP_PREVIEWS'),
  );
}
