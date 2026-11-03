import 'dart:io';
import 'dart:ui' as ui;
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/auth/providers/account_lifecycle_providers.dart';
import 'package:bote_parroquial/features/dashboard/providers/dashboard_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_deletion_providers.dart';
import 'package:bote_parroquial/features/home/presentation/home_screen.dart';
import 'package:bote_parroquial/features/photos/providers/photo_providers.dart';
import 'package:bote_parroquial/features/settings/presentation/appearance_screen.dart';
import 'package:bote_parroquial/features/settings/providers/appearance_providers.dart';
import 'package:bote_parroquial/models/appearance_settings.dart';
import 'package:bote_parroquial/models/auth_user.dart';
import 'package:bote_parroquial/models/custom_palette.dart';
import 'package:bote_parroquial/models/dashboard_summary.dart';
import 'package:bote_parroquial/models/group.dart';
import 'package:bote_parroquial/models/group_member.dart';
import 'package:bote_parroquial/repositories/appearance_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'support/memory_appearance.dart';

final _captureKey = GlobalKey();
Widget _host(Widget child, {bool reduced = false}) => RepaintBoundary(
  key: _captureKey,
  child: MaterialApp(
    theme: AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(
        body: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    ),
  ),
);
Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('EXPORT_VISUAL_LIBRARY')) return;
  final boundary =
      _captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final dir = Directory('.dart_tool/visual_library_preview');
    await dir.create(recursive: true);
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '${dir.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets(
    'Carga con formas y brillo, sin círculos, respeta movimiento reducido y elimina tickers',
    (tester) async {
      tester.view.physicalSize = const Size(412, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        for (final (family, asset) in [
          ('Manrope', 'assets/fonts/Manrope-Variable.ttf'),
          ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
        ]) {
          await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
        }
      });
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              AppSkeleton(
                layout: AppSkeletonLayout.group,
                label: 'Cargando grupo',
              ),
              AppAvatar(name: 'Ana', loading: true),
              LoadingIndicator(size: 24),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ShaderMask), findsNWidgets(3));
      expect(find.bySemanticsLabel('Cargando grupo'), findsOneWidget);
      await _capture(tester, 'loading-shimmer');
      await tester.pumpWidget(
        _host(
          const AppSkeleton(layout: AppSkeletonLayout.group),
          reduced: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShaderMask), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(_host(const Text('Datos listos')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Paletas propias ajustan contraste incluso blanco/negro y mantienen tres fuentes',
    () {
      double contrast(Color a, Color b) {
        final x = a.computeLuminance(), y = b.computeLuminance();
        return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
      }

      for (final seeds in [
        (0, 0xFFFFFF, 0x888888),
        (0xFFFF00, 0xFF00FF, 0x00FFFF),
        (0xFFFFFF, 0xFFFFFF, 0xFFFFFF),
      ]) {
        final custom = CustomPalette(
          id: 'local',
          name: 'Mi paleta',
          primaryRgb: seeds.$1,
          secondaryRgb: seeds.$2,
          tertiaryRgb: seeds.$3,
        );
        for (final mode in Brightness.values) {
          final c = AppColors.forCustom(custom, mode);
          for (final background in [
            c.surface,
            c.background,
            c.surfaceVariant,
            c.primaryContainer,
            c.secondaryContainer,
            c.tertiaryContainer,
          ]) {
            for (final text in [c.textPrimary, c.textSecondary, c.textMuted]) {
              expect(contrast(text, background), greaterThanOrEqualTo(4.5));
            }
            for (final accent in [c.primary, c.secondary, c.tertiary]) {
              expect(
                contrast(
                  accent,
                  Color.alphaBlend(accent.withValues(alpha: .12), background),
                ),
                greaterThanOrEqualTo(4.5),
              );
            }
          }
          for (final pair in [
            (c.primary, c.primaryContainer),
            (c.secondary, c.secondaryContainer),
            (c.tertiary, c.tertiaryContainer),
            (c.primary, c.onPrimary),
          ]) {
            expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
          }
          for (final font in AppFont.values) {
            final theme = AppTheme.forSettings(
              AppearanceSettings(
                font: font,
                customPalettes: [custom],
                customPaletteId: 'local',
              ),
              mode,
            );
            expect(theme.extension<AppColors>()!.primary, c.primary);
            if (font != AppFont.system) {
              expect(
                theme.textTheme.bodyMedium!.fontFamily,
                font == AppFont.manrope ? 'Manrope' : 'Newsreader',
              );
            }
          }
        }
      }
      final legacy = AppearanceSettings.fromJson({
        'version': 1,
        'palette': 'iris',
        'mode': 'dark',
      });
      expect(legacy.font, AppFont.manrope);
      expect(legacy.customPalette, isNull);
      expect(legacy.palette, AppPalette.iris);
    },
  );

  testWidgets(
    'Menú de cuenta y desplegable comparten filas; no conservan datos de otra cuenta',
    (tester) async {
      tester.view.physicalSize = const Size(360, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final account = ValueNotifier('Ana');
      addTearDown(account.dispose);
      String? chosen = 'Uno';
      var copies = 0;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                ValueListenableBuilder(
                  valueListenable: account,
                  builder: (_, name, _) => AppAvatarMenu(
                    accountId: name,
                    name: name,
                    email: '$name@example.test',
                    onSignOut: () {},
                    onCopies: () => copies++,
                  ),
                ),
                AppDropdown<String>(
                  label: 'Elegir',
                  options: const {
                    'Uno': 'Primera opción',
                    'Dos': 'Segunda opción',
                  },
                  value: chosen,
                  onChanged: (v) => setState(() => chosen = v),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tu cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Hola, Ana'), findsOneWidget);
      expect(find.byType(AppMenuRow), findsWidgets);
      await _capture(tester, 'account-menu');
      await tester.tap(find.text('Copias guardadas'));
      await tester.pumpAndSettle();
      expect(copies, 1);
      await tester.tap(find.byTooltip('Tu cuenta'));
      await tester.pumpAndSettle();
      account.value = 'Otra';
      await tester.pumpAndSettle();
      expect(find.text('Hola, Ana'), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Segunda opción').last);
      await tester.pumpAndSettle();
      expect(chosen, 'Dos');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Crear paleta muestra ejemplo sin guardar, selector real y guardar/editar/eliminar local',
    (tester) async {
      tester.view.physicalSize = const Size(412, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final storage = MemoryAppearance();
      final container = ProviderContainer(
        overrides: [
          appearanceRepositoryProvider.overrideWithValue(
            AppearanceRepository(storage),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        for (final (family, asset) in [
          ('Manrope', 'assets/fonts/Manrope-Variable.ttf'),
          ('Newsreader', 'assets/fonts/Newsreader-Variable.ttf'),
          ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
        ]) {
          await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
        }
      });
      await tester.pumpWidget(
        RepaintBoundary(
          key: _captureKey,
          child: UncontrolledProviderScope(
            container: container,
            child: Consumer(
              builder: (context, ref, _) => MaterialApp(
                theme: AppTheme.forSettings(
                  ref.watch(appearanceProvider).settings,
                  Brightness.light,
                ),
                home: const AppearanceScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await container
          .read(appearanceProvider.notifier)
          .select(font: AppFont.newsreader);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Crear mi propia paleta'));
      await tester.tap(find.text('Crear mi propia paleta'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Atardecer');
      expect(storage.saved!.customPalettes, isEmpty);
      await tester.ensureVisible(find.text('Color principal'));
      await tester.tap(find.text('Color principal'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'C65422');
      await tester.pump();
      await tester.ensureVisible(find.text('Usar este color'));
      await tester.tap(find.text('Usar este color'));
      await tester.pumpAndSettle();
      expect(storage.saved!.customPalettes, isEmpty);
      await tester.ensureVisible(find.text('Vista previa antes de guardar'));
      await tester.pumpAndSettle();
      await _capture(tester, 'custom-preview-light');
      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();
      await _capture(tester, 'custom-preview-dark');
      await tester.ensureVisible(find.text('Guardar y usar paleta'));
      await tester.tap(find.text('Guardar y usar paleta'));
      await tester.pumpAndSettle();
      expect(storage.saved!.customPalette!.name, 'Atardecer');
      expect(storage.saved!.customPalette!.primaryRgb, 0xC65422);
      expect(storage.saved!.font, AppFont.newsreader);
      final restored = AppearanceSettings.fromJson(storage.saved!.toJson());
      expect(restored.customPalette!.primaryRgb, 0xC65422);
      final id = restored.customPaletteId!;
      await container
          .read(appearanceProvider.notifier)
          .saveCustom(
            CustomPalette(
              id: id,
              name: 'Atardecer nuevo',
              primaryRgb: 0xC65422,
              secondaryRgb: 0x116677,
              tertiaryRgb: 0x7744AA,
            ),
          );
      expect(storage.saved!.customPalettes.length, 1);
      await container.read(appearanceProvider.notifier).deleteCustom(id);
      expect(storage.saved!.customPalette, isNull);
      expect(storage.saved!.font, AppFont.newsreader);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Inicio con muchos grupos conserva Añadir y acceso a código; Copias está en cuenta',
    (tester) async {
      tester.view.physicalSize = const Size(412, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          for (final path in ['/groups/new', '/join', '/offline'])
            GoRoute(
              path: path,
              builder: (_, _) => Scaffold(body: Text('Destino $path')),
            ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) =>
                  Stream.value(const AuthUser(uid: 'me', displayName: 'Ana')),
            ),
            userProfileProvider.overrideWith((ref) async => null),
            accountClosingProvider.overrideWith((ref) async => false),
            pendingGroupDeletionsProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            membershipsProvider.overrideWith(
              (ref) => Stream.value([
                for (var i = 0; i < 14; i++)
                  GroupMember(
                    uid: 'me',
                    displayName: 'Ana',
                    joinedAt: DateTime.utc(2026),
                    updatedAt: DateTime.utc(2026),
                    groupId: 'g$i',
                    role: GroupRole.owner,
                    isActive: true,
                  ),
              ]),
            ),
            groupProvider.overrideWith(
              (ref, id) => Stream.value(
                Group(
                  id: id,
                  name: 'Grupo $id',
                  currency: 'EUR',
                  timeZone: 'Europe/Madrid',
                  isActive: true,
                  createdBy: 'me',
                  createdAt: DateTime.utc(2026),
                  updatedAt: DateTime.utc(2026),
                ),
              ),
            ),
            dashboardProvider.overrideWith(
              (ref, id) => AsyncData(
                DashboardSummary(
                  groupId: id,
                  incomeCents: 100,
                  withdrawalCents: 0,
                  activePersonsCount: 1,
                  inactivePersonsCount: 0,
                  recentActivity: [],
                ),
              ),
            ),
            photoPresentationProvider.overrideWith(
              (ref, target) => (bytes: null, loading: false),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final before = tester.getCenter(find.text('Añadir'));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -1500),
      );
      await tester.pumpAndSettle();
      expect(tester.getCenter(find.text('Añadir')), before);
      expect(find.text('Entrar con código'), findsNothing);
      await tester.tap(find.byTooltip('Añadir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrar con código'));
      await tester.pumpAndSettle();
      expect(find.text('Destino /join'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tu cuenta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copias guardadas'));
      await tester.pumpAndSettle();
      expect(find.text('Destino /offline'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
