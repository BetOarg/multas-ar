import 'dart:io';

import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════════
// OCR SERVICE
// Android  → PaddleOCR v5 + ONNX Runtime (on-device, sin red)
// iOS      → Apple Vision Framework (nativo, on-device)
// Fallback → Google ML Kit (cross-platform)
//
// Pasos para configurar PaddleOCR en Android:
// 1. Descargar modelos desde github.com/PaddlePaddle/PaddleOCR
//    - ch_PP-OCRv4_det_infer.onnx  (detección de texto)
//    - ch_PP-OCRv4_rec_infer.onnx  (reconocimiento de texto)
//    - ch_ppocr_keys_v1.txt        (diccionario de caracteres)
// 2. Copiar a assets/models/
// 3. Declarar en pubspec.yaml bajo flutter.assets
// ══════════════════════════════════════════════════════════════════

/// Resultado del análisis OCR
class OcrResultado {
  final String textoCompleto;
  final List<OcrBloque> bloques;
  final OcrConfianza confianza;
  final String motor; // 'paddle' | 'vision' | 'mlkit'
  final Duration tiempoProcesamiento;

  const OcrResultado({
    required this.textoCompleto,
    required this.bloques,
    required this.confianza,
    required this.motor,
    required this.tiempoProcesamiento,
  });
}

class OcrBloque {
  final String texto;
  final double confianza;
  final Rect? boundingBox;

  const OcrBloque({
    required this.texto,
    required this.confianza,
    this.boundingBox,
  });
}

enum OcrConfianza { alta, media, baja }

/// Campos extraídos y estructurados de un acta de tránsito
class ActaExtraida {
  final String? numeroActa;
  final DateTime? fechaInfraccion;
  final String? hora;
  final String? lugar;
  final String? patente;
  final String? titularNombre;
  final String? titularDni;
  final String? normaImputada;
  final String? descripcion;
  final String? agente;
  final String? organismo;
  final String? jurisdiccion;
  final List<String> erroresFormalesDetectados;
  final double confianzaGlobal;

  const ActaExtraida({
    this.numeroActa,
    this.fechaInfraccion,
    this.hora,
    this.lugar,
    this.patente,
    this.titularNombre,
    this.titularDni,
    this.normaImputada,
    this.descripcion,
    this.agente,
    this.organismo,
    this.jurisdiccion,
    this.erroresFormalesDetectados = const [],
    this.confianzaGlobal = 0.0,
  });
}

// ── INTERFACE ────────────────────────────────────────────────────
abstract class IOcrService {
  Future<bool> get isDisponible;
  Future<OcrResultado> procesarImagen(File imagen);
  Future<ActaExtraida> extraerCamposActa(File imagen);
}

// ── FACTORY — selecciona implementación por plataforma ───────────
class OcrServiceFactory {
  static IOcrService crear() {
    if (Platform.isAndroid) {
      return PaddleOcrService();
    } else if (Platform.isIOS) {
      return AppleVisionOcrService();
    } else {
      return MlKitOcrService(); // fallback web/desktop
    }
  }
}

// ── IMPLEMENTACIÓN ANDROID: PaddleOCR v5 + ONNX ─────────────────
class PaddleOcrService implements IOcrService {
  // Referencia: github.com/PaddlePaddle/PaddleOCR
  // Integración ONNX: github.com/microsoft/onnxruntime
  // Binding Flutter: paquete onnxruntime (pub.dev)

  bool _inicializado = false;

  @override
  Future<bool> get isDisponible async => true; // Android siempre disponible

  /// Inicializar modelos ONNX (llamar en app startup)
  Future<void> inicializar() async {
    if (_inicializado) return;
    // TODO: cargar modelos desde assets/models/
    // final detModel = await _cargarModelo('assets/models/ch_PP-OCRv4_det_infer.onnx');
    // final recModel = await _cargarModelo('assets/models/ch_PP-OCRv4_rec_infer.onnx');
    // final keys = await _cargarDiccionario('assets/models/ch_ppocr_keys_v1.txt');
    _inicializado = true;
    debugPrint('[PaddleOCR] Modelos cargados');
  }

  @override
  Future<OcrResultado> procesarImagen(File imagen) async {
    final stopwatch = Stopwatch()..start();
    await inicializar();

    // Pipeline PaddleOCR:
    // 1. Preprocesamiento: redimensionar, normalizar
    // 2. Detección: ch_PP-OCRv4_det → bounding boxes del texto
    // 3. Rectificación: rotar y recortar cada caja
    // 4. Reconocimiento: ch_PP-OCRv4_rec → texto por caja
    // 5. Post-procesamiento: ordenar bloques top-left → bottom-right

    // ⚠️ IMPLEMENTACIÓN PENDIENTE:
    // Requiere binding nativo ONNX Runtime para Android.
    // Ver: github.com/ultralytics/yolo-flutter-app como referencia
    // de integración ONNX Runtime en Flutter.

    stopwatch.stop();

    // Placeholder hasta implementación completa
    return OcrResultado(
      textoCompleto: '[PaddleOCR] Texto extraído de la imagen',
      bloques: const [],
      confianza: OcrConfianza.alta,
      motor: 'paddle',
      tiempoProcesamiento: stopwatch.elapsed,
    );
  }

