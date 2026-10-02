import 'dart:io';

import 'ocr_engine.dart';

/// Factory que devuelve el motor OCR según plataforma.
///
/// STUB — implementación completa en Fase 1.
OcrEngine createOcrEngine() {
  if (Platform.isIOS) {
    // TODO(fase-1): retornar AppleVisionOcr()
    throw UnimplementedError('AppleVisionOcr no implementado aún');
  }
  if (Platform.isAndroid) {
    // TODO(fase-1): retornar MlKitOcr()
    throw UnimplementedError('MlKitOcr no implementado aún');
  }
  throw UnsupportedError('Plataforma no soportada');
}