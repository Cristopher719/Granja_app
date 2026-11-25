import 'package:flutter/material.dart';
import '../../services/metricas_service.dart';

class MetricasValidacionCard extends StatelessWidget {
  final String adminId;
  final DateTime desde;
  final DateTime hasta;

  const MetricasValidacionCard({
    super.key,
    required this.adminId,
    required this.desde,
    required this.hasta,
  });

  static const _nombres = {
    'registro_diario': 'Registro diario',
    'registro_sanitario': 'Registro sanitario',
    'registro_venta': 'Registro de venta',
    'clasificacion_huevos': 'Clasificación de huevos',
    'entrada_alimento': 'Entrada de alimento',
    'consulta_reportes': 'Consulta de reportes',
  };

  @override
  Widget build(BuildContext context) {
    final servicio = MetricasService();
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        servicio.resumenAlertas(adminId: adminId, desde: desde, hasta: hasta),
        servicio.resumenDesempeno(adminId: adminId, desde: desde, hasta: hasta),
      ]),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          );
        }
        if (snap.hasError) {
          return _caja(
            Text(
              'No se pudieron cargar las métricas: ${snap.error}',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          );
        }
        final alertas = snap.data![0] as Map<String, double>;
        final desempeno = snap.data![1] as Map<String, Map<String, double>>;

        final nAlertas = alertas['cantidad']!.toInt();
        final pctAlertas = alertas['pct_menos_1min']!;

        return _caja(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Atención de alertas críticas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (nAlertas == 0)
                Text(
                  'Aún no hay alertas vistas en este período.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                )
              else ...[
                _fila('Alertas vistas', '$nAlertas'),
                _fila(
                  'Tiempo promedio hasta verla',
                  '${alertas['promedio_min']!.toStringAsFixed(1)} min',
                ),
                _fila(
                  'Vistas en menos de 1 minuto',
                  '${pctAlertas.toStringAsFixed(0)} %',
                  cumple: pctAlertas >= 95,
                  meta: 'Meta: ≥ 95 %',
                ),
              ],
              const Divider(height: 24),
              const Text(
                'Desempeño (tiempo de respuesta con conexión)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (desempeno.isEmpty)
                Text(
                  'Aún no hay operaciones medidas en este período.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                )
              else
                ...desempeno.entries.map((e) {
                  final pct = e.value['pct_menos_3s']!;
                  return _fila(
                    _nombres[e.key] ?? e.key,
                    '${(e.value['promedio_ms']! / 1000).toStringAsFixed(2)} s  ·  ${pct.toStringAsFixed(0)} % < 3 s',
                    cumple: pct >= 95,
                    meta: '${e.value['cantidad']!.toInt()} mediciones',
                  );
                }),
              const SizedBox(height: 8),
              Text(
                'Las demás metas de la Tabla 1 (consolidación manual, errores en papel, encuestas SUS y de satisfacción) se miden en campo.',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _caja(Widget hijo) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: hijo,
  );

  Widget _fila(String etiqueta, String valor, {bool? cumple, String? meta}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cumple != null)
            Padding(
              padding: const EdgeInsets.only(right: 6, top: 1),
              child: Icon(
                cumple ? Icons.check_circle : Icons.error_outline,
                size: 16,
                color: cumple ? Colors.green : Colors.orange,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: const TextStyle(fontSize: 13)),
                if (meta != null)
                  Text(
                    meta,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          Text(
            valor,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
