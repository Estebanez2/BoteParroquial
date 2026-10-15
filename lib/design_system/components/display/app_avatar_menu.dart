import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import 'app_avatar.dart';

class AppAvatarMenu extends StatefulWidget {
  const AppAvatarMenu({
    super.key,
    required this.name,
    required this.onSignOut,
    this.email,
    this.image,
    this.enabled = true,
    this.accountId,
  });
  final String name;
  final String? email;
  final ImageProvider? image;
  final VoidCallback onSignOut;
  final bool enabled;
  final String? accountId;
  @override
  State<AppAvatarMenu> createState() => _AppAvatarMenuState();
}

class _AppAvatarMenuState extends State<AppAvatarMenu> {
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
    tooltip: 'Tu cuenta',
    enabled: widget.enabled,
    onOpened: () => _open = true,
    onCanceled: () => _open = false,
    onSelected: (_) {
      _open = false;
      widget.onSignOut();
    },
    itemBuilder: (context) => [
      PopupMenuItem<String>(
        enabled: false,
        child: Text('Hola, ${widget.name}'),
      ),
      if (widget.email != null)
        PopupMenuItem<String>(enabled: false, child: Text(widget.email!)),
      const PopupMenuDivider(),
      const PopupMenuItem(value: 'sign-out', child: Text('Cerrar sesión')),
    ],
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppAvatar(
            name: widget.name,
            image: widget.image,
            size: AppAvatarSize.small,
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.keyboard_arrow_down_rounded),
        ],
      ),
    ),
  );
}
