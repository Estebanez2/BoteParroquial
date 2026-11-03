import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _BuildProbe extends StatelessWidget {
  const _BuildProbe(this.onBuild);
  final VoidCallback onBuild;
  @override
  Widget build(BuildContext context) {
    onBuild();
    return const Text('Contenido estable');
  }
}

Widget _host(WidgetBuilder builder, {bool reduced = false}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Theme(
      data: AppTheme.light,
      child: Builder(builder: builder),
    ),
  ),
);

void main() {
  testWidgets(
    'P03 y P05 respetan sus ejes sin reconstruir contenido por frame',
    (tester) async {
      final controller = AnimationController(vsync: tester, value: .25);
      addTearDown(controller.dispose);
      var builds = 0;
      for (final motion in AppPageMotion.values) {
        controller.value = .25;
        await tester.pumpWidget(
          _host(
            (context) => AppPageTransitions.build(
              context,
              controller,
              const AlwaysStoppedAnimation<double>(0),
              _BuildProbe(() => builds++),
              motion: motion,
            ),
          ),
        );
        final before = builds;
        final target = find.ancestor(
          of: find.byType(_BuildProbe),
          matching: find.byType(SlideTransition),
        );
        {
          final offset = tester.widget<SlideTransition>(target).position.value;
          expect(
            motion == AppPageMotion.form ? offset.dy : offset.dx,
            greaterThan(0),
          );
          expect(motion == AppPageMotion.form ? offset.dx : offset.dy, 0);
        }
        controller.value = .55;
        await tester.pump();
        controller.value = 1;
        await tester.pump();
        expect(
          builds,
          before,
          reason: 'El contenido no se reconstruye durante el efecto',
        );
        expect(find.text('Contenido estable'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(
        _host(
          (context) => AppPageTransitions.build(
            context,
            controller,
            controller,
            const Text('Sin efecto'),
            motion: AppPageMotion.group,
          ),
          reduced: true,
        ),
      );
      final content = find.text('Sin efecto');
      expect(
        find.ancestor(of: content, matching: find.byType(ScaleTransition)),
        findsNothing,
      );
    },
  );
}
