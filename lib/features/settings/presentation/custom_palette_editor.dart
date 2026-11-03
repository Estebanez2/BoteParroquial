import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/design_system.dart';
import '../../../models/custom_palette.dart';
import '../providers/appearance_providers.dart';

Future<void> showCustomPaletteEditor(
  BuildContext context, {
  CustomPalette? palette,
}) => Navigator.of(context, rootNavigator: true).push<void>(
  AppPageTransitions.formRoute(context, CustomPaletteEditor(palette: palette)),
);

class CustomPaletteEditor extends ConsumerStatefulWidget {
  const CustomPaletteEditor({super.key, this.palette});
  final CustomPalette? palette;
  @override
  ConsumerState<CustomPaletteEditor> createState() =>
      _CustomPaletteEditorState();
}

class _CustomPaletteEditorState extends ConsumerState<CustomPaletteEditor> {
  final _guard = GlobalKey<AppFormGuardState>();
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final String _id;
  late Color _primary, _secondary, _tertiary;
  late List<int> _initial;
  bool _saving = false;
  Brightness _preview = Brightness.light;
  int _rgb(Color c) => c.toARGB32() & 0xFFFFFF;
  CustomPalette get _palette => CustomPalette(
    id: _id,
    name: _name.text.trim(),
    primaryRgb: _rgb(_primary),
    secondaryRgb: _rgb(_secondary),
    tertiaryRgb: _rgb(_tertiary),
  );
  @override
  void initState() {
    super.initState();
    final original = widget.palette;
    _name = TextEditingController(text: original?.name ?? '');
    _id = original?.id ?? ref.read(appearanceRepositoryProvider).newPaletteId();
    _primary = original == null
        ? AppColors.light.primary
        : Color(0xFF000000 | original.primaryRgb);
    _secondary = original == null
        ? AppColors.light.secondary
        : Color(0xFF000000 | original.secondaryRgb);
    _tertiary = original == null
        ? AppColors.light.tertiary
        : Color(0xFF000000 | original.tertiaryRgb);
    _initial = [_rgb(_primary), _rgb(_secondary), _rgb(_tertiary)];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final saved = await ref
        .read(appearanceProvider.notifier)
        .saveCustom(_palette);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      _guard.currentState?.saved();
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appearanceProvider).settings;
    final previewSettings = settings.copyWith(
      customPalettes: [_palette],
      customPaletteId: _id,
    );
    // A draft without a name still has a valid visual preview.
    final previewPalette = CustomPalette(
      id: _id,
      name: 'Vista previa',
      primaryRgb: _rgb(_primary),
      secondaryRgb: _rgb(_secondary),
      tertiaryRgb: _rgb(_tertiary),
    );
    final theme = AppTheme.forSettings(
      previewSettings.copyWith(customPalettes: [previewPalette]),
      _preview,
    );
    return AppFormGuard(
      key: _guard,
      busy: _saving,
      changes: _name,
      isDirty: () =>
          _name.text != (widget.palette?.name ?? '') ||
          _rgb(_primary) != _initial[0] ||
          _rgb(_secondary) != _initial[1] ||
          _rgb(_tertiary) != _initial[2],
      child: AppScaffold(
        maxWidth: AppSpacing.readingMax,
        appBar: AppTopBar(
          title: widget.palette == null
              ? 'Tu propia paleta'
              : 'Editar tu paleta',
          leading: AppIconButton(
            icon: Icons.arrow_back_rounded,
            label: 'Volver a apariencia',
            onPressed: () => _guard.currentState?.requestExit(),
          ),
        ),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tres colores. Tu estilo.',
                style: AppTypography.of(context).editorialTitle,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Se guarda solo en este móvil. Ajustamos los tonos de texto y los fondos para mantener el contraste; tus colores originales se conservan.',
                style: AppTypography.of(context).bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: 'Nombre de la paleta',
                controller: _name,
                enabled: !_saving,
                validator: (raw) =>
                    raw == null || raw.trim().isEmpty || raw.trim().length > 40
                    ? 'Escribe de 1 a 40 caracteres.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppColorField(
                label: 'Color principal',
                value: _primary,
                enabled: !_saving,
                onChanged: (color) => setState(() => _primary = color),
              ),
              const SizedBox(height: AppSpacing.md),
              AppColorField(
                label: 'Color complementario',
                value: _secondary,
                enabled: !_saving,
                onChanged: (color) => setState(() => _secondary = color),
              ),
              const SizedBox(height: AppSpacing.md),
              AppColorField(
                label: 'Tercer acento',
                value: _tertiary,
                enabled: !_saving,
                onChanged: (color) => setState(() => _tertiary = color),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Vista previa antes de guardar',
                style: AppTypography.of(context).headingSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              AppChoiceBar<Brightness>(
                options: const {
                  Brightness.light: 'Claro',
                  Brightness.dark: 'Oscuro',
                },
                value: _preview,
                onChanged: (value) => setState(() => _preview = value),
              ),
              const SizedBox(height: AppSpacing.md),
              AppThemePreview(theme: theme),
              const SizedBox(height: AppSpacing.xl),
              if (ref.watch(appearanceProvider).saveFailed)
                const Text(
                  'No se pudo guardar. Tu propuesta sigue aquí para reintentar.',
                ),
              AppButton(
                label: 'Guardar y usar paleta',
                validate: () => _form.currentState?.validate() ?? false,
                leadingIcon: Icons.palette_outlined,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
