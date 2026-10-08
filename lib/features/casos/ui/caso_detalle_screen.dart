import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/casos_bloc.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/legal_alert_widget.dart';
import '../../../shared/widgets/plazo_card_widget.dart';
import '../../../core/services/analisis_service.dart';

class CasoDetalleScreen extends StatelessWidget {
  final String casoId;
  const CasoDetalleScreen({super.key, required this.casoId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CasosBloc, CasosState>(
      builder: (ctx, state) {
        if (state is! CasosCargados) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final caso = state.casos.where((c) => c.id == casoId).firstOrNull;

        if (caso == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Caso no encontrado')),
            body: const Center(
              child: Text(
                'El caso no existe o fue archivado.',
                style: TextStyle(color: AppColors.text2),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              caso.numeroActa != null
                  ? 'Acta N° ${caso.numeroActa}'
                  : 'Caso sin número',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.archive_outlined),
                tooltip: 'Archivar caso',
                onPressed: () {
                  ctx.read<CasosBloc>().add(ArchivarCasoEvent(casoId: caso.id));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Datos del caso ───────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📋  Datos del caso',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Divider(height: 20),
                        _fila('Jurisdicción', caso.jurisdiccion),
                        _fila('Patente', caso.patente),
                        _fila('Tipo de falta', caso.tipoFalta),
                        _fila('Norma imputada', caso.normaImputada),
                        _fila('Estado procesal', caso.estadoProcesal),
                        _fila('Titular', caso.titularNombre),
                        _fila('DNI titular', caso.titularDni),
                        if (caso.conductorNombre != null)
                          _fila('Conductor real', caso.conductorNombre),
                        if (caso.fechaNotificacion != null)
                          _fila(
                            'Fecha notificación',
                            _fmt(caso.fechaNotificacion!),
                          ),
                        if (caso.fechaInfraccion != null)
                          _fila(
                            'Fecha infracción',
                            _fmt(caso.fechaInfraccion!),
                          ),
                        if (caso.notas != null && caso.notas!.isNotEmpty)
                          _fila('Notas', caso.notas),
                      ],
                    ),
                  ),
                ),

                // ── Advertencias por estado ──────────────────
                if (caso.estadoProcesal == 'apremio')
                  const LegalAlertWidget(
                    tipo: TipoAlerta.peligro,
                    mensaje: 'JUICIO DE APREMIO: el organismo puede embargar cuentas, vehículos e inmuebles. Consultar urgente con abogado/a matriculado/a.',
                  ),
                if (caso.estadoProcesal == 'condenado')
                  const LegalAlertWidget(
                    tipo: TipoAlerta.peligro,
                    mensaje: 'RESOLUCIÓN CONDENATORIA: verificar plazo de apelación. En PBA: 5 días hábiles desde la notificación, fundado en el mismo escrito (Art. 40 Ley 13.927).',
                  ),
                if (caso.jurisdiccion == 'PBA')
                  const LegalAlertWidget(
                    tipo: TipoAlerta.advertencia,
                    mensaje: 'PBA: La adhesión al plan de pagos implica reconocimiento irrevocable de deuda y renuncia a recursos.',
                    norma: 'Art. 35 Ley 13.927 PBA',
                  ),

                // ── Errores formales detectados ──────────────
                if (caso.erroresFormales != null &&
                    caso.erroresFormales!.isNotEmpty) ...[
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎯  Errores formales detectados',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.success),
                          ),
                          const SizedBox(height: 8),
                          ...caso.erroresFormales!
                              .split('|')
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          e,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.text2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],

                // ── Acciones rápidas ─────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚡  Acciones',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _accionBtn(
                              context,
                              icon: Icons.description_outlined,
                              label: 'Generar escrito',
                              onTap: () {},
                            ),
                            _accionBtn(
                              context,
                              icon: Icons.edit_outlined,
                              label: 'Editar caso',
                              onTap: () {},
                            ),
                            _accionBtn(
                              context,
                              icon: Icons.share_outlined,
                              label: 'Compartir',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fila(String label, String? valor) {
    if (valor == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.text3,
                letterSpacing: 0.05,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 13, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 15),
      label: Text(label),
      onPressed: onTap,
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}
