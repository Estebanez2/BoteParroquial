import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/design_system.dart';
import '../../../models/appearance_settings.dart';
import '../providers/appearance_providers.dart';
import 'custom_palette_editor.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appearanceProvider);
    final controller = ref.read(appearanceProvider.notifier);
    final t = AppTypography.of(context);
    return AppScaffold(
      maxWidth: AppSpacing.readingMax,
      appBar: AppTopBar(
        title: 'Ajustes de apariencia',
        leading: AppIconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Volver',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('A tu manera.', style: t.displayLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Elige el ambiente de tu app. Se aplica a todas las pantallas y se recuerda en este móvil.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.section),
          Text('Modo de pantalla', style: t.headingSmall),
          const SizedBox(height: AppSpacing.md),
          AppChoiceBar<AppearanceMode>(
            options: const {
              AppearanceMode.system: 'Sistema',
              AppearanceMode.light: 'Claro',
              AppearanceMode.dark: 'Oscuro',
            },
            value: state.settings.mode,
            enabled: !state.loading,
            onChanged: (mode) => controller.select(mode: mode),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sistema sigue la configuración de tu teléfono.',
            style: t.bodySmall,
          ),
          if (state.saveFailed) ...[
            const SizedBox(height: AppSpacing.md),
            const AppBadge(
              'No se pudo guardar la elección',
              tone: AppTone.warning,
            ),
            AppButton(
              label: 'Reintentar guardado',
              variant: AppButtonVariant.ghost,
              onPressed: () => controller.select(),
            ),
          ],
          const SizedBox(height: AppSpacing.section),
          Text('Tipo de letra', style: t.headingSmall),
          const SizedBox(height: AppSpacing.md),
          AppDropdown<AppFont>(
            label: 'Letra de toda la app',
            options: const {
              AppFont.manrope: 'Manrope · Moderna',
              AppFont.newsreader: 'Newsreader · Con serif',
              AppFont.system: 'Sistema · La de tu móvil',
            },
            value: state.settings.font,
            enabled: !state.loading,
            onChanged: (font) {
              if (font != null) controller.select(font: font);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Personas, movimientos y el bote de tu comunidad.',
            style: t.headingMedium,
          ),
          const SizedBox(height: AppSpacing.section),
          Text('Tu paleta', style: t.headingSmall),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Crear mi propia paleta',
            leadingIcon: Icons.add_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: state.loading
                ? null
                : () => showCustomPaletteEditor(context),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final custom in state.settings.customPalettes) ...[
            AppPaletteTile(
              label: custom.name,
              description: 'Tu paleta · Guardada en este móvil',
              light: AppColors.forCustom(custom, Brightness.light),
              dark: AppColors.forCustom(custom, Brightness.dark),
              selected: state.settings.customPaletteId == custom.id,
              onTap: () => controller.selectCustom(custom.id),
            ),
            AppAdaptiveRow(
              children: [
                AppButton(
                  label: 'Editar ${custom.name}',
                  variant: AppButtonVariant.ghost,
                  leadingIcon: Icons.edit_outlined,
                  onPressed: () =>
                      showCustomPaletteEditor(context, palette: custom),
                ),
                AppButton(
                  label: 'Eliminar ${custom.name}',
                  variant: AppButtonVariant.ghost,
                  leadingIcon: Icons.delete_outline,
                  onPressed: () async {
                    final confirmed = await AppDialog.show(
                      context,
                      title: '¿Eliminar esta paleta local?',
                      description:
                          'Solo se elimina ${custom.name} de este móvil. Si estaba activa, volverás a la paleta predefinida anterior.',
                      confirmLabel: 'Eliminar paleta',
                      variant: AppDialogVariant.warning,
                    );
                    if (context.mounted && confirmed) {
                      await controller.deleteCustom(custom.id);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          for (final palette in AppPalette.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppPaletteTile(
                label: AppPaletteCatalog.label(palette),
                description: AppPaletteCatalog.description(palette),
                light: AppColors.forPalette(palette, Brightness.light),
                dark: AppColors.forPalette(palette, Brightness.dark),
                selected:
                    state.settings.customPalette == null &&
                    state.settings.palette == palette,
                onTap: () {
                  if (!state.loading) controller.select(palette: palette);
                },
              ),
            ),
        ],
      ),
    );
  }
}
