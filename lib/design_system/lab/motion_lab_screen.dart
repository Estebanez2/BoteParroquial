import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../design_system.dart';
import 'motion_lab_catalog.dart';
import 'motion_lab_transitions.dart';
import 'motion_lab_buttons.dart';
import 'motion_lab_bar.dart';

/// Explicit temporary opt-in for testing APKs; never enabled in release.
const motionLabEnabled = !kReleaseMode;
const motionLabPath = '/testing/motion';

enum _LabSection { pages, buttons, bars }

class MotionLabScreen extends StatefulWidget {
  const MotionLabScreen({super.key});
  @override
  State<MotionLabScreen> createState() => _MotionLabScreenState();
}

class _MotionLabScreenState extends State<MotionLabScreen> {
  final _navigator = GlobalKey<NavigatorState>();
  final _effect = ValueNotifier(LabPageEffect.none);
  final _revision = ValueNotifier(0);
  final _scroll = ScrollController();
  final _tested = <String>{};
  _LabSection _section = _LabSection.pages;
  double _milliseconds = 400;
  bool _opening = false;
  Duration get _duration => Duration(milliseconds: _milliseconds.round());

  @override
  void dispose() {
    _effect.dispose();
    _revision.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _update(VoidCallback change) {
    if (!mounted) return;
    change();
    _revision.value++;
  }

  Future<void> _open(LabPageEffect effect) async {
    if (_opening) return;
    _opening = true;
    _effect.value = effect;
    _update(() => _tested.add(effect.id));
    try {
      await _navigator.currentState!.push<void>(
        MotionLabTransitions.route(
          effect: effect,
          duration: _duration,
          reduced: MediaQuery.disableAnimationsOf(context),
          child: _LabDestination(effect: effect, duration: _duration),
        ),
      );
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!motionLabEnabled) return const SizedBox.shrink();
    return NavigatorPopHandler<void>(
      onPopWithResult: (_) => _navigator.currentState?.pop(),
      child: Navigator(
        key: _navigator,
        onGenerateInitialRoutes: (_, _) => [
          MotionLabTransitions.route(
            effect: LabPageEffect.none,
            duration: _duration,
            outgoingEffect: _effect,
            child: ValueListenableBuilder<int>(
              valueListenable: _revision,
              builder: (_, _, _) => Builder(builder: _catalogue),
            ),
          ),
        ],
        onGenerateRoute: (_) => null,
      ),
    );
  }

  Widget _catalogue(BuildContext labContext) {
    final t = AppTypography.of(labContext);
    return AppScaffold(
      scroll: false,
      maxWidth: AppSpacing.readingMax,
      bottomNavigation: AppBottomNavigation(
        items: const [
          AppNavigationItem(label: 'Pantallas', icon: Icons.layers_outlined),
          AppNavigationItem(label: 'Botones', icon: Icons.touch_app_outlined),
          AppNavigationItem(label: 'Barra', icon: Icons.view_week_outlined),
        ],
        selectedIndex: _section.index,
        onSelected: (index) {
          _update(() => _section = _LabSection.values[index]);
          if (_scroll.hasClients) _scroll.jumpTo(0);
        },
      ),
      appBar: AppTopBar(
        title: 'Laboratorio de animaciones',
        leading: AppIconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Salir del laboratorio',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      child: ListView(
        controller: _scroll,
        children: [
          const AppBadge('TEMPORAL · SOLO PRUEBAS', tone: AppTone.tertiary),
          const SizedBox(height: AppSpacing.sm),
          Text('Encuentra el movimiento que te gusta.', style: t.headingLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '24 transiciones, 12 botones y 4 barras. Dime sus códigos (por ejemplo, P10 + B07). No se guarda ni aplica una elección a la app.',
            style: t.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Duración: ${_milliseconds.round()} ms · ${_tested.length} probadas',
            style: t.labelSmall,
          ),
          Slider(
            value: _milliseconds,
            min: 150,
            max: 1000,
            divisions: 17,
            label: '${_milliseconds.round()} ms',
            semanticFormatterCallback: (v) => '${v.round()} milisegundos',
            onChanged: (v) => _update(() => _milliseconds = v),
          ),
          if (MediaQuery.disableAnimationsOf(labContext))
            const Text(
              'El móvil tiene el movimiento reducido: las demostraciones serán estáticas.',
            ),
          const SizedBox(height: AppSpacing.md),
          if (_section == _LabSection.pages)
            for (final effect in LabPageEffect.values)
              _demoCard(
                effect.id,
                effect.title,
                effect.description,
                AppButton(
                  key: ValueKey(effect.id),
                  label: 'Abrir ${effect.id}',
                  leadingIcon: Icons.open_in_new_rounded,
                  onPressed: () => _open(effect),
                  fullWidth: true,
                ),
              ),
          if (_section == _LabSection.buttons)
            for (final effect in LabButtonEffect.values)
              _demoCard(
                effect.id,
                effect.title,
                effect.description,
                MotionLabButton(
                  key: ValueKey(effect.id),
                  effect: effect,
                  duration: _duration,
                  onTested: () {
                    _update(() => _tested.add(effect.id));
                  },
                ),
              ),
          if (_section == _LabSection.bars)
            for (final effect in LabBarEffect.values)
              _demoCard(
                effect.id,
                effect.title,
                'Toca los cuatro iconos: solo cambia esta muestra.',
                MotionLabBar(
                  key: ValueKey(effect.id),
                  effect: effect,
                  duration: _duration,
                  onTested: () => _update(() => _tested.add(effect.id)),
                ),
              ),
        ],
      ),
    );
  }

  Widget _demoCard(String id, String title, String description, Widget demo) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$id · $title',
                style: AppTypography.of(context).headingSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(description, style: AppTypography.of(context).bodySmall),
              const SizedBox(height: AppSpacing.xl),
              demo,
            ],
          ),
        ),
      );
}

class _LabDestination extends StatelessWidget {
  const _LabDestination({required this.effect, required this.duration});
  final LabPageEffect effect;
  final Duration duration;
  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return AppScaffold(
      maxWidth: AppSpacing.readingMax,
      appBar: AppTopBar(
        title: 'Prueba ${effect.id}',
        leading: AppIconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Volver al catálogo',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBadge('CONTENIDO FICTICIO', tone: AppTone.tertiary),
          const SizedBox(height: AppSpacing.xl),
          Text(effect.id, style: t.displayLarge),
          Text(effect.title, style: t.headingLarge),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${effect.description}\nDuración elegida: ${duration.inMilliseconds} ms. Atrás permite comparar la salida.',
            style: t.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          const AppHeroPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: AppSpacing.avatarMedium,
                ),
                SizedBox(height: AppSpacing.lg),
                Text('La misma vista en todas las pruebas'),
                SizedBox(height: AppSpacing.sm),
                Text('Formas, texto y paneles para comparar el movimiento.'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppCard(
            child: ListTile(
              leading: Icon(Icons.people_outline),
              title: Text('Grupo de ejemplo'),
              subtitle: Text('No crea personas, movimientos ni grupos.'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Volver y probar otra',
            onPressed: () => Navigator.of(context).pop(),
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
