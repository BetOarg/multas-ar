import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'casos_dao.g.dart'; // generado por drift_dev

@DriftAccessor(tables: [Casos, Plazos])
class CasosDao extends DatabaseAccessor<AppDatabase> with _$CasosDaoMixin {
  CasosDao(super.db);

  // ── Lecturas ────────────────────────────────────────────────────

  /// Todos los casos activos, ordenados por fecha de creación desc
  Stream<List<Caso>> watchCasosActivos() {
    return (select(casos)
          ..where((c) => c.archivado.equals(false))
          ..orderBy([(c) => OrderingTerm.desc(c.creadoEn)]))
        .watch();
  }

  /// Un caso por ID
  Future<Caso?> getCasoPorId(String id) {
    return (select(casos)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// Casos por estado procesal
  Stream<List<Caso>> watchCasosPorEstado(String estado) {
    return (select(casos)
          ..where((c) => c.estadoProcesal.equals(estado))
          ..orderBy([(c) => OrderingTerm.desc(c.creadoEn)]))
        .watch();
  }

  /// Casos con plazos próximos a vencer (próximos N días)
  Future<List<Caso>> getCasosConPlazosProximos({int dias = 7}) async {
    final limite = DateTime.now().add(Duration(days: dias));
    final casosIds = await (select(plazos)
          ..where((p) =>
              p.fechaVencimiento.isSmallerThanValue(limite) &
              p.vencido.equals(false) &
              p.notificado.equals(false)))
        .map((p) => p.casoId)
        .get();

    if (casosIds.isEmpty) return [];

    return (select(casos)
          ..where((c) => c.id.isIn(casosIds) & c.archivado.equals(false)))
        .get();
  }

  // ── Escrituras ──────────────────────────────────────────────────

  /// Insertar nuevo caso
  Future<String> insertarCaso(CasosCompanion caso) async {
    await into(casos).insert(caso);
    return caso.id.value;
  }

  /// Actualizar caso existente
  Future<bool> actualizarCaso(CasosCompanion caso) {
    return update(casos).replace(caso);
  }

  /// Archivar caso (soft delete)
  Future<void> archivarCaso(String id) async {
    await (update(casos)..where((c) => c.id.equals(id))).write(
      const CasosCompanion(archivado: Value(true)),
    );
  }

  /// Actualizar estado procesal
  Future<void> actualizarEstado(String id, String nuevoEstado) async {
    await (update(casos)..where((c) => c.id.equals(id))).write(
      CasosCompanion(
        estadoProcesal: Value(nuevoEstado),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }
}
