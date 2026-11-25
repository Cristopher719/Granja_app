import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';
import '../../widgets/registrado_por_widget.dart';
import 'galpon_detalle_screen.dart';

class DashboardAdminTab extends StatefulWidget {
  const DashboardAdminTab({super.key});

  @override
  State<DashboardAdminTab> createState() => _DashboardAdminTabState();
}

class _DashboardAdminTabState extends State<DashboardAdminTab> {
  final _firestoreService = FirestoreService();
  bool _cargando = true;
  List<Map<String, dynamic>> _registrosHoy = [];
  List<QueryDocumentSnapshot> _galpones = [];
  String _nombreAdmin = '';
  String? _error;

  static const _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

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

      final results = await Future.wait([
        _firestoreService.obtenerUsuario(uid),
        _firestoreService.obtenerRegistrosConsolidados(adminId: uid, dias: 1),
        FirebaseFirestore.instance
            .collection('galpones')
            .where('administrador_id', isEqualTo: uid)
            .get(),
      ]);

      final datosAdmin = results[0] as Map<String, dynamic>?;
      final registros = results[1] as List<Map<String, dynamic>>;
      final galponesSnap = results[2] as QuerySnapshot;

      setState(() {
        _nombreAdmin = datosAdmin?['nombre'] as String? ?? '';
        _registrosHoy = registros;
        _galpones = galponesSnap.docs;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _cargando = false);
    }
  }

  int get _huevosHoy =>
      _registrosHoy.fold(0, (s, r) => s + ((r['huevos_buenos'] as int?) ?? 0));

  int get _mortalidadHoy =>
      _registrosHoy.fold(0, (s, r) => s + ((r['mortalidad'] as int?) ?? 0));

  double get _alimentoHoy => _registrosHoy.fold(
    0.0,
    (s, r) => s + ((r['alimento_kg'] as num?)?.toDouble() ?? 0),
  );

  bool get _hayAlertaMortalidad => _mortalidadHoy > 5;

  String get _saludo {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get _fechaHoy {
    final hoy = DateTime.now();
    return '${hoy.day} de ${_meses[hoy.month - 1]} de ${hoy.year}';
  }

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
                    expandedHeight: 150,
                    pinned: true,
                    backgroundColor: colorPrimario,
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
                            colors: [colorPrimario, Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '$_saludo${_nombreAdmin.isNotEmpty ? ', $_nombreAdmin' : ''} 👋',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _fechaHoy,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_galpones.length} galpones registrados',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
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
                        if (_hayAlertaMortalidad) ...[
                          _TarjetaAlerta(
                            mensaje:
                                'Mortalidad alta hoy: $_mortalidadHoy aves en total.',
                            color: Colors.red,
                            icono: Icons.warning_amber_rounded,
                          ),
                          const SizedBox(height: 16),
                        ],

                        tituloSeccion('Resumen de hoy', Icons.today_rounded),
                        const SizedBox(height: 10),
                        _registrosHoy.isEmpty ? _sinRegistrosHoy() : _kpisHoy(),
                        const SizedBox(height: 24),

                        tituloSeccion('Mis galpones', Icons.warehouse_outlined),
                        const SizedBox(height: 10),
                        if (_galpones.isEmpty)
                          estadoVacio(
                            'Aún no tienes galpones.\nVe a la pestaña Galpones para crear uno.',
                            Icons.warehouse_outlined,
                          )
                        else
                          ..._galpones.map(
                            (doc) => _TarjetaGalponDashboard(
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

  Widget _sinRegistrosHoy() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Los galponeros aún no han registrado datos hoy.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpisHoy() {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        _KpiMini(
          valor: '$_huevosHoy',
          etiqueta: 'Huevos',
          icono: Icons.egg_rounded,
          color: colorPrimario,
        ),
        _KpiMini(
          valor: '${_alimentoHoy.toStringAsFixed(0)} kg',
          etiqueta: 'Alimento',
          icono: Icons.grain,
          color: Colors.brown,
        ),
        _KpiMini(
          valor: '$_mortalidadHoy',
          etiqueta: 'Muertas',
          icono: Icons.monitor_heart_outlined,
          color: _hayAlertaMortalidad ? Colors.red : Colors.grey,
        ),
      ],
    );
  }
}

class _TarjetaAlerta extends StatelessWidget {
  final String mensaje;
  final Color color;
  final IconData icono;

  const _TarjetaAlerta({
    required this.mensaje,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiMini extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final IconData icono;
  final Color color;

  const _KpiMini({
    required this.valor,
    required this.etiqueta,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            etiqueta,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _TarjetaGalponDashboard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final FirestoreService firestoreService;

  const _TarjetaGalponDashboard({
    required this.doc,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    final datos = doc.data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                iconoCirculo(Icons.warehouse_rounded),
                const SizedBox(width: 12),
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
                      Text(
                        '${datos['capacidad_maxima'] ?? '-'} aves máx.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            FutureBuilder<QueryDocumentSnapshot?>(
              future: firestoreService.obtenerLoteActivo(doc.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return badgeEstado('Sin ciclo activo', color: Colors.grey);
                }
                final loteData = snapshot.data!.data() as Map<String, dynamic>;
                final cantidadInicial =
                    (loteData['cantidad_inicial'] as int?) ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        badgeEstado(
                          loteData['raza'] ?? '-',
                          color: colorPrimario,
                          icono: Icons.egg_rounded,
                        ),
                        const SizedBox(width: 8),
                        AvesVivasContador(
                          idGalpon: doc.id,
                          idLote: snapshot.data!.id,
                          cantidadInicial: cantidadInicial,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GalponDetalleScreen(
                      idGalpon: doc.id,
                      nombreGalpon: datos['nombre_o_numero'] ?? 'Galpón',
                    ),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: const Text(
                  'Gestionar galpón',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorPrimario,
                  side: BorderSide(color: colorPrimario.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
