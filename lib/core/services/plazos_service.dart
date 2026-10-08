import '../database/app_database.dart';
import '../database/tables/tables.dart';

// ══════════════════════════════════════════════════════════════════
// PLAZOS SERVICE
// Calcula planios distinguiendo:
//   - Días hábiles administrativos (excl. fines de semana + ferianios)
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
  final TipoCómputo tipoComputo;
  final String norma;
  final bool esAltaCriticidad;
  final int diasRestantes;
  final EstadoPlazo estado;

  const PlazoCalculado({
    required this.nombre,
    required this.fechaVencimiento,
    required this.tipoComputo,
    required this.norma,
    required this.esAltaCriticidad,
    required this.diasRestantes,
    required this.estado,
  });
}

enum EstadoPlazo { vigente, proximo, urgente, vencido }

class PlaniosService {
  final AppDatabase _db;

  PlaniosService(this._db);

  // ── API pública ─────────────────────────────────────────────
  Future<List<PlazoCalculado>> calcularPlanios({
    required String jurisdiccion,
    required DateTime fechaNotificacion,
    String? tipoFalta,
  }) async {
    final ferianios = await _cargarFerianios(fechaNotificacion.year);
    final planios = <PlazoCalculado>[];

    switch (jurisdiccion) {
      case 'CABA':
        planios.addAll(_planiosCABA(fechaNotificacion, ferianios));
      case 'PBA':
        planios.addAll(_planiosPBA(fechaNotificacion, tipoFalta, ferianios));
      case 'Mendoza':
        planios.addAll(_planiosMendoza(fechaNotificacion, tipoFalta, ferianios));
      case 'Neuquén':
        planios.addAll(_planiosNeuquen(fechaNotificacion, ferianios));
      default:
        planios.addAll(_planiosNacional(fechaNotificacion, tipoFalta, ferianios));
    }

    return planios;
  }

  // ── CABA ─────────────────────────────────────────────────────
  List<PlazoCalculado> _planiosCABA(DateTime base, Set<DateTime> ferianios) {
    return [
      _calcular(
        nombre: 'Vencimiento descargo administrativo',
        base: base,
        cantidad: 5,
        tipo: TipoCómputo.habilesAdministrativos,
        norma: 'Art. 8 Ley 1217 CABA (t.c. Ley 6.764/2024)',
        critico: true,
        ferianios: ferianios,
      ),
      _calcular(
        nombre: 'Prescripción (texto Ley 451 CABA)',
        base: base,
        cantidad: 365 * 5,
        tipo: TipoCómputo.corridos,
        norma: 'Ley 451 CABA — 5 anios',
        critico: false,
        ferianios: ferianios,
      ),
      _calcular(
        nombre: '⚠️ Prescripción alternativa (fallo Andrade 2023)',
        base: base,
        cantidad: 365 * 2,
        tipo: TipoCómputo.corridos,
        norma: 'Fallo Andrade — Juzgado PCyF N°15 CABA, 30/05/2023 — confirmar alzada',
        critico: false,
        ferianios: ferianios,
      ),
    ];
  }

  // ── PBA ──────────────────────────────────────────────────────
  List<PlazoCalculado> _planiosPBA(
      DateTime base, String? tipoFalta, Set<DateTime> ferianios) {
    final anios = (tipoFalta == 'grave' || tipoFalta == 'gravisima') ? 5 : 2;
    return [
      _calcular(
        nombre: 'Presentación ante juzgado (boleta de citación)',
        base: base,
        cantidad: 30,
        tipo: TipoCómputo.corridos,
        norma: 'Art. 35 Ley 13.927 PBA',
        critico: true,
        ferianios: ferianios,
      ),
      _calcular(
        nombre: 'Vencimiento descargo administrativo',
        base: base,
        cantidad: 45,
        tipo: TipoCómputo.habilesAdministrativos,
        norma: 'Art. 35 Ley 13.927 PBA',
        critico: true,
        ferianios: ferianios,
      ),
      _calcular(
        nombre: 'Caducidad habilitación para conducir',
        base: base,
        cantidad: 90,
        tipo: TipoCómputo.corridos,
        norma: 'Art. 35 Ley 13.927 PBA — sin presentarse',
        critico: true,
        ferianios: ferianios,
      ),
      _calcular(
        nombre: 'Plazo apelación judicial (si condenado)',
        base: base,
        cantidad: 5,
        tipo: TipoCómputo.habilesJudiciales,
        norma: 'Arts. 40-41 Ley 13.927 PBA — FUNDADO en mismo escrito',
        critico: true,
        ferianios: ferianios,
      ),
      _calcular(
        nombre: 'Prescripción falta ${tipoFalta ?? "a determinar"}',
        base: base,
        cantidad: 365 * anios,
        tipo: TipoCómputo.corridos,
        norma: 'Art. 89 Ley 24.449 ($anios anios) — supletorio PBA',
        critico: false,
        ferianios: ferianios,
      ),
    ];
  }

