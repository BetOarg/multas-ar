import 'dart:io';

/// Resultado de una extracción OCR.
class OcrResult {
  const OcrResult({
    required this.rawText,
    required this.confidence,
  });

  final String rawText;
  final double confidence;
}

/// Interfaz abstracta de motor OCR.
abstract class OcrEngine {
  Future<OcrResult> extractFromImage(File image);
  Future<bool> isAvailable();
}