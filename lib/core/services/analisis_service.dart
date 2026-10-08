import 'plazos_service.dart';

// ══════════════════════════════════════════════════════════════════
// ANALISIS SERVICE
// Motor de análisis normativo. Produce:
//   - Campos faltantes (con norma que los exige)
//   - Alertas (vencimientos, estado procesal crítico)
//   - Oportunidades defensivas
//   - Plazos calculados
// ══════════════════════════════════════════════════════════════════

class ResultadoAnalisis {
  final List<CampoFaltante> faltantes;
  final List<AlertaLegal> alertas;
  final List<OportunidadDefensiva> oportunidades;
  final List<PlazoCalculado> plazos;
  final String jurisdiccion;
  final DateTime generadoEn;

  const ResultadoAnalisis({
    required this.faltantes,
    required this.alertas,
    required this.oportunidades,
    required this.plazos,
    required this.jurisdiccion,
    required this.generadoEn,
  });

  bool get tieneCriticos => faltantes.any((f) => f.esCritico);
  bool get tieneVencidos => plazos.any((p) => p.estado == EstadoPlazo.vencido);
  bool get tieneUrgentes => plazos.any((p) => p.estado == EstadoPlazo.urgente);
}

class CampoFaltante {
  final String campo;
  final String detalle;
  final String? normaQueLoExige;
  final bool esCritico;

  const CampoFaltante({
    required this.campo,
    required this.detalle,
    this.normaQueLoExige,
    this.esCritico = false,
  });
}

class AlertaLegal {
  final TipoAlerta tipo;
  final String mensaje;
  final String? norma;

  const AlertaLegal({required this.tipo, required this.mensaje, this.norma});
}

enum TipoAlerta { peligro, advertencia, info }

class OportunidadDefensiva {
  final String titulo;
  final String detalle;
  final String? normaAplicable;

  const OportunidadDefensiva({
    required this.titulo,
    required this.detalle,
    this.normaAplicable,
  });
}

// ── SERVICIO ─────────────────────────────────────────────────────
class AnalisisService {
  final PlazosService _plazosService;

  AnalisisService(this._plazosService);

  Future<ResultadoAnalisis> analizar({
    required String jurisdiccion,
    DateTime? fechaNotificacion,
    String? tipoFalta,
    List<String> erroresFormales = const [],
    bool? titularEsConductor,
    String? estadoProcesal,
    bool vaJudicial = false,
    bool agotamientoVia = false,
    String? numeroActa,
  }) async {
    final faltantes = _detectarFaltantes(
      jurisdiccion: jurisdiccion,
      fechaNotificacion: fechaNotificacion,
      tipoFalta: tipoFalta,
      estadoProcesal: estadoProcesal,
      vaJudicial: vaJudicial,
      agotamientoVia: agotamientoVia,
    );

    final alertas = _generarAlertas(
      estadoProcesal: estadoProcesal,
      jurisdiccion: jurisdiccion,
    );

    final oportunidades = _detectarOportunidades(
      erroresFormales: erroresFormales,
      titularEsConductor: titularEsConductor,
      jurisdiccion: jurisdiccion,
    );

    List<PlazoCalculado> plazos = [];
    if (fechaNotificacion != null) {
      plazos = await _plazosService.calcularPlazos(
        jurisdiccion: jurisdiccion,
        fechaNotificacion: fechaNotificacion,
        tipoFalta: tipoFalta,
      );

      // Alertas automáticas por plazos críticos
      for (final p in plazos) {
        if (p.estado == EstadoPlazo.vencido) {
          alertas.add(
            AlertaLegal(
              tipo: TipoAlerta.peligro,
              mensaje:
                  'PLAZO VENCIDO: "${p.nombre}" — venció hace ${p.diasRestantes.abs()} días.',
              norma: p.norma,
            ),
          );
        } else if (p.estado == EstadoPlazo.urgente) {
          alertas.add(
            AlertaLegal(
              tipo: TipoAlerta.peligro,
              mensaje:
                  'URGENTE: "${p.nombre}" vence en ${p.diasRestantes} días.',
              norma: p.norma,
            ),
          );
        } else if (p.estado == EstadoPlazo.proximo) {
          alertas.add(
            AlertaLegal(
              tipo: TipoAlerta.advertencia,
              mensaje:
                  'PRÓXIMO: "${p.nombre}" vence en ${p.diasRestantes} días.',
              norma: p.norma,
            ),
          );
        }
      }
    } else {
      alertas.add(
        const AlertaLegal(
          tipo: TipoAlerta.advertencia,
          mensaje: 'Sin fecha de notificación: no es posible calcular plazos con precisión.',
        ),
      );
    }

    return ResultadoAnalisis(
      faltantes: faltantes,
      alertas: alertas,
      oportunidades: oportunidades,
      plazos: plazos,
      jurisdiccion: jurisdiccion,
      generadoEn: DateTime.now(),
    );
  }

