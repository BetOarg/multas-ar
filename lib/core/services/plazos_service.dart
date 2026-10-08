import '../database/app_database.dart';
import '../database/tables/tables.dart';

// ══════════════════════════════════════════════════════════════════
// PLAZOS SERVICE
// Calcula plazos distinguiendo:
//   - Días hábiles administrativos (excl. fines de semana + feriados)
//   - Días hábiles judiciales (+ feria judicial enero/julio)
//   - Días corridos (solo cuenta días del calendario)
//
// IMPORTANTE: cómputo desde el día SIGUIENTE a la notificación.
// Si el vencimiento cae en día inhábil → siguiente día hábil.
// ══════════════════════════════════════════════════════════════════

enum TipoCómputo { habilesAdministrativos, habilesJudiciales, corridos }

class PlazoCalculado {
  final String nombre;
  final DateTime fechaVencimiento;
  final TipoCómputo tipoCómputo;
  final String norma;
  final bool esAltaCriticidad;
  final int diasRestantes;
  final EstadoPlazo estado;

  const PlazoCalculado({
    required this.nombre,
    required this.fechaVencimiento,
    required this.tipoCómputo,
    required this.norma,
    required this.esAltaCriticidad,
    required this.diasRestantes,
    required this.estado,
  });
}

enum EstadoPlazo { vigente, proximo, urgente, vencido }

class PlazosService {
  final AppDatabase _db;

  PlazosService(this._db);

  // ── API pública ─────────────────────────────────────────────
  Future<List<PlazoCalculado>> calcularPlazos({
    required String jurisdiccion,
    required DateTime fechaNotificacion,
    String? tipoFalta,
  }) async {
    final feriados = await _cargarFeriados(fechaNotificacion.year);
    final plazos = <PlazoCalculado>[];

    switch (jurisdiccion) {
      case 'CABA':
        plazos.addAll(_plazosCABA(fechaNotificacion, feriados));
      case 'PBA':
        plazos.addAll(_plazosPBA(fechaNotificacion, tipoFalta, feriados));
      case 'Mendoza':
        plazos.addAll(_plazosMendoza(fechaNotificacion, tipoFalta, feriados));
      case 'Neuquén':
        plazos.addAll(_plazosNeuquen(fechaNotificacion, feriados));
      default:
        plazos.addAll(_plazosNacional(fechaNotificacion, tipoFalta, feriados));
    }

    return plazos;
  }

  // ── CABA ─────────────────────────────────────────────────────
  List<PlazoCalculado> _plazosCABA(DateTime base, Set<DateTime> feriados) {
    return [
      _calcular(
        nombre: 'Vencimiento descargo administrativo',
        base: base,
        cantidad: 5,
        tipo: TipoCómputo.habilesAdministrativos,
        norma: 'Art. 8 Ley 1217 CABA (t.c. Ley 6.764/2024)',
        critico: true,
        feriados: feriados,
      ),
      _calcular(
        nombre: 'Prescripción (texto Ley 451 CABA)',
        base: base,
        cantidad: 365 * 5,
        tipo: TipoCómputo.corridos,
        norma: 'Ley 451 CABA — 5 años',
        critico: false,
        feriados: feriados,
      ),
      _calcular(
        nombre: '⚠️ Prescripción alternativa (fallo Andrade 2023)',
        base: base,
        cantidad: 365 * 2,
        tipo: TipoCómputo.corridos,
        norma: 'Fallo Andrade — Juzgado PCyF N°15 CABA, 30/05/2023 — confirmar alzada',
        critico: false,
        feriados: feriados,
      ),
    ];
  }

  // ── PBA ──────────────────────────────────────────────────────
  List<PlazoCalculado> _plazosPBA(
      DateTime base, String? tipoFalta, Set<DateTime> feriados) {
    final años = (tipoFalta == 'grave' || tipoFalta == 'gravisima') ? 5 : 2;
    return [
      _calcular(
        nombre: 'Presentación ante juzgado (boleta de citación)',
        base: base,
        cantidad: 30,
        tipo: TipoCómputo.corridos,
        norma: 'Art. 35 Ley 13.927 PBA',
        critico: true,
        feriados: feriados,
      ),
      _calcular(
        nombre: 'Vencimiento descargo administrativo',
        base: base,
        cantidad: 45,
        tipo: TipoCómputo.habilesAdministrativos,
        norma: 'Art. 35 Ley 13.927 PBA',
        critico: true,
        feriados: feriados,
      ),
      _calcular(
        nombre: 'Caducidad habilitación para conducir',
        base: base,
        cantidad: 90,
        tipo: TipoCómputo.corridos,
        norma: 'Art. 35 Ley 13.927 PBA — sin presentarse',
        critico: true,
        feriados: feriados,
      ),
      _calcular(
        nombre: 'Plazo apelación judicial (si condenado)',
        base: base,
        cantidad: 5,
        tipo: TipoCómputo.habilesJudiciales,
        norma: 'Arts. 40-41 Ley 13.927 PBA — FUNDADO en mismo escrito',
        critico: true,
        feriados: feriados,
      ),
      _calcular(
        nombre: 'Prescripción falta ${tipoFalta ?? "a determinar"}',
        base: base,
        cantidad: 365 * años,
        tipo: TipoCómputo.corridos,
        norma: 'Art. 89 Ley 24.449 ($años años) — supletorio PBA',
        critico: false,
        feriados: feriados,
      ),
    ];
  }

