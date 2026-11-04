import 'package:flutter/material.dart';
import 'app_dialog.dart';
import '../../platform/app_interaction_gate.dart';

/// Protects an explicit-save form. Contains no persistence or domain logic.
class AppFormGuard extends StatefulWidget {
  const AppFormGuard({
    super.key,
    required this.isDirty,
    required this.child,
    this.busy = false,
    this.changes,
  });
  final bool Function() isDirty;
  final bool busy;
  final Listenable? changes;
  final Widget child;

  static AppFormGuardState of(BuildContext context) =>
      context.findAncestorStateOfType<AppFormGuardState>()!;

  @override
  State<AppFormGuard> createState() => AppFormGuardState();
}

class AppFormGuardState extends State<AppFormGuard> {
  bool _allowExit = false, _asking = false;
  @override
  void initState() {
    super.initState();
    widget.changes?.addListener(_changed);
  }

  @override
  void didUpdateWidget(AppFormGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.changes != widget.changes) {
      oldWidget.changes?.removeListener(_changed);
      widget.changes?.addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() => _allowExit = false);
  }

  /// Call only after a confirmed save; failures must keep the draft protected.
  void saved() => setState(() => _allowExit = true);

  Future<void> requestExit([VoidCallback? exit]) async {
    if (widget.busy || _asking) return;
    if (!_allowExit && widget.isDirty()) {
      _asking = true;
      final discard = await AppDialog.show(
        context,
        title: '¿Salir sin guardar?',
        description: 'Los cambios que has hecho no se guardarán.',
        confirmLabel: 'Descartar cambios',
        cancelLabel: 'Seguir editando',
        variant: AppDialogVariant.warning,
      );
      _asking = false;
      if (!mounted || !discard || widget.busy) return;
      setState(() => _allowExit = true);
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted || widget.busy) return;
    if (exit != null) {
      exit();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    widget.changes?.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.busy && (_allowExit || !widget.isDirty()),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && AppInteractionScope.maybeOf(context)?.busy != true) {
        requestExit();
      }
    },
    child: widget.child,
  );
}
