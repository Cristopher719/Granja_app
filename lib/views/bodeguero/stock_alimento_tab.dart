import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';
import 'entrada_alimento_tab.dart';

class StockAlimentoTab extends StatefulWidget {
  const StockAlimentoTab({super.key});

  @override
  State<StockAlimentoTab> createState() => _StockAlimentoTabState();
}

class _StockAlimentoTabState extends State<StockAlimentoTab> {
  final _firestoreService = FirestoreService();
  String? _adminId;
  bool _cargando = true;

  int _recarga = 0;

  @override
  void initState() {
    super.initState();
    _cargarAdmin();
  }

  Future<void> _cargarAdmin() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final datos = await _firestoreService.obtenerUsuario(uid);
    if (!mounted) return;
    setState(() {
      _adminId = datos?['creado_por'] as String?;
      _cargando = false;
    });
  }

  void _recargar() => setState(() => _recarga++);

  Future<void> _abrirEntrada({String? idGalpon, bool conteo = false}) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EntradaAlimentoTab(
          idGalponInicial: idGalpon,
          cerrarAlGuardar: true,
          conteoInicial: conteo,
        ),
      ),
    );
    if (guardado == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Stock de Alimento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _recargar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        onPressed: () => _abrirEntrada(),
        icon: const Icon(Icons.add),
        label: const Text('Registrar entrada'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _adminId == null
          ? const Center(child: Text('No se encontró el administrador.'))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.obtenerGalpones(_adminId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final galpones = snapshot.data?.docs ?? [];
                if (galpones.isEmpty) {
                  return estadoVacio(
                    'No hay galpones registrados.',
                    Icons.warehouse_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _recargar(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      Text(
                        'Stock = último conteo físico + entradas posteriores − consumo diario reportado por el galponero.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      ...galpones.map((doc) {
                        final datos = doc.data() as Map<String, dynamic>;
                        return _TarjetaAlimentoGalpon(
                          key: ValueKey('${doc.id}-$_recarga'),
                          idGalpon: doc.id,
                          nombreGalpon:
                              datos['nombre_o_numero'] ?? 'Sin nombre',
                          firestoreService: _firestoreService,
                          onRegistrarEntrada: () =>
                              _abrirEntrada(idGalpon: doc.id),
                          onConteo: () =>
                              _abrirEntrada(idGalpon: doc.id, conteo: true),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _TarjetaAlimentoGalpon extends StatelessWidget {
  final String idGalpon;
  final String nombreGalpon;
  final FirestoreService firestoreService;
  final VoidCallback onRegistrarEntrada;
  final VoidCallback onConteo;

  static const double _umbralStockBajoKg = 100;

  const _TarjetaAlimentoGalpon({
    super.key,
    required this.idGalpon,
    required this.nombreGalpon,
    required this.firestoreService,
    required this.onRegistrarEntrada,
    required this.onConteo,
  });

  String _kg(double v) => '${v.toStringAsFixed(1)} kg';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: FutureBuilder<Map<String, double>>(
        future: firestoreService.obtenerResumenAlimento(idGalpon),
        builder: (context, snapshot) {
          final cargando = snapshot.connectionState == ConnectionState.waiting;
          final r = snapshot.data;
          final stock = r?['stock'] ?? 0;
          final entradas = r?['entradas'] ?? 0;
          final promedio = r?['promedio_diario'] ?? 0;
          final dias = r?['dias_estimados'] ?? -1;
          final faltante = r?['faltante'] ?? 0;
          final conteoMs = r?['ultimo_conteo_ms'] ?? -1;
          final ultimoConteo = conteoMs > 0
              ? DateTime.fromMillisecondsSinceEpoch(conteoMs.toInt())
              : null;

          final color = stock <= 0
              ? Colors.red
              : stock < _umbralStockBajoKg
              ? Colors.orange
              : colorPrimario;
          final estado = stock <= 0
              ? 'Sin stock'
              : stock < _umbralStockBajoKg
              ? 'Stock bajo'
              : 'Normal';
          final proporcion = entradas > 0
              ? (stock / entradas).clamp(0.0, 1.0)
              : 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  iconoCirculo(Icons.warehouse_rounded, color: Colors.brown),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      nombreGalpon,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!cargando && !snapshot.hasError)
                    badgeEstado(
                      estado,
                      color: color,
                      icono: stock < _umbralStockBajoKg
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (cargando)
                const LinearProgressIndicator()
              else if (snapshot.hasError)
                Text(
                  'No se pudo calcular el stock: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _kg(stock),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'disponibles',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: proporcion,
                    minHeight: 8,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entradas > 0
                      ? 'Queda el ${(proporcion * 100).toStringAsFixed(0)} % de ${_kg(entradas)} '
                            '${ultimoConteo != null ? 'desde el conteo del ${ultimoConteo.day}/${ultimoConteo.month}' : 'ingresados'}'
                      : 'Aún no hay entradas ni conteos registrados',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _dato(
                        'Consumo diario (7 días)',
                        promedio > 0 ? _kg(promedio) : 'Sin registros',
                        Icons.grain,
                      ),
                    ),
                    Expanded(
                      child: _dato(
                        'Alcanza para',
                        dias < 0
                            ? '—'
                            : '${dias.floor()} ${dias.floor() == 1 ? 'día' : 'días'}',
                        Icons.event_available_outlined,
                      ),
                    ),
                  ],
                ),
                if (stock < _umbralStockBajoKg) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          stock <= 0
                              ? '¡Sin alimento disponible! Registra una entrada.'
                              : 'Stock por debajo de 100 kg: se recomienda reabastecer.',
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              if (!cargando && faltante > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    'El consumo reportado supera en ${_kg(faltante)} el alimento registrado. '
                    'Probablemente hubo alimento que no se registró como entrada: '
                    'haz un conteo físico para ajustar el stock real.',
                    style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onConteo,
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('Conteo físico'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.brown,
                    side: BorderSide(color: Colors.brown.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRegistrarEntrada,
                  icon: const Icon(Icons.add_box_outlined, size: 18),
                  label: const Text('Registrar entrada'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.brown,
                    side: BorderSide(color: Colors.brown.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dato(String etiqueta, String valor, IconData icono) {
    return Row(
      children: [
        Icon(icono, size: 16, color: Colors.brown),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
