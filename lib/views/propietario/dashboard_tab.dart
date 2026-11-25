import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';

class DashboardPropietarioTab extends StatefulWidget {
  const DashboardPropietarioTab({super.key});

  @override
  State<DashboardPropietarioTab> createState() =>
      _DashboardPropietarioTabState();
}

class _DashboardPropietarioTabState extends State<DashboardPropietarioTab> {
  final _firestoreService = FirestoreService();
  bool _cargando = true;
  List<Map<String, dynamic>> _registrosHoy = [];
  List<Map<String, dynamic>> _ventasHoy = [];
  List<QueryDocumentSnapshot> _galpones = [];
  String? _adminId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final datosUsuario = await _firestoreService.obtenerUsuario(uid);
      _adminId = datosUsuario?['creado_por'] as String?;

      if (_adminId == null) throw Exception('No se encontró el administrador.');

      final galponesSnap = await FirebaseFirestore.instance
          .collection('galpones')
          .where('administrador_id', isEqualTo: _adminId)
          .get();
      _galpones = galponesSnap.docs;

      _registrosHoy = await _firestoreService.obtenerRegistrosConsolidados(
        adminId: _adminId!,
        dias: 1,
      );

      final ventasHoy = await _firestoreService.obtenerVentasConsolidadas(
        adminId: _adminId!,
        dias: 1,
      );
      _ventasHoy = ventasHoy;
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _cargando = false);
    }
  }

  int get _totalHuevosHoy =>
      _registrosHoy.fold(0, (s, r) => s + ((r['huevos_buenos'] as int?) ?? 0));

  int get _totalMortalidadHoy =>
      _registrosHoy.fold(0, (s, r) => s + ((r['mortalidad'] as int?) ?? 0));

  double get _totalVentasHoy => _ventasHoy.fold(
    0.0,
    (s, r) => s + ((r['total'] as num?)?.toDouble() ?? 0),
  );

  int get _totalUnidadesVendidasHoy =>
      _ventasHoy.fold(0, (s, r) => s + ((r['cantidad_unidades'] as int?) ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 120,
                    pinned: true,
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _cargarDatos,
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  'Panel Ejecutivo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_galpones.length} galpones activos',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        tituloSeccion('Resumen de hoy', Icons.today_rounded),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.5,
                          children: [
                            _KpiCard(
                              valor: '$_totalHuevosHoy',
                              etiqueta: 'Huevos producidos',
                              icono: Icons.egg_rounded,
                              color: colorPrimario,
                            ),
                            _KpiCard(
                              valor: '$_totalUnidadesVendidasHoy',
                              etiqueta: 'Huevos vendidos',
                              icono: Icons.point_of_sale_rounded,
                              color: Colors.orange,
                            ),
                            _KpiCard(
                              valor: '\$${_totalVentasHoy.toStringAsFixed(0)}',
                              etiqueta: 'Ingresos hoy',
                              icono: Icons.attach_money_rounded,
                              color: Colors.green[800]!,
                            ),
                            _KpiCard(
                              valor: '$_totalMortalidadHoy',
                              etiqueta: 'Mortalidad hoy',
                              icono: Icons.monitor_heart_outlined,
                              color: _totalMortalidadHoy > 5
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        tituloSeccion(
                          'Estado de galpones',
                          Icons.warehouse_outlined,
                        ),
                        const SizedBox(height: 10),
                        if (_galpones.isEmpty)
                          estadoVacio(
                            'No hay galpones registrados.',
                            Icons.warehouse_outlined,
                          )
                        else
                          ..._galpones.map(
                            (doc) => _TarjetaGalponResumen(
                              doc: doc,
                              firestoreService: _firestoreService,
                            ),
                          ),

                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TarjetaGalponResumen extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final FirestoreService firestoreService;

  const _TarjetaGalponResumen({
    required this.doc,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    final datos = doc.data() as Map<String, dynamic>;

    return tarjetaItem(
      child: Row(
        children: [
          iconoCirculo(Icons.warehouse_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  datos['nombre_o_numero'] ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _LoteActivoInfo(
                  idGalpon: doc.id,
                  firestoreService: firestoreService,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoteActivoInfo extends StatelessWidget {
  final String idGalpon;
  final FirestoreService firestoreService;

  const _LoteActivoInfo({
    required this.idGalpon,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QueryDocumentSnapshot?>(
      future: firestoreService.obtenerLoteActivo(idGalpon),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Text(
            'Sin ciclo activo',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          );
        }

        final datos = snapshot.data!.data() as Map<String, dynamic>;
        final cantidadInicial = (datos['cantidad_inicial'] as int?) ?? 0;

        return FutureBuilder<int>(
          future: firestoreService.calcularAvesVivas(
            idGalpon: idGalpon,
            idLote: snapshot.data!.id,
            cantidadInicial: cantidadInicial,
          ),
          builder: (context, snapVivas) {
            final vivas = snapVivas.data ?? cantidadInicial;
            return Row(
              children: [
                badgeEstado(
                  '${datos['raza'] ?? '-'}',
                  color: colorPrimario,
                  icono: Icons.egg_rounded,
                ),
                const SizedBox(width: 6),
                Text(
                  '$vivas aves vivas',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final IconData icono;
  final Color color;

  const _KpiCard({
    required this.valor,
    required this.etiqueta,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                etiqueta,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
