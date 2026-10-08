/// Errores base del dominio.
sealed class AppError {
  const AppError(this.message);
  final String message;
}

final class ValidationError extends AppError {
  const ValidationError(super.message);
}

final class NotFoundError extends AppError {
  const NotFoundError(super.message);
}

final class UnexpectedError extends AppError {
  const UnexpectedError(super.message);
}
