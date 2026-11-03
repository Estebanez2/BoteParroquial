import 'package:flutter/material.dart';
import '../design_system.dart';
import 'motion_lab_catalog.dart';

class MotionLabBar extends StatefulWidget {
  const MotionLabBar({
    super.key,
    required this.effect,
    required this.duration,
    required this.onTested,
  });
  final LabBarEffect effect;
  final Duration duration;
  final VoidCallback onTested;
  @override
  State<MotionLabBar> createState() => _MotionLabBarState();
}

class _MotionLabBarState extends State<MotionLabBar> {
  int _selected = 0;
  static const _icons = [
    Icons.home_outlined,
    Icons.receipt_long_outlined,
    Icons.people_outline,
    Icons.bar_chart_rounded,
  ];
  static const _labels = ['Inicio', 'Actividad', 'Personas', 'Informes'];
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final duration = AppMotion.duration(context, widget.duration);
    final isLine = widget.effect == LabBarEffect.underline;
    final isFade = widget.effect == LabBarEffect.fade;
    final curve = widget.effect == LabBarEffect.spring
        ? Curves.easeOutBack
        : AppMotion.curveStandard;
    return Material(
      color: c.surfaceVariant,
      borderRadius: AppRadius.control,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              if (!isFade)
                Positioned.fill(
                  child: AnimatedAlign(
                    alignment: AlignmentDirectional(
                      -1 + 2 * _selected / 3,
                      isLine ? 1 : 0,
                    ),
                    duration: duration,
                    curve: curve,
                    child: SizedBox(
                      width: constraints.maxWidth / 4,
                      height: isLine ? AppSpacing.xs : AppSpacing.controlHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.primaryContainer,
                            borderRadius: AppRadius.control,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: Semantics(
                        selected: i == _selected,
                        button: true,
                        label: '${widget.effect.id} ${_labels[i]}',
                        child: InkWell(
                          onTap: () {
                            setState(() => _selected = i);
                            widget.onTested();
                          },
                          borderRadius: AppRadius.control,
                          child: AnimatedContainer(
                            duration: duration,
                            decoration: BoxDecoration(
                              color: isFade && i == _selected
                                  ? c.primaryContainer
                                  : c.primaryContainer.withValues(alpha: 0),
                              borderRadius: AppRadius.control,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            child: Icon(
                              _icons[i],
                              color: i == _selected ? c.primary : c.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
