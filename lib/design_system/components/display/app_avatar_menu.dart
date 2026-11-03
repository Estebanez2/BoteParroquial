import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';
import '../navigation/app_menu_row.dart';
import 'app_avatar.dart';
import '../navigation/app_menu_surface.dart';

class AppAvatarMenu extends StatefulWidget {
  const AppAvatarMenu({
    super.key,
    required this.name,
    required this.onSignOut,
    this.email,
    this.image,
    this.enabled = true,
    this.accountId,
    this.onPhoto,
    this.onProfile,
    this.loading = false,
    this.onCopies,
  });
  final String name;
  final String? email;
  final ImageProvider? image;
  final VoidCallback onSignOut;
  final bool enabled;
  final String? accountId;
  final VoidCallback? onPhoto;
  final VoidCallback? onProfile;
  final bool loading;
  final VoidCallback? onCopies;
  @override
  State<AppAvatarMenu> createState() => _AppAvatarMenuState();
}

class _AppAvatarMenuState extends State<AppAvatarMenu> {
  final _menu = GlobalKey<PopupMenuButtonState<String>>();
  bool _open = false;
  @override
  void didUpdateWidget(covariant AppAvatarMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_open &&
        (oldWidget.accountId != widget.accountId ||
            oldWidget.name != widget.name ||
            oldWidget.email != widget.email)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _open) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    key: _menu,
    tooltip: 'Tu cuenta',
    enabled: widget.enabled,
    offset: const Offset(0, AppSpacing.sm),
    constraints: const BoxConstraints(
      minWidth: AppSpacing.menuMinWidth,
      maxWidth: AppSpacing.menuMaxWidth,
    ),
    onOpened: () => _open = true,
    onCanceled: () => _open = false,
    onSelected: (value) {
      _open = false;
      if (value == 'photo') {
        widget.onPhoto?.call();
      } else if (value == 'profile') {
        widget.onProfile?.call();
      } else if (value == 'copies') {
        widget.onCopies?.call();
      } else {
        widget.onSignOut();
      }
    },
    itemBuilder: (context) => [
      PopupMenuItem<String>(
        enabled: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.of(context).primaryContainer,
            borderRadius: AppRadius.control,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                name: widget.name,
                image: widget.image,
                loading: widget.loading,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Hola, ${widget.name}',
                style: AppTypography.of(context).headingSmall,
              ),
              if (widget.email != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(widget.email!, style: AppTypography.of(context).bodySmall),
              ],
            ],
          ),
        ),
      ),
      const PopupMenuDivider(),
      if (widget.onProfile != null)
        const PopupMenuItem(
          value: 'profile',
          child: AppMenuRow(
            label: 'Mi perfil',
            icon: Icons.person_outline_rounded,
          ),
        ),
      if (widget.onPhoto != null)
        const PopupMenuItem(
          value: 'photo',
          child: AppMenuRow(
            label: 'Mi foto de cuenta',
            icon: Icons.photo_camera_outlined,
          ),
        ),
      if (widget.onCopies != null)
        const PopupMenuItem(
          value: 'copies',
          child: AppMenuRow(
            label: 'Copias guardadas',
            icon: Icons.inventory_2_outlined,
          ),
        ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'sign-out',
        child: AppMenuRow(
          label: 'Cerrar sesión',
          icon: Icons.logout_rounded,
          destructive: true,
        ),
      ),
    ],
    child: AppMenuSurface(
      enabled: widget.enabled,
      onPressed: () => _menu.currentState?.showButtonMenu(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAvatar(
              name: widget.name,
              image: widget.image,
              loading: widget.loading,
              size: AppAvatarSize.small,
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    ),
  );
}
