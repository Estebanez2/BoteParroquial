enum FailureCode {
  cancelled,
  network,
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

String failureMessage(Object error) => error is AppFailure
    ? error.message
    : 'No se pudo completar la operación. Inténtalo de nuevo.';