  @override
  Future<ActaExtraida> extraerCamposActa(File imagen) async {
    final resultado = await procesarImagen(imagen);
    return _parsearTextoActa(resultado.textoCompleto);
  }
}

// ── IMPLEMENTACIÓN iOS: Apple Vision Framework ───────────────────
class AppleVisionOcrService implements IOcrService {
  // Acceso via google_mlkit_text_recognition que usa Vision en iOS
  // o via platform channel nativo

  @override
  Future<bool> get isDisponible async => Platform.isIOS;

  @override
  Future<OcrResultado> procesarImagen(File imagen) async {
    final stopwatch = Stopwatch()..start();

    // En iOS, google_mlkit_text_recognition usa automáticamente
    // el Vision Framework nativo de Apple.
    // Ver implementación en MlKitOcrService abajo.

    stopwatch.stop();
    return OcrResultado(
      textoCompleto: '[AppleVision] Texto extraído',
      bloques: const [],
      confianza: OcrConfianza.alta,
      motor: 'vision',
      tiempoProcesamiento: stopwatch.elapsed,
    );
  }

  @override
  Future<ActaExtraida> extraerCamposActa(File imagen) async {
    final resultado = await procesarImagen(imagen);
    return _parsearTextoActa(resultado.textoCompleto);
  }
}

// ── FALLBACK: Google ML Kit ───────────────────────────────────────
class MlKitOcrService implements IOcrService {
  // Plugin: google_mlkit_text_recognition
  // Usa Vision en iOS, ML Kit en Android

  @override
  Future<bool> get isDisponible async => true;

  @override
  Future<OcrResultado> procesarImagen(File imagen) async {
    final stopwatch = Stopwatch()..start();
    // final inputImage = InputImage.fromFile(imagen);
    // final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    // final resultado = await recognizer.processImage(inputImage);
    // await recognizer.close();
    stopwatch.stop();

    return OcrResultado(
      textoCompleto: '[MLKit] Texto extraído',
      bloques: const [],
      confianza: OcrConfianza.media,
      motor: 'mlkit',
      tiempoProcesamiento: stopwatch.elapsed,
    );
  }

  @override
  Future<ActaExtraida> extraerCamposActa(File imagen) async {
    final resultado = await procesarImagen(imagen);
    return _parsearTextoActa(resultado.textoCompleto);
  }
}

// ── PARSER DE ACTAS ──────────────────────────────────────────────
/// Extrae campos estructurados del texto OCR de un acta de tránsito
/// argentina usando expresiones regulares y heurísticas.
ActaExtraida _parsearTextoActa(String texto) {
  final textoNorm = texto.toUpperCase();

  // Número de acta
  final actaRegex = RegExp(r'N[°ºO]?\s*:?\s*(\d{6,10})', caseSensitive: false);
  final actaMatch = actaRegex.firstMatch(texto);

  // Patente (formato viejo ABC-123 o nuevo AB123CD)
  final patenteRegex = RegExp(
    r'\b([A-Z]{2}\d{3}[A-Z]{2}|[A-Z]{3}[-\s]?\d{3})\b',
    caseSensitive: false,
  );
  final patenteMatch = patenteRegex.firstMatch(texto);

  // DNI
  final dniRegex = RegExp(r'DNI[:\s]+(\d{7,8})', caseSensitive: false);
  final dniMatch = dniRegex.firstMatch(texto);

  // Norma imputada (ej: "Art. 48" o "Artículo 51 inc. b")
  final normaRegex = RegExp(
    r'(art[íi]culo|art\.?)\s+(\d+)\s*(inc\.?\s*[a-z])?',
    caseSensitive: false,
  );
  final normaMatch = normaRegex.firstMatch(texto);

  // Detección de jurisdicción por palabras clave
  String? jurisdiccion;
  if (textoNorm.contains('GOBIERNO DE LA CIUDAD') ||
      textoNorm.contains('CABA') ||
      textoNorm.contains('CGPC')) {
    jurisdiccion = 'CABA';
  } else if (textoNorm.contains('PROVINCIA DE BUENOS AIRES') ||
      textoNorm.contains('JAITP') ||
      textoNorm.contains('MINISTERIO DE TRANSPORTE PBA')) {
    jurisdiccion = 'PBA';
  }

  // Errores formales básicos detectables por OCR
  final errores = <String>[];
  if (patenteMatch == null) errores.add('Patente no legible o ausente');
  if (actaMatch == null) errores.add('Número de acta no identificado');
  if (normaMatch == null) errores.add('Norma imputada no identificada');

  return ActaExtraida(
    numeroActa: actaMatch?.group(1),
    patente: patenteMatch?.group(0),
    titularDni: dniMatch?.group(1),
    normaImputada: normaMatch?.group(0),
    jurisdiccion: jurisdiccion,
    erroresFormalesDetectados: errores,
    confianzaGlobal: _calcularConfianza(actaMatch, patenteMatch, normaMatch),
  );
}

double _calcularConfianza(Match? acta, Match? patente, Match? norma) {
  int encontrados = 0;
  if (acta != null) encontrados++;
  if (patente != null) encontrados++;
  if (norma != null) encontrados++;
  return encontrados / 3.0;
}
