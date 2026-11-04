enum FailureCode {
  cancelled,
  network,
  resourceExhausted,
  permissionDenied,
  configuration,
  invalidData,
  unknown,
}

class AppFailure implements Exception {
  const AppFailure(this.code, this.message);
  final FailureCode code;
  final String message;
  @override
  String toString() => message;
}

const firestoreQuotaFailure = AppFailure(
  FailureCode.resourceExhausted,
  'El servidor está temporalmente fuera de servicio. Inténtalo más tarde o mañana. Puedes consultar una copia guardada.',
);

String failureMessage(Object error) => error is AppFailure
    ? error.message
    : 'No se pudo completar la operación. Inténtalo de nuevo.';
