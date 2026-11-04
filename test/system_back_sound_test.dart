import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/design_system/platform/app_system_back_sound.dart';

void main() {
  testWidgets(
    'Atrás del sistema y gesto confirmado suenan una vez; botón y gesto cancelado no duplican',
    (tester) async {
      final sounds = <UiSound>[];
      final feedback = AppSystemBackSound();
      final observer = feedback.observer();
      final router = GoRouter(
        observers: [observer],
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Inicio')),
            routes: [
              ShellRoute(
                observers: [feedback.observer()],
                builder: (_, _, child) => child,
                routes: [
                  GoRoute(
                    path: 'group',
                    builder: (_, _) => const Scaffold(body: Text('Grupo')),
                    routes: [
                      GoRoute(
                        path: 'sub',
                        builder: (_, _) =>
                            const Scaffold(body: Text('Sección')),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'page',
                builder: (context, _) => Scaffold(
                  body: AppIconButton(
                    icon: Icons.arrow_back_rounded,
                    label: 'Volver',
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              GoRoute(
                path: 'blocked',
                builder: (_, _) => const PopScope(
                  canPop: false,
                  child: Scaffold(body: Text('Bloqueado')),
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        AppSoundSurface(
          onSound: sounds.add,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerDelegate: router.routerDelegate,
            routeInformationProvider: router.routeInformationProvider,
            routeInformationParser: router.routeInformationParser,
            backButtonDispatcher: feedback.dispatcher,
          ),
        ),
      );
      router.push('/page');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(sounds, [UiSound.back]);
      router.push('/page');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(sounds, [UiSound.back, UiSound.back]);
      router.push('/page');
      await tester.pumpAndSettle();
      final navigator = observer.navigator!;
      navigator.didStartUserGesture();
      navigator.didStopUserGesture();
      expect(sounds.length, 2);
      navigator.didStartUserGesture();
      router.pop();
      await tester.pump();
      navigator.didStopUserGesture();
      await tester.pumpAndSettle();
      expect(sounds.length, 3);
      router.push('/blocked');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(sounds.length, 3);
      expect(find.text('Bloqueado'), findsOneWidget);
      router.go('/');
      await tester.pumpAndSettle();
      router.go('/group/sub');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(sounds.length, 4);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(sounds.length, 5);
    },
  );

  testWidgets(
    'Panel de audio compacto conserva nivel, interruptor y accesibilidad',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 340,
              child: AppSoundSettingsPanel(
                enabled: true,
                volume: 75,
                onEnabled: (_) {},
                onVolume: (_) {},
                onVolumeEnd: (_) {},
                onPreview: () {},
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(AppSoundSettingsPanel)).height,
        lessThan(180),
      );
      expect(find.text('75 %'), findsOneWidget);
      expect(find.byTooltip('Probar sonido'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