  // ── Detectar campos faltantes ───────────────────────────────
  List<CampoFaltante> _detectarFaltantes({
    required String jurisdiccion,
    DateTime? fechaNotificacion,
    String? tipoFalta,
    String? estadoProcesal,
    bool vaJudicial = false,
    bool agotamientoVia = false,
  }) {
    final lista = <CampoFaltante>[];

    if (fechaNotificacion == null) {
      lista.add(
        const CampoFaltante(
          campo: 'Fecha de notificación fehaciente',
          detalle: 'Sin esta fecha no es posible calcular ningún plazo con certeza jurídica.',
          normaQueLoExige: 'Art. 35 Ley 13.927 PBA / Art. 8 Ley 1217 CABA',
          esCritico: true,
        ),
      );
    }

    if (tipoFalta == null) {
      lista.add(
        const CampoFaltante(
          campo: 'Tipo de falta (leve / grave / gravísima)',
          detalle: 'Determina el plazo de prescripción: 2 años (leve) o 5 años (grave) en el régimen nacional.',
          normaQueLoExige: 'Art. 89 Ley 24.449',
          esCritico: false,
        ),
      );
    }

    if (estadoProcesal == null) {
      lista.add(
        const CampoFaltante(
          campo: 'Estado procesal actual',
          detalle: 'Necesario para determinar qué acción corresponde y si quedan recursos disponibles.',
          esCritico: true,
        ),
      );
    }

    if (vaJudicial && !agotamientoVia) {
      lista.add(
        const CampoFaltante(
          campo: 'Agotamiento de vía administrativa',
          detalle: 'Para acceder a la vía judicial generalmente se requiere acreditar el agotamiento previo de la instancia administrativa.',
          normaQueLoExige: 'Art. 43 CN (amparo) / CPCA PBA / CCAyT CABA',
          esCritico: true,
        ),
      );
    }

    if (jurisdiccion == 'PBA') {
      lista.add(
        const CampoFaltante(
          campo: 'N° y sede del Juzgado Administrativo (PBA)',
          detalle: 'Necesario para identificar el JAITP competente para la presentación del descargo.',
          normaQueLoExige: 'Art. 32 Ley 13.927 PBA',
          esCritico: false,
        ),
      );
    }

    return lista;
  }

  // ── Generar alertas por estado procesal ─────────────────────
  List<AlertaLegal> _generarAlertas({
    String? estadoProcesal,
    required String jurisdiccion,
  }) {
    final lista = <AlertaLegal>[];

    if (estadoProcesal == 'apremio') {
      lista.add(
        const AlertaLegal(
          tipo: TipoAlerta.peligro,
          mensaje: 'JUICIO DE APREMIO INICIADO: el organismo puede embargar cuentas, vehículos e inmuebles. Consultar urgente con abogado/a matriculado/a.',
        ),
      );
    }

    if (estadoProcesal == 'firme') {
      lista.add(
        const AlertaLegal(
          tipo: TipoAlerta.peligro,
          mensaje: 'RESOLUCIÓN FIRME: los plazos de impugnación ordinarios están vencidos. Las opciones disponibles son limitadas (amparo, prescripción si aplica).',
        ),
      );
    }

    if (estadoProcesal == 'condenado') {
      final plazoTexto = jurisdiccion == 'PBA'
          ? '5 días hábiles desde la notificación (Arts. 40-41 Ley 13.927). El recurso DEBE fundarse en el mismo escrito.'
          : jurisdiccion == 'CABA'
          ? '5 días hábiles (Ley 1217)'
          : 'Verificar plazo de apelación local — actuar con urgencia.';
      lista.add(
        AlertaLegal(
          tipo: TipoAlerta.peligro,
          mensaje: 'PLAZO DE APELACIÓN EN CURSO: $plazoTexto',
        ),
      );
    }

    // Advertencia plan de pagos PBA
    if (jurisdiccion == 'PBA') {
      lista.add(
        const AlertaLegal(
          tipo: TipoAlerta.advertencia,
          mensaje: 'ADVERTENCIA PBA: La adhesión al plan de pagos implica reconocimiento irrevocable de deuda + renuncia a recursos + interrupción de prescripción.',
          norma: 'Art. 35 Ley 13.927 PBA',
        ),
      );
    }

    lista.add(
      const AlertaLegal(
        tipo: TipoAlerta.info,
        mensaje: 'Este análisis es orientativo. Verificar normativa vigente y consultar con abogado/a matriculado/a para el caso concreto.',
      ),
    );

    return lista;
  }

  // ── Detectar oportunidades defensivas ───────────────────────
  List<OportunidadDefensiva> _detectarOportunidades({
    required List<String> erroresFormales,
    bool? titularEsConductor,
    required String jurisdiccion,
  }) {
    final lista = <OportunidadDefensiva>[];

    if (erroresFormales.isNotEmpty) {
      lista.add(
        OportunidadDefensiva(
          titulo: 'Nulidad formal del acta',
          detalle:
              'Errores detectados: ${erroresFormales.join(", ")}. Pueden configurar nulidad formal del acta.',
          normaAplicable: jurisdiccion == 'PBA'
              ? 'Art. 3 Ley 13.927 PBA'
              : jurisdiccion == 'CABA'
              ? 'Art. 3 Ley 1217 CABA'
              : 'Verificar norma local aplicable',
        ),
      );
    }

    if (titularEsConductor == false) {
      lista.add(
        OportunidadDefensiva(
          titulo: 'Identificación del conductor real',
          detalle: 'El titular puede trasladar la responsabilidad identificando al conductor real. ATENCIÓN: la omisión hace responsable al titular.',
          normaAplicable: 'Art. 35 inc. f Ley 13.927 PBA',
        ),
      );
    }

    return lista;
  }
}
