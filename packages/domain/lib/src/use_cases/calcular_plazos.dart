import 'package:core/core.dart';
import 'package:legal_db/legal_db.dart';

/// Calcula plazos procesales según jurisdicción y tipo de falta.
///
/// STUB — implementación completa en Fase 1.
class CalcularPlazos {
  const CalcularPlazos();

  Result<DateTime, AppError> call({
    required Jurisdiccion jurisdiccion,
    required DateTime fechaHecho,
    required String tipoFalta,
  }) {
    // TODO(fase-1): implementar cálculo con feriados y días hábiles
    return Err(UnexpectedError('No implementado aún'));
  }
}