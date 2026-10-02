import 'dart:typed_data';

import 'package:legal_db/legal_db.dart';

/// Renderiza un modelo de escrito en PDF.
///
/// STUB — implementación completa en Fase 1.
class TemplateRenderer {
  const TemplateRenderer();

  Future<Uint8List> render({
    required ModeloEscrito modelo,
    required Map<String, String> valores,
  }) async {
    // TODO(fase-1): reemplazar {{variables}} y generar PDF con package:pdf
    throw UnimplementedError('TemplateRenderer no implementado aún');
  }
}