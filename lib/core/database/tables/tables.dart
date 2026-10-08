import 'package:drift/drift.dart';

// ══════════════════════════════════════════════════════════════════
// TABLAS — MULTAS ARGENTINA PRO
// Drift genera el código tipado a partir de estas definiciones.
// Ejecutar: dart run build_runner build --delete-conflicting-outputs
// ══════════════════════════════════════════════════════════════════

// ── CASOS ──────────────────────────────────────────────────────────
/// Tabla principal de casos — una fila por acta/expediente
class Casos extends Table {
  // Identificación
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get numeroActa => text().nullable()();
  TextColumn get numeroExpediente => text().nullable()();

  // Jurisdicción (ver enum Jurisdiccion en constants.dart)
  TextColumn get jurisdiccion => text()();
  TextColumn get municipio => text().nullable()();

  // Fechas del acta
  DateTimeColumn get fechaInfraccion => dateTime().nullable()();
  DateTimeColumn get fechaNotificacion => dateTime().nullable()();
  TextColumn get tipoFalta => text().nullable()(); // leve | grave | gravisima

  // Vehículo
  TextColumn get patente => text().nullable()();
  TextColumn get titularNombre => text().nullable()();
  TextColumn get titularDni => text().nullable()();
  TextColumn get conductorNombre => text().nullable()(); // si ≠ titular
  TextColumn get conductorDni => text().nullable()();

  // Norma imputada
  TextColumn get normaImputada => text().nullable()();
  TextColumn get descripcionInfraccion => text().nullable()();

  // Estado procesal
  TextColumn get estadoProcesal => text().withDefault(const Constant('admin'))();
  // admin | descargo | condenado | apelacion | firme | apremio | prescripto

  // Vía judicial
  BoolColumn get vaJudicial => boolean().withDefault(const Constant(false))();
  BoolColumn get agotamientoVia => boolean().withDefault(const Constant(false))();

  // Juzgado
  TextColumn get numeroJuzgado => text().nullable()();
  TextColumn get sedeJuzgado => text().nullable()();

  // Errores formales detectados (JSON array)
  TextColumn get erroresFormales => text().nullable()();

  // Análisis OCR
  TextColumn get ocrTextoExtraido => text().nullable()();
  TextColumn get ocrConfianza => text().nullable()(); // alta | media | baja
  TextColumn get imagenPath => text().nullable()();   // path local

  // Notas
  TextColumn get notas => text().nullable()();

  // Alertas activas (JSON array de IDs de alerta)
  TextColumn get alertasActivas => text().nullable()();

  // Metadata
  DateTimeColumn get creadoEn => dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get actualizadoEn => dateTime().clientDefault(() => DateTime.now())();
  BoolColumn get archivado => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ── PLAZOS ─────────────────────────────────────────────────────────
/// Plazos calculados para cada caso — generados por PlazosService
class Plazos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get casoId => text().references(Casos, #id)();

  TextColumn get nombre => text()();           // "Vencimiento descargo"
  DateTimeColumn get fechaVencimiento => dateTime()();
  TextColumn get tipoCómputo => text()();      // habiles_admin | habiles_jud | corridos
  TextColumn get norma => text()();            // "Art. 35 Ley 13.927 PBA"
  BoolColumn get esAltaCriticidad => boolean().withDefault(const Constant(false))();
  BoolColumn get notificado => boolean().withDefault(const Constant(false))();
  BoolColumn get vencido => boolean().withDefault(const Constant(false))();

  DateTimeColumn get creadoEn => dateTime().clientDefault(() => DateTime.now())();
}

// ── ESCRITOS ───────────────────────────────────────────────────────
/// Modelos de escritos generados para cada caso
class Escritos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get casoId => text().references(Casos, #id)();

  TextColumn get tipo => text()();
  // descargo_pba | descargo_caba | recurso_apelacion | amparo |
  // prescripcion | telegrama | demanda_contencioso | denuncia_conductor

  TextColumn get jurisdiccion => text()();
  TextColumn get contenido => text()();         // texto completo del escrito
  TextColumn get camposFaltantes => text().nullable()(); // JSON array
  BoolColumn get completo => boolean().withDefault(const Constant(false))();

  DateTimeColumn get creadoEn => dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get actualizadoEn => dateTime().clientDefault(() => DateTime.now())();
}

// ── NORMATIVA ──────────────────────────────────────────────────────
/// Base normativa por jurisdicción — actualizable sin release
class NormativaEntradas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get jurisdiccion => text()();
  TextColumn get categoria => text()();
  // ley | plazo | organo | prescripcion | advertencia | contacto

  TextColumn get titulo => text()();
  TextColumn get contenido => text()();
  TextColumn get normaBase => text().nullable()();  // "Art. 35 Ley 13.927"
  BoolColumn get esAltaImportancia => boolean().withDefault(const Constant(false))();
  IntColumn get orden => integer().withDefault(const Constant(0))();

  // Para alertas duales (ej. fallo Andrade CABA, caducidad PBA)
  BoolColumn get tieneAlertaDual => boolean().withDefault(const Constant(false))();
  TextColumn get alertaDualDetalle => text().nullable()();

  // Versión para updates OTA
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get vigenciaDesde => dateTime().nullable()();
  DateTimeColumn get vigenciaHasta => dateTime().nullable()();

  DateTimeColumn get actualizadoEn => dateTime().clientDefault(() => DateTime.now())();
}

// ── CONFIGURACION ──────────────────────────────────────────────────
/// Configuración del usuario y preferencias
class Configuracion extends Table {
  TextColumn get clave => text()();
  TextColumn get valor => text()();
  DateTimeColumn get actualizadoEn => dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {clave};
}

// ── FERIADOS ───────────────────────────────────────────────────────
/// Feriados nacionales y provinciales para cómputo de plazos
class Feriados extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get nombre => text()();
  TextColumn get tipo => text()();
  // nacional | judicial | provincial_CABA | provincial_PBA | etc.
  TextColumn get jurisdiccion => text().nullable()(); // null = todos

  // Año para indexar
  IntColumn get anio => integer()();
}

// ── HELPER ─────────────────────────────────────────────────────────
String _uuid() {
  // En producción usar el paquete uuid
  return DateTime.now().millisecondsSinceEpoch.toString();
}
