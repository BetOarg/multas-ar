import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/analisis/ui/analisis_screen.dart';
import '../../features/casos/ui/casos_screen.dart';
import '../../features/casos/ui/caso_detalle_screen.dart';
import '../../features/escritos/ui/escritos_screen.dart';
import '../../features/normativa/ui/normativa_screen.dart';
import '../../features/configuracion/ui/configuracion_screen.dart';
import '../widgets/scaffold_with_nav.dart';

// ══════════════════════════════════════════════════════════════════
// APP ROUTER — go_router con shell route (bottom nav persistente)
// ══════════════════════════════════════════════════════════════════

abstract class AppRouter {
  // Rutas nombradas
  static const analisis = '/analisis';
  static const casos = '/casos';
  static const casoDetalle = '/casos/:id';
  static const escritos = '/escritos';
  static const normativa = '/normativa';
  static const configuracion = '/configuracion';

  static final config = GoRouter(
    initialLocation: analisis,
    debugLogDiagnostics: false,
    routes: [
      // Shell route — mantiene la BottomNavigationBar entre pantallas
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            ScaffoldWithNav(navigationShell: shell),
        branches: [
          // ── Analizar multa ──────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: analisis,
                name: 'analisis',
                builder: (_, __) => const AnalisisScreen(),
              ),
            ],
          ),

          // ── Mis casos ───────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: casos,
                name: 'casos',
                builder: (_, __) => const CasosScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'caso-detalle',
                    builder: (_, state) =>
                        CasoDetalleScreen(casoId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),

          // ── Escritos ────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: escritos,
                name: 'escritos',
                builder: (_, __) => const EscritosScreen(),
              ),
            ],
          ),

          // ── Normativa ───────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: normativa,
                name: 'normativa',
                builder: (_, __) => const NormativaScreen(),
              ),
            ],
          ),

          // ── Configuración ───────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: configuracion,
                name: 'configuracion',
                builder: (_, __) => const ConfiguracionScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
