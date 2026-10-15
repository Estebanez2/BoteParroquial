import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../design_system.dart';

/// Isolated development gallery. All records and monetary values are fixtures.
class DesignSystemShowcase extends StatefulWidget {
  const DesignSystemShowcase({
    super.key,
    this.initialSection = 0,
    this.initialDark = false,
  });
  final int initialSection;
  final bool initialDark;
  @override
  State<DesignSystemShowcase> createState() => _DesignSystemShowcaseState();
}

class _DesignSystemShowcaseState extends State<DesignSystemShowcase> {
  late bool _dark = widget.initialDark;
  late int _section = widget.initialSection;
  final _name = TextEditingController();
  final _money = TextEditingController();
  final _scroll = ScrollController();
  String? _role = 'admin';
  DateTime? _date = DateTime(2026, 10, 15);
  int? _amount;
  static const _items = [
    AppNavigationItem(label: 'Identidad', icon: Icons.grid_view_outlined),
    AppNavigationItem(label: 'Controles', icon: Icons.tune_rounded),
    AppNavigationItem(
      label: 'Feedback',
      icon: Icons.chat_bubble_outline_rounded,
    ),
    AppNavigationItem(label: 'Tokens', icon: Icons.palette_outlined),
  ];
  @override
  void dispose() {
    _name.dispose();
    _money.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _select(int index) {
    setState(() => _section = index);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BoteParroquial · Estudio visual',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
    themeAnimationDuration:
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations
        ? Duration.zero
        : AppMotion.durationNormal,
    locale: const Locale('es'),
    supportedLocales: const [Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Builder(
      builder: (context) {
        final wide = MediaQuery.sizeOf(context).width >= 860;
        final c = AppColors.of(context);
        final t = AppTypography.of(context);
        final page = SingleChildScrollView(
          controller: _scroll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!wide) ...[
                  const AppBrand(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
                AppReveal(
                  child: switch (_section) {
                    0 => _identity(context),
                    1 => _controls(context),
                    2 => _feedback(context),
                    _ => _tokens(context),
                  },
                ),
                Divider(color: c.divider),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'BoteParroquial / Design System v0.1',
                  style: t.labelSmall.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Entorno de desarrollo · Todos los datos son de ejemplo.',
                  style: t.bodySmall.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
        return AppScaffold(
          padding: EdgeInsets.zero,
          scroll: false,
          appBar: AppTopBar(
            title: 'Estudio visual',
            actions: [
              AppIconButton(
                icon: _dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                label: _dark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
                variant: AppIconButtonVariant.ghost,
                onPressed: () => setState(() => _dark = !_dark),
              ),
            ],
          ),
          bottomNavigation: wide
              ? null
              : AppBottomNavigation(
                  items: _items,
                  selectedIndex: _section,
                  onSelected: _select,
                ),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 220,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppBrand(compact: true),
                            const SizedBox(height: AppSpacing.lg),
                            Text('BoteParroquial', style: t.headingSmall),
                            const SizedBox(height: AppSpacing.sm),
                            const AppBadge('DESIGN LAB', tone: AppTone.primary),
                            const SizedBox(height: AppSpacing.xxxl),
                            ...List.generate(
                              _items.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: AppButton(
                                  label: _items[index].label,
                                  leadingIcon: _items[index].icon,
                                  fullWidth: true,
                                  variant: _section == index
                                      ? AppButtonVariant.secondary
                                      : AppButtonVariant.ghost,
                                  onPressed: () => _select(index),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Sereno. Cercano.\nHecho para compartir.',
                              style: t.bodySmall.copyWith(color: c.textMuted),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                    VerticalDivider(width: 1, color: c.divider),
                    Expanded(child: page),
                  ],
                )
              : page,
        );
      },
    ),
  );

  Widget _intro(
    BuildContext context,
    String eyebrow,
    String title,
    String description,
  ) {
    final c = AppColors.of(context);
    final t = AppTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: t.labelSmall.copyWith(color: c.secondary)),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: t.displayLarge),
        const SizedBox(height: AppSpacing.lg),
        Text(description, style: t.bodyLarge.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _identity(BuildContext context) {
    final t = AppTypography.of(context);
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _intro(
          context,
          '01 / UNA IDENTIDAD COMPARTIDA',
          'Lo que compartimos,\nen buenas manos.',
          'Un lugar claro y cercano para cuidar lo que construimos juntos.',
        ),
        const BalanceCard(
          balanceCents: 243050,
          currency: 'EUR',
          incomeCents: 48000,
          withdrawalCents: 12550,
          caption: 'Cifras de ejemplo · Octubre 2026',
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              SizedBox(
                width: constraints.maxWidth >= 440
                    ? (constraints.maxWidth - AppSpacing.lg) / 2
                    : constraints.maxWidth,
                child: const StatisticCard(
                  label: 'Personas al día',
                  value: '18 de 24',
                  icon: Icons.people_outline,
                  caption: 'Una comunidad que suma',
                ),
              ),
              SizedBox(
                width: constraints.maxWidth >= 440
                    ? (constraints.maxWidth - AppSpacing.lg) / 2
                    : constraints.maxWidth,
                child: const StatisticCard(
                  label: 'Pendiente este mes',
                  value: '120,00 €',
                  icon: Icons.schedule_outlined,
                  caption: 'Datos de muestra',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        AppSection(
          title: 'Pequeños detalles, una misma voz.',
          eyebrow: '02 / PERSONAS Y ESTADOS',
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppAvatar(name: 'María García', showIndicator: true),
                    AppAvatar(name: 'Antonio Ruiz'),
                    AppAvatar(name: 'Lucía Pérez', size: AppAvatarSize.small),
                    AppAvatar(name: 'Comunidad', size: AppAvatarSize.large),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: AppStatus.values
                      .map((status) => StatusChip(status))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        AppSection(
          title: 'Cada cifra se entiende.',
          eyebrow: '03 / LECTURA FINANCIERA',
          description: 'El signo y la etiqueta acompañan al color.',
          child: AppCard(
            child: Wrap(
              spacing: AppSpacing.xxl,
              runSpacing: AppSpacing.lg,
              children: const [
                MoneyText(2000, variant: MoneyTextVariant.income),
                MoneyText(5000, variant: MoneyTextVariant.withdrawal),
                MoneyText(-3000),
              ],
            ),
          ),
        ),
        AppSection(
          title: 'Superficies que respiran.',
          eyebrow: '04 / CARDS',
          child: Column(
            children: [
              for (final variant in AppCardVariant.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    variant: variant,
                    onTap: () => AppSnackbar.show(
                      context,
                      'Card interactiva seleccionada.',
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.layers_outlined, color: c.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(switch (variant) {
                            AppCardVariant.standard => 'Superficie base',
                            AppCardVariant.elevated => 'Elevación suave',
                            AppCardVariant.outlined => 'Contorno definido',
                            AppCardVariant.interactive => 'Toca para explorar',
                          }, style: t.labelLarge),
                        ),
                        if (variant == AppCardVariant.interactive)
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: c.textSecondary,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _controls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _intro(
          context,
          '02 / INTERACCIÓN',
          'Sencillo de usar.\nConsistente siempre.',
          'Acciones claras, campos amables y estados que acompañan.',
        ),
        AppSection(
          title: 'Botones',
          description: 'Jerarquía, iconos y estados de interacción.',
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final variant in AppButtonVariant.values)
                      AppButton(
                        label: switch (variant) {
                          AppButtonVariant.primary => 'Añadir ingreso',
                          AppButtonVariant.secondary => 'Ver detalle',
                          AppButtonVariant.outline => 'Editar',
                          AppButtonVariant.ghost => 'Más opciones',
                          AppButtonVariant.destructive => 'Anular',
                        },
                        leadingIcon: variant == AppButtonVariant.primary
                            ? Icons.add_rounded
                            : null,
                        trailingIcon: variant == AppButtonVariant.secondary
                            ? Icons.arrow_forward_rounded
                            : null,
                        variant: variant,
                        onPressed: () => AppSnackbar.show(
                          context,
                          'Acción de ejemplo, sin guardar datos.',
                          variant: AppSnackbarVariant.success,
                        ),
                      ),
                    const AppButton(
                      label: 'Guardando',
                      onPressed: null,
                      loading: true,
                    ),
                    const AppButton(label: 'No disponible', onPressed: null),
                    AppButton(
                      label: 'Compacto',
                      size: AppButtonSize.compact,
                      onPressed: () =>
                          AppSnackbar.show(context, 'Botón compacto.'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Continuar',
                  trailingIcon: Icons.arrow_forward_rounded,
                  fullWidth: true,
                  onPressed: () =>
                      AppSnackbar.show(context, 'Puedes continuar.'),
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final variant in AppIconButtonVariant.values)
                      AppIconButton(
                        icon: variant == AppIconButtonVariant.danger
                            ? Icons.delete_outline
                            : Icons.edit_outlined,
                        label: 'Ejemplo ${variant.name}',
                        variant: variant,
                        onPressed: () =>
                            AppSnackbar.show(context, 'Acción de icono.'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        AppSection(
          title: 'Campos de entrada',
          description: 'Los valores de esta galería nunca se guardan.',
          child: AppCard(
            child: Column(
              children: [
                AppTextField(
                  label: 'Nombre de la persona',
                  hint: 'Por ejemplo, María García',
                  icon: Icons.person_outline,
                  controller: _name,
                  helper: 'Así se mostrará en el grupo.',
                ),
                const SizedBox(height: AppSpacing.xl),
                const AppTextField(
                  label: 'Contraseña de ejemplo',
                  password: true,
                  hint: 'Campo visual, no se usa en el login Google',
                ),
                const SizedBox(height: AppSpacing.xl),
                const AppTextField(
                  label: 'Campo con error',
                  initialValue: 'Ejemplo',
                  error: 'Revisa este dato antes de continuar.',
                ),
                const SizedBox(height: AppSpacing.xl),
                const AppTextField(
                  label: 'Solo lectura',
                  initialValue: 'Comunidad',
                  readOnly: true,
                ),
                const SizedBox(height: AppSpacing.xl),
                const AppTextField(
                  label: 'Deshabilitado',
                  initialValue: 'No disponible',
                  enabled: false,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppMoneyField(
                  currency: 'EUR',
                  controller: _money,
                  onChangedCents: (value) => setState(() => _amount = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Valor de desarrollo: ${_amount ?? '—'} céntimos',
                    style: AppTypography.of(context).bodySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppDropdown<String>(
                  label: 'Rol de ejemplo',
                  options: const {
                    'admin': 'Administrador',
                    'member': 'Miembro',
                  },
                  value: _role,
                  onChanged: (value) => setState(() => _role = value),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppDateField(
                  label: 'Fecha',
                  value: _date,
                  onChanged: (value) => setState(() => _date = value),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _feedback(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _intro(
        context,
        '03 / FEEDBACK',
        'Siempre sabes\nqué está pasando.',
        'Mensajes humanos y decisiones sin sorpresas.',
      ),
      AppSection(
        title: 'Estados vacíos',
        child: AppCard(
          child: EmptyState(
            icon: Icons.people_outline,
            title: 'Aquí empieza vuestra comunidad',
            description:
                'Cuando añadas personas, podrás verlas y cuidarlas desde un mismo lugar.',
            actionLabel: 'Añadir primera persona',
            onAction: () =>
                AppSnackbar.show(context, 'Solo es una muestra visual.'),
          ),
        ),
      ),
      AppSection(
        title: 'Diálogos',
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final variant in AppDialogVariant.values)
              AppButton(
                label: switch (variant) {
                  AppDialogVariant.information => 'Información',
                  AppDialogVariant.confirmation => 'Confirmación',
                  AppDialogVariant.warning => 'Advertencia',
                  AppDialogVariant.danger => 'Acción delicada',
                },
                variant: AppButtonVariant.outline,
                onPressed: () async {
                  final confirmed = await AppDialog.show(
                    context,
                    title: variant == AppDialogVariant.danger
                        ? '¿Anular este movimiento?'
                        : 'Una decisión con contexto',
                    description:
                        'Este diálogo es una demostración. No cambia ni elimina ningún dato.',
                    variant: variant,
                    confirmLabel: variant == AppDialogVariant.danger
                        ? 'Anular'
                        : 'Entendido',
                  );
                  if (context.mounted) {
                    AppSnackbar.show(
                      context,
                      confirmed
                          ? 'Has confirmado la demostración.'
                          : 'Operación cancelada.',
                    );
                  }
                },
              ),
          ],
        ),
      ),
      AppSection(
        title: 'Mensajes breves',
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final variant in AppSnackbarVariant.values)
              AppButton(
                label: switch (variant) {
                  AppSnackbarVariant.success => 'Éxito',
                  AppSnackbarVariant.error => 'Error',
                  AppSnackbarVariant.warning => 'Aviso',
                  AppSnackbarVariant.info => 'Información breve',
                },
                variant: AppButtonVariant.secondary,
                onPressed: () => AppSnackbar.show(context, switch (variant) {
                  AppSnackbarVariant.success =>
                    'Todo listo. El cambio se ha completado.',
                  AppSnackbarVariant.error =>
                    'No se pudo completar. Puedes volver a intentarlo.',
                  AppSnackbarVariant.warning =>
                    'Comprueba los datos antes de continuar.',
                  AppSnackbarVariant.info => 'Esta es una vista de ejemplo.',
                }, variant: variant),
              ),
          ],
        ),
      ),
      AppSection(
        title: 'Panel inferior',
        child: AppButton(
          label: 'Abrir panel',
          variant: AppButtonVariant.outline,
          leadingIcon: Icons.vertical_align_top_rounded,
          onPressed: () => AppBottomSheet.show<void>(
            context,
            title: 'Un espacio para los detalles',
            builder: (sheetContext) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panel de ejemplo. Se adapta al teclado, a la pantalla y al modo de color.',
                ),
                const SizedBox(height: AppSpacing.xl),
                const AppTextField(
                  label: 'Nota de ejemplo',
                  hint: 'Escribe algo…',
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Listo',
                  fullWidth: true,
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        ),
      ),
      const AppSection(
        title: 'Cargando',
        child: AppCard(
          child: Row(
            children: [
              LoadingIndicator(),
              SizedBox(width: AppSpacing.lg),
              Expanded(child: Text('Preparando la información…')),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _tokens(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTypography.of(context);
    final swatches = <String, Color>{
      'primary': c.primary,
      'primaryContainer': c.primaryContainer,
      'secondary': c.secondary,
      'secondaryContainer': c.secondaryContainer,
      'background': c.background,
      'surface': c.surface,
      'surfaceVariant': c.surfaceVariant,
      'textPrimary': c.textPrimary,
      'textSecondary': c.textSecondary,
      'textMuted': c.textMuted,
      'success': c.success,
      'warning': c.warning,
      'danger': c.danger,
      'info': c.info,
      'divider': c.divider,
      'outline': c.outline,
    };
    final styles = <String, TextStyle>{
      'displayLarge': t.displayLarge,
      'headingLarge': t.headingLarge,
      'headingMedium': t.headingMedium,
      'headingSmall': t.headingSmall,
      'bodyLarge': t.bodyLarge,
      'bodyMedium': t.bodyMedium,
      'bodySmall': t.bodySmall,
      'labelLarge': t.labelLarge,
      'labelMedium': t.labelMedium,
      'labelSmall': t.labelSmall,
      'moneyHero': t.moneyHero,
      'moneyLarge': t.moneyLarge,
      'moneyMedium': t.moneyMedium,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _intro(
          context,
          '04 / FUNDAMENTOS',
          'Una misma raíz.\nMuchas posibilidades.',
          'Tokens semánticos para que cada pantalla hable el mismo idioma.',
        ),
        AppSection(
          title: 'Paleta de color',
          description: 'Cambia el modo para revisar también la paleta oscura.',
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: swatches.entries
                .map(
                  (entry) => SizedBox(
                    width: 148,
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: entry.value,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppRadius.large),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(entry.key, style: t.labelSmall),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '#${entry.value.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                                  style: t.bodySmall.copyWith(
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        AppSection(
          title: 'Tipografía',
          description:
              'Manrope para lectura y cifras. Newsreader para los momentos editoriales.',
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: styles.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: t.labelSmall.copyWith(color: c.textMuted),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            entry.key.startsWith('money')
                                ? '2.430,50 €'
                                : 'Compartir nos une.',
                            style: entry.value,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        AppSection(
          title: 'Espaciado',
          child: AppCard(
            child: Column(
              children: [
                for (final entry in <String, double>{
                  'xs': AppSpacing.xs,
                  'sm': AppSpacing.sm,
                  'md': AppSpacing.md,
                  'lg': AppSpacing.lg,
                  'xl': AppSpacing.xl,
                  'xxl': AppSpacing.xxl,
                }.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            '${entry.key} / ${entry.value.toInt()}',
                            style: t.labelMedium,
                          ),
                        ),
                        Container(
                          width: entry.value * 3,
                          height: AppSpacing.md,
                          decoration: BoxDecoration(
                            color: c.primary,
                            borderRadius: AppRadius.control,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        AppSection(
          title: 'Radios y superficies',
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final entry in <String, double>{
                'Small': AppRadius.small,
                'Medium': AppRadius.medium,
                'Large': AppRadius.large,
                'Extra large': AppRadius.extraLarge,
                'Pill': AppRadius.pill,
              }.entries)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.divider),
                    borderRadius: BorderRadius.circular(entry.value),
                    boxShadow: AppShadows.soft(context),
                  ),
                  child: Text(entry.key, style: t.labelMedium),
                ),
            ],
          ),
        ),
        const AppSection(
          title: 'Movimiento contenido',
          description:
              '140 / 220 / 320 ms. Sin rebotes y con respeto al ajuste de movimiento reducido.',
          child: AppBadge(
            'Sutil y funcional',
            tone: AppTone.primary,
            icon: Icons.animation_rounded,
          ),
        ),
      ],
    );
  }
}
