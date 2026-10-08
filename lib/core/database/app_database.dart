import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/tables.dart';
import 'daos/casos_dao.dart';
import 'daos/plazos_dao.dart';
import 'daos/normativa_dao.dart';
import 'daos/escritos_dao.dart';

part 'app_database.g.dart'; // generado por drift_dev

// ══════════════════════════════════════════════════════════════════
// APP DATABASE
// Ejecutar para generar: dart run build_runner build
// ══════════════════════════════════════════════════════════════════

@DriftDatabase(
  tables: [
    Casos,
    Plazos,
    Escritos,
    NormativaEntradas,
    Configuracion,
    Feriados,
  ],
  daos: [
    CasosDao,
    PlazosDao,
    NormativaDao,
    EscritosDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // ── Versión del esquema ─────────────────────────────────────────
  // IMPORTANTE: incrementar cada vez que se modifique una tabla
  @override
  int get schemaVersion => 1;

  // ── Migraciones ────────────────────────────────────────────────
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // Seed inicial de feriados y normativa base
          await _seedFeriados2026();
          await _seedNormativaBase();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v1 → v2: ejemplo futuro
          // if (from < 2) {
          //   await m.addColumn(casos, casos.nuevoCampo);
          // }
        },
        beforeOpen: (details) async {
          // Habilitar foreign keys en SQLite
          await customStatement('PRAGMA foreign_keys = ON');
          // Optimizaciones de rendimiento
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA synchronous = NORMAL');
        },
      );

  // ── Seed feriados 2026 ─────────────────────────────────────────
  Future<void> _seedFeriados2026() async {
    final feriados2026 = [
      _feriado('2026-01-01', 'Año Nuevo', 'nacional'),
      _feriado('2026-03-24', 'Día Nacional de la Memoria', 'nacional'),
      _feriado('2026-04-02', 'Día de las Malvinas', 'nacional'),
      _feriado('2026-04-03', 'Viernes Santo', 'judicial'),
      _feriado('2026-05-01', 'Día del Trabajador', 'nacional'),
      _feriado('2026-05-25', 'Revolución de Mayo', 'nacional'),
      _feriado('2026-06-17', 'Paso a la Inmortalidad Gral. Güemes', 'nacional'),
      _feriado('2026-06-20', 'Paso a la Inmortalidad Gral. Belgrano', 'nacional'),
      _feriado('2026-07-09', 'Día de la Independencia', 'nacional'),
      _feriado('2026-08-17', 'Paso a la Inmortalidad Gral. San Martín', 'nacional'),
      _feriado('2026-10-12', 'Día del Respeto a la Diversidad Cultural', 'nacional'),
      _feriado('2026-11-23', 'Día de la Soberanía Nacional', 'nacional'),
      _feriado('2026-12-08', 'Inmaculada Concepción', 'nacional'),
      _feriado('2026-12-25', 'Navidad', 'nacional'),
    ];
    await batch((b) {
      b.insertAllOnConflictUpdate(feriados, feriados2026);
    });
  }

  FeriadosCompanion _feriado(String fecha, String nombre, String tipo, {String? jurisdiccion}) {
    final dt = DateTime.parse(fecha);
    return FeriadosCompanion.insert(
      fecha: dt,
      nombre: nombre,
      tipo: tipo,
      jurisdiccion: Value(jurisdiccion),
      anio: dt.year,
    );
  }

  // ── Seed normativa base ────────────────────────────────────────
  Future<void> _seedNormativaBase() async {
    // La normativa completa se carga desde assets/normativa/normativa_base.json
    // en NormativaRepository.seedFromAssets()
    // Aquí solo insertamos la versión mínima de arranque
    await into(normativaEntradas).insert(NormativaEntradasCompanion.insert(
      jurisdiccion: 'CABA',
      categoria: 'plazo',
      titulo: 'Vencimiento descargo administrativo',
      contenido: '5 días hábiles administrativos desde la notificación fehaciente',
      normaBase: const Value('Art. 8 Ley 1217 CABA (t.c. Ley 6.764/2024)'),
      esAltaImportancia: const Value(true),
    ));
    await into(normativaEntradas).insert(NormativaEntradasCompanion.insert(
      jurisdiccion: 'PBA',
      categoria: 'plazo',
      titulo: 'Vencimiento descargo administrativo',
      contenido: '45 días hábiles administrativos desde la notificación fehaciente',
      normaBase: const Value('Art. 35 Ley 13.927 PBA'),
      esAltaImportancia: const Value(true),
    ));
  }

  // ── Singleton ──────────────────────────────────────────────────
  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase();
}

// ── Conexión SQLite ─────────────────────────────────────────────
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'multas_ar.db'));
    return NativeDatabase.createInBackground(file);
  });
}
