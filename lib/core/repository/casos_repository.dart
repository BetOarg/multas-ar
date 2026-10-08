import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/tables.dart';

// ══════════════════════════════════════════════════════════════════
// REPOSITORY PATTERN
// El contrato (interface) define qué hace el repositorio.
// La implementación concreta usa Drift hoy.
// En Fase 3, se puede crear FirestoreCasosRepository sin
// cambiar ningún BLoC ni UI — solo el binding en el DI.
// ══════════════════════════════════════════════════════════════════

// ── INTERFACE (contrato) ────────────────────────────────────────
abstract class ICasosRepository {
  Stream<List<Caso>> watchCasosActivos();
  Future<Caso?> getCasoPorId(String id);
  Future<String> crearCaso(CasosCompanion caso);
  Future<bool> actualizarCaso(CasosCompanion caso);
  Future<void> archivarCaso(String id);
  Future<void> actualizarEstado(String id, String estado);
  Future<List<Caso>> getCasosConPlazosProximos({int dias});
}

// ── IMPLEMENTACIÓN LOCAL (Drift) ────────────────────────────────
class LocalCasosRepository implements ICasosRepository {
  final AppDatabase _db;

  LocalCasosRepository(this._db);

  @override
  Stream<List<Caso>> watchCasosActivos() => _db.casosDao.watchCasosActivos();

  @override
  Future<Caso?> getCasoPorId(String id) => _db.casosDao.getCasoPorId(id);

  @override
  Future<String> crearCaso(CasosCompanion caso) =>
      _db.casosDao.insertarCaso(caso);

  @override
  Future<bool> actualizarCaso(CasosCompanion caso) =>
      _db.casosDao.actualizarCaso(caso);

  @override
  Future<void> archivarCaso(String id) => _db.casosDao.archivarCaso(id);

  @override
  Future<void> actualizarEstado(String id, String estado) =>
      _db.casosDao.actualizarEstado(id, estado);

  @override
  Future<List<Caso>> getCasosConPlazosProximos({int dias = 7}) =>
      _db.casosDao.getCasosConPlazosProximos(dias: dias);
}

// ── IMPLEMENTACIÓN REMOTA (Firestore — Fase 3) ──────────────────
// class FirestoreCasosRepository implements ICasosRepository {
//   // Misma interface, implementación sobre Firestore.
//   // Activar en main.dart cambiando el binding de DI.
// }
