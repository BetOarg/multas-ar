import 'package:core/core.dart';

/// Calcula la fecha límite de prescripción con interrupciones.
///
/// STUB — implementación completa en Fase 1.
class CalcularPrescripcion {
  const CalcularPrescripcion();

  Result<DateTime, AppError> call({
    required DateTime fechaHecho,
    required String tipoFalta,
    List<Map<String, dynamic>> eventos = const [],
  }) {
    // TODO(fase-1): implementar cálculo con interrupciones (Art. 88/89)
    return Err(UnexpectedError('No implementado aún'));
  }
}