  // ── Mendoza ──────────────────────────────────────────────────
  List<PlazoCalculado> _plazosMendoza(
      DateTime base, String? tipoFalta, Set<DateTime> feriados) {
    final años = tipoFalta == 'gravisima'
        ? 4
        : tipoFalta == 'grave'
            ? 3
            : 2;
    return [
      _calcular(
        nombre: 'Descargo administrativo',
        base: base,
        cantidad: 10,
        tipo: TipoCómputo.habilesAdministrativos,
        norma: 'Ley 9024 Mendoza',
        critico: true,
        feriados: feriados,
      ),
      _calcular(
        nombre: 'Prescripción falta ${tipoFalta ?? "a determinar"}',
        base: base,
        cantidad: 365 * años,
        tipo: TipoCómputo.corridos,
        norma: 'Art. 94 Ley 9024 Mendoza ($años años)',
        critico: false,
        feriados: feriados,
      ),
    ];
  }

  // ── Neuquén ──────────────────────────────────────────────────
  List<PlazoCalculado> _plazosNeuquen(
      DateTime base, Set<DateTime> feriados) {
    return [
      _calcular(
        nombre: 'Prescripción (ciudad de Neuquén)',
        base: base,
        cantidad: 365 * 3,
        tipo: TipoCómputo.corridos,
        norma: 'Regulación local ciudad de Neuquén — 3 años',
        critico: false,
        feriados: feriados,
      ),
    ];
  }

  // ── Nacional ─────────────────────────────────────────────────
  List<PlazoCalculado> _plazosNacional(
      DateTime base, String? tipoFalta, Set<DateTime> feriados) {
    final años = (tipoFalta == 'grave' || tipoFalta == 'gravisima') ? 5 : 2;
    return [
      _calcular(
        nombre: 'Prescripción falta ${tipoFalta ?? "a determinar"}',
        base: base,
        cantidad: 365 * años,
        tipo: TipoCómputo.corridos,
        norma: 'Art. 89 Ley 24.449 — $años años desde el hecho',
        critico: false,
        feriados: feriados,
      ),
    ];
  }

  // ── Motor de cómputo ─────────────────────────────────────────
  PlazoCalculado _calcular({
    required String nombre,
    required DateTime base,
    required int cantidad,
    required TipoCómputo tipo,
    required String norma,
    required bool critico,
    required Set<DateTime> feriados,
  }) {
    // El cómputo arranca el día SIGUIENTE a la notificación
    DateTime inicio = base.add(const Duration(days: 1));
    DateTime vencimiento;

    switch (tipo) {
      case TipoCómputo.corridos:
        vencimiento = base.add(Duration(days: cantidad));
      case TipoCómputo.habilesAdministrativos:
        vencimiento = _sumarHabiles(inicio, cantidad, feriados, judicial: false);
      case TipoCómputo.habilesJudiciales:
        vencimiento = _sumarHabiles(inicio, cantidad, feriados, judicial: true);
    }

    // Si cae en inhábil → siguiente hábil
    vencimiento = _ajustarAHabil(vencimiento, feriados, tipo == TipoCómputo.habilesJudiciales);

    final hoy = DateTime.now();
    final diff = vencimiento.difference(hoy).inDays;

    return PlazoCalculado(
      nombre: nombre,
      fechaVencimiento: vencimiento,
      tipoCómputo: tipo,
      norma: norma,
      esAltaCriticidad: critico,
      diasRestantes: diff,
      estado: diff < 0
          ? EstadoPlazo.vencido
          : diff <= 3
              ? EstadoPlazo.urgente
              : diff <= 10
                  ? EstadoPlazo.proximo
                  : EstadoPlazo.vigente,
    );
  }

  DateTime _sumarHabiles(
      DateTime desde, int dias, Set<DateTime> feriados, {required bool judicial}) {
    DateTime actual = desde;
    int contados = 0;
    while (contados < dias) {
      if (_esHabil(actual, feriados, judicial: judicial)) contados++;
      if (contados < dias) actual = actual.add(const Duration(days: 1));
    }
    return actual;
  }

  DateTime _ajustarAHabil(DateTime fecha, Set<DateTime> feriados, bool judicial) {
    while (!_esHabil(fecha, feriados, judicial: judicial)) {
      fecha = fecha.add(const Duration(days: 1));
    }
    return fecha;
  }

  bool _esHabil(DateTime fecha, Set<DateTime> feriados, {required bool judicial}) {
    if (fecha.weekday == DateTime.saturday) return false;
    if (fecha.weekday == DateTime.sunday) return false;
    if (feriados.contains(DateTime(fecha.year, fecha.month, fecha.day))) return false;
    if (judicial && _esFeriaJudicial(fecha)) return false;
    return true;
  }

  bool _esFeriaJudicial(DateTime fecha) {
    // Feria de verano: enero completo
    if (fecha.month == 1) return true;
    // Feria de invierno: primera quincena de julio (aprox.)
    if (fecha.month == 7 && fecha.day <= 15) return true;
    return false;
  }

  // ── Carga de feriados desde DB ───────────────────────────────
  Future<Set<DateTime>> _cargarFeriados(int año) async {
    final rows = await (_db.select(_db.feriados)
          ..where((f) => f.anio.equals(año)))
        .get();
    return rows.map((f) => DateTime(f.fecha.year, f.fecha.month, f.fecha.day)).toSet();
  }
}