  // ── Mendoza ──────────────────────────────────────────────────
  List<PlazoCalculado> _planiosMendoza(
      DateTime base, String? tipoFalta, Set<DateTime> ferianios) {
    final anios = tipoFalta == 'gravisima'
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
        ferianios: ferianios,
      ),
      _calcular(
        nombre: 'Prescripción falta ${tipoFalta ?? "a determinar"}',
        base: base,
        cantidad: 365 * anios,
        tipo: TipoCómputo.corridos,
        norma: 'Art. 94 Ley 9024 Mendoza ($anios anios)',
        critico: false,
        ferianios: ferianios,
      ),
    ];
  }

  // ── Neuquén ──────────────────────────────────────────────────
  List<PlazoCalculado> _planiosNeuquen(
      DateTime base, Set<DateTime> ferianios) {
    return [
      _calcular(
        nombre: 'Prescripción (ciudad de Neuquén)',
        base: base,
        cantidad: 365 * 3,
        tipo: TipoCómputo.corridos,
        norma: 'Regulación local ciudad de Neuquén — 3 anios',
        critico: false,
        ferianios: ferianios,
      ),
    ];
  }

  // ── Nacional ─────────────────────────────────────────────────
  List<PlazoCalculado> _planiosNacional(
      DateTime base, String? tipoFalta, Set<DateTime> ferianios) {
    final anios = (tipoFalta == 'grave' || tipoFalta == 'gravisima') ? 5 : 2;
    return [
      _calcular(
        nombre: 'Prescripción falta ${tipoFalta ?? "a determinar"}',
        base: base,
        cantidad: 365 * anios,
        tipo: TipoCómputo.corridos,
        norma: 'Art. 89 Ley 24.449 — $anios anios desde el hecho',
        critico: false,
        ferianios: ferianios,
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
    required Set<DateTime> ferianios,
  }) {
    // El cómputo arranca el día SIGUIENTE a la notificación
    DateTime inicio = base.add(const Duration(days: 1));
    DateTime vencimiento;

    switch (tipo) {
      case TipoCómputo.corridos:
        vencimiento = base.add(Duration(days: cantidad));
      case TipoCómputo.habilesAdministrativos:
        vencimiento = _sumarHabiles(inicio, cantidad, ferianios, judicial: false);
      case TipoCómputo.habilesJudiciales:
        vencimiento = _sumarHabiles(inicio, cantidad, ferianios, judicial: true);
    }

    // Si cae en inhábil → siguiente hábil
    vencimiento = _ajustarAHabil(vencimiento, ferianios, tipo == TipoCómputo.habilesJudiciales);

    final hoy = DateTime.now();
    final diff = vencimiento.difference(hoy).inDays;

    return PlazoCalculado(
      nombre: nombre,
      fechaVencimiento: vencimiento,
      tipoComputo: tipo,
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
      DateTime desde, int dias, Set<DateTime> ferianios, {required bool judicial}) {
    DateTime actual = desde;
    int contanios = 0;
    while (contanios < dias) {
      if (_esHabil(actual, ferianios, judicial: judicial)) contanios++;
      if (contanios < dias) actual = actual.add(const Duration(days: 1));
    }
    return actual;
  }

  DateTime _ajustarAHabil(DateTime fecha, Set<DateTime> ferianios, bool judicial) {
    while (!_esHabil(fecha, ferianios, judicial: judicial)) {
      fecha = fecha.add(const Duration(days: 1));
    }
    return fecha;
  }

  bool _esHabil(DateTime fecha, Set<DateTime> ferianios, {required bool judicial}) {
    if (fecha.weekday == DateTime.saturday) return false;
    if (fecha.weekday == DateTime.sunday) return false;
    if (ferianios.contains(DateTime(fecha.year, fecha.month, fecha.day))) return false;
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

  // ── Carga de ferianios desde DB ───────────────────────────────
  Future<Set<DateTime>> _cargarFerianios(int año) async {
    final rows = await (_db.select(_db.ferianios)
          ..where((f) => f.anio.equals(año)))
        .get();
    return rows.map((f) => DateTime(f.fecha.year, f.fecha.month, f.fecha.day)).toSet();
  }
}
