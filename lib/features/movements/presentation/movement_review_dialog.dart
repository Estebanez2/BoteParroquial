import 'package:flutter/material.dart';
import '../../../design_system/design_system.dart';
import '../../../models/movement.dart';

Future<bool> confirmMovementReview(
  BuildContext context,
  MovementReview review,
  String currency,
) async {
  if (review.inactivePerson) {
    final confirmed = await AppDialog.show(
      context,
      title: 'La persona está inactiva',
      description:
          'Puedes registrar este movimiento histórico sin reactivarla. ¿Quieres continuar?',
      confirmLabel: 'Continuar con persona inactiva',
      variant: AppDialogVariant.warning,
    );
    if (!context.mounted || !confirmed) return false;
  }
  if (review.needsNegativeConfirmation) {
    return AppDialog.show(
      context,
      title: 'El bote quedará en negativo',
      description:
          'Saldo consultado: ${formatMoneyCents(review.balanceCents, currency: currency)}.\n'
          'Después de esta operación: ${formatMoneyCents(review.projectedCents, currency: currency)}.\n\n'
          'Estás registrando una operación que deja el fondo en negativo. Confirma que quieres continuar.',
      confirmLabel: 'Confirmar saldo negativo',
      variant: AppDialogVariant.warning,
    );
  }
  return true;
}
