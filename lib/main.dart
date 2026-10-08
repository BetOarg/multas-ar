import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/database/app_database.dart';
import 'core/repository/casos_repository.dart';
import 'core/services/ocr_service.dart';
import 'core/services/plazos_service.dart';
import 'core/services/analisis_service.dart';
import 'core/services/notification_service.dart';
import 'features/analisis/bloc/analisis_bloc.dart';
import 'features/casos/bloc/casos_bloc.dart';
import 'features/escritos/bloc/escritos_bloc.dart';
import 'shared/theme/app_theme.dart';
import 'shared/router/app_router.dart';

// ══════════════════════════════════════════════════════════════════
// MAIN — Entry point
// Dependency Injection manual (sin get_it ni injectable).
// Para escalar: agregar get_it en Fase 3.
// ══════════════════════════════════════════════════════════════════

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación fija vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Zona horaria para notificaciones
  tz.initializeTimeZones();

  // Base de datos Drift (singleton)
  final db = AppDatabase.instance;

  // Notificaciones locales
  await NotificationService.inicializar(notificationsPlugin);

  runApp(MultasArApp(db: db));
}

class MultasArApp extends StatelessWidget {
  final AppDatabase db;
  const MultasArApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    // ── Servicios ───────────────────────────────────────────────
    final ocrService = OcrServiceFactory.crear();
    final plazosService = PlazosService(db);
    final analisisService = AnalisisService(plazosService);

    // ── Repositorios ────────────────────────────────────────────
    // Para cambiar a Firestore en Fase 3:
    // reemplazar LocalCasosRepository por FirestoreCasosRepository
    // sin tocar ningún BLoC ni UI.
    final casosRepo = LocalCasosRepository(db);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ICasosRepository>(create: (_) => casosRepo),
        RepositoryProvider<IOcrService>(create: (_) => ocrService),
        RepositoryProvider<PlazosService>(create: (_) => plazosService),
        RepositoryProvider<AnalisisService>(create: (_) => analisisService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AnalisisBloc>(
            create: (ctx) => AnalisisBloc(
              casosRepository: ctx.read<ICasosRepository>(),
              ocrService: ctx.read<IOcrService>(),
              plazosService: ctx.read<PlazosService>(),
              analisisService: ctx.read<AnalisisService>(),
            ),
          ),
          BlocProvider<CasosBloc>(
            create: (ctx) => CasosBloc(
              casosRepository: ctx.read<ICasosRepository>(),
            )..add(const CargarCasosEvent()),
          ),
          BlocProvider<EscritosBloc>(
            create: (ctx) => EscritosBloc(
              casosRepository: ctx.read<ICasosRepository>(),
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'Multas Argentina',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          routerConfig: AppRouter.config,
        ),
      ),
    );
  }
}
