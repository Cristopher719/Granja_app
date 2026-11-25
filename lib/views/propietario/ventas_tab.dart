import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';
import '../../widgets/selector_rango_fechas.dart';

class VentasPropietarioTab extends StatefulWidget {
  const VentasPropietarioTab({super.key});

  @override
  State<VentasPropietarioTab> createState() => _VentasPropietarioTabState();
}

class _VentasPropietarioTabState extends State<VentasPropietarioTab> {
  final _firestoreService = FirestoreService();
  bool _cargando = true;
  bool _cargandoGalpones = true;
  String? _adminId;
  List<Map<String, dynamic>> _registros = [];
  List<Map<String, dynamic>> _ventas = [];
  List<QueryDocumentSnapshot> _todosLosGalpones = [];
  Set<String> _galponesSeleccionados = {};
  String? _error;

  late DateTime _fechaDesde;
  late DateTime _fechaHasta;

  @override
  void initState() {
    super.initState();
    _fechaHasta = DateTime.now();
    _fechaDesde = _fechaHasta.subtract(const Duration(days: 6));
    _inicializar();
  }

  Future<void> _inicializar() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final datosUsuario = await _firestoreService.obtenerUsuario(uid);
    _adminId = datosUsuario?['creado_por'] as String?;

    if (_adminId == null) {
      setState(() {
        _error = 'No se encontró el administrador.';
        _cargando = false;
        _cargandoGalpones = false;
      });
      return;
    }

    await _cargarGalpones();
    await _cargarDatos();
  }

  Future<void> _cargarGalpones() async {
    final snap = await FirebaseFirestore.instance
        .collection('galpones')
        .where('administrador_id', isEqualTo: _adminId)
        .get();
    setState(() {
      _todosLosGalpones = snap.docs;
      _cargandoGalpones = false;
    });
  }

  Future<void> _cargarDatos() async {
    if (_adminId == null) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final idsFiltro =
          _galponesSeleccionados.isEmpty ? null : _galponesSeleccionados.toList();

      final registros = await _firestoreService.obtenerRegistrosConsolidados(
        adminId: _adminId!,
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
        galponIds: idsFiltro,
      );

      final ventas = await _firestoreService.obtenerVentasConsolidadas(
        adminId: _adminId!,
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
        galponIds: idsFiltro,
      );

      setState(() {
        _registros = registros;
        _ventas = ventas;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _cargando = false);
    }
  }

  Map<DateTime, int> get _produccionPorDia {
    final mapa = <DateTime, int>{};
    for (final r in _registros) {
      final fecha = (r['fecha'] as Timestamp?)?.toDate();
      if (fecha == null) continue;
      final dia = DateTime(fecha.year, fecha.month, fecha.day);
      mapa[dia] = (mapa[dia] ?? 0) + ((r['huevos_buenos'] as int?) ?? 0);
    }
    return Map.fromEntries(mapa.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  Map<DateTime, int> get _mortalidadPorDia {
    final mapa = <DateTime, int>{};
    for (final r in _registros) {
      final fecha = (r['fecha'] as Timestamp?)?.toDate();
      if (fecha == null) continue;
      final dia = DateTime(fecha.year, fecha.month, fecha.day);
      mapa[dia] = (mapa[dia] ?? 0) + ((r['mortalidad'] as int?) ?? 0);
    }
    return Map.fromEntries(mapa.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  Map<DateTime, double> get _ventasPorDia {
    final mapa = <DateTime, double>{};
    for (final v in _ventas) {
      final fecha = (v['fecha'] as Timestamp?)?.toDate();
      if (fecha == null) continue;
      final dia = DateTime(fecha.year, fecha.month, fecha.day);
      mapa[dia] = (mapa[dia] ?? 0) + ((v['total'] as num?)?.toDouble() ?? 0);
    }
    return Map.fromEntries(mapa.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  int get _totalUnidadesVendidas =>
      _ventas.fold(0, (s, v) => s + ((v['cantidad_unidades'] as int?) ?? 0));

  double get _totalIngresos =>
      _ventas.fold(0.0, (s, v) => s + ((v['total'] as num?)?.toDouble() ?? 0));

  int get _totalMortalidadPeriodo =>
      _registros.fold(0, (s, r) => s + ((r['mortalidad'] as int?) ?? 0));

  int get _totalHuevosPeriodo =>
      _registros.fold(0, (s, r) => s + ((r['huevos_buenos'] as int?) ?? 0));

  Future<void> _seleccionarRangoFechas() async {
    final rango = await mostrarSelectorRangoFechas(
      context: context,
      fechaDesdeActual: _fechaDesde,
      fechaHastaActual: _fechaHasta,
    );
    if (rango != null) {
      setState(() {
        _fechaDesde = rango.start;
        _fechaHasta = rango.end;
      });
      _cargarDatos();
    }
  }

  void _aplicarRangoRapido(int dias) {
    setState(() {
      _fechaHasta = DateTime.now();
      _fechaDesde = _fechaHasta.subtract(Duration(days: dias - 1));
    });
    _cargarDatos();
  }

  Future<void> _abrirFiltroGalpones() async {
    final resultado = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalFiltroGalpones(
        galpones: _todosLosGalpones,
        seleccionActual: _galponesSeleccionados,
      ),
    );
    if (resultado != null) {
      setState(() => _galponesSeleccionados = resultado);
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rangoDias = _fechaHasta.difference(_fechaDesde).inDays + 1;
    final filtroActivo = _galponesSeleccionados.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Reportes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarDatos),
        ],
      ),
      body: (_cargando || _cargandoGalpones)
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _cargarDatos,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      tituloSeccion('Filtros', Icons.filter_alt_outlined),
                      const SizedBox(height: 10),
                      _selectorRangoRapido(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _botonFiltro(
                              icono: Icons.date_range_outlined,
                              texto: '${_fmtFecha(_fechaDesde)} → ${_fmtFecha(_fechaHasta)}',
                              onTap: _seleccionarRangoFechas,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _botonFiltro(
                              icono: Icons.warehouse_outlined,
                              texto: filtroActivo
                                  ? '${_galponesSeleccionados.length} galpón(es)'
                                  : 'Todos los galpones',
                              onTap: _abrirFiltroGalpones,
                              activo: filtroActivo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      tituloSeccion('Producción de huevos ($rangoDias días)', Icons.egg_rounded),
                      const SizedBox(height: 10),
                      _produccionPorDia.isEmpty
                          ? _sinDatos('Sin datos de producción en el rango seleccionado.')
                          : _graficoLinea(datos: _produccionPorDia, color: colorPrimario, sufijo: 'huevos'),
                      const SizedBox(height: 24),

                      tituloSeccion('Ventas ($rangoDias días)', Icons.point_of_sale_rounded),
                      if (filtroActivo) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Las ventas no se asocian a un galpón: se muestran las de toda la operación.',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                      const SizedBox(height: 10),
                      if (_ventas.isNotEmpty) ...[
                        _resumenVentas(),
                        const SizedBox(height: 12),
                      ],
                      _ventasPorDia.isEmpty
                          ? _sinDatos('Sin ventas registradas en el rango seleccionado.')
                          : _graficoLinea(
                              datos: _ventasPorDia.map((k, v) => MapEntry(k, v.round())),
                              color: Colors.orange,
                              sufijo: '\$',
                              esMoneda: true,
                            ),
                      const SizedBox(height: 24),

                      tituloSeccion('Mortalidad ($rangoDias días)', Icons.monitor_heart_outlined),
                      const SizedBox(height: 10),
                      if (_registros.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total mortalidad del período', style: TextStyle(color: Colors.grey[700])),
                              Text(
                                '$_totalMortalidadPeriodo aves',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _totalMortalidadPeriodo > 20 ? Colors.red : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _mortalidadPorDia.isEmpty
                          ? _sinDatos('Sin registros de mortalidad en el rango seleccionado.')
                          : _graficoLinea(datos: _mortalidadPorDia, color: Colors.red, sufijo: 'aves'),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  String _fmtFecha(DateTime d) => '${d.day}/${d.month}';

  Widget _botonFiltro({
    required IconData icono,
    required String texto,
    required VoidCallback onTap,
    bool activo = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: activo ? colorPrimario.withOpacity(0.4) : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icono, size: 15, color: colorPrimario),
            const SizedBox(width: 6),
            Expanded(
              child: Text(texto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectorRangoRapido() {
    return Row(
      children: [7, 14, 30].map((dias) {
        final activo = _fechaHasta.difference(_fechaDesde).inDays + 1 == dias;
        return GestureDetector(
          onTap: () => _aplicarRangoRapido(dias),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: activo ? colorPrimario : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: activo ? colorPrimario : Colors.grey[300]!),
            ),
            child: Text('$dias días', style: TextStyle(color: activo ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _sinDatos(String texto) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: TextStyle(color: Colors.grey[600]))),
        ],
      ),
    );
  }

  Widget _resumenVentas() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.orange, Color(0xFFE65100)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(child: _datoVenta('\$${_totalIngresos.toStringAsFixed(0)}', 'Ingresos', Icons.attach_money_rounded)),
          Container(width: 1, height: 36, color: Colors.white24),
          Expanded(child: _datoVenta('$_totalUnidadesVendidas', 'Huevos vendidos', Icons.egg_rounded)),
          Container(width: 1, height: 36, color: Colors.white24),
          Expanded(child: _datoVenta('${_ventas.length}', 'Transacciones', Icons.receipt_outlined)),
        ],
      ),
    );
  }

  Widget _datoVenta(String valor, String etiqueta, IconData icono) {
    return Column(
      children: [
        Icon(icono, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(valor, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        Text(etiqueta, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _graficoLinea({
    required Map<DateTime, int> datos,
    required Color color,
    required String sufijo,
    bool esMoneda = false,
  }) {
    final entradas = datos.entries.toList();
    final maxVal = entradas.isEmpty ? 10 : entradas.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal * 1.2).toDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY == 0 ? 10 : maxY,
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[200]!, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) => Text(
                  esMoneda ? '\$${value.toInt()}' : value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (entradas.length / 4).ceilToDouble().clamp(1, 999),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entradas.length) return const SizedBox.shrink();
                  final fecha = entradas[index].key;
                  return Text('${fecha.day}/${fecha.month}', style: TextStyle(fontSize: 10, color: Colors.grey[500]));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: entradas.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value.toDouble())).toList(),
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: color)),
              belowBarData: BarAreaData(show: true, color: color.withOpacity(0.08)),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) {
                final fecha = entradas[spot.x.toInt()].key;
                final valorTexto = esMoneda ? '\$${spot.y.toInt()}' : '${spot.y.toInt()} $sufijo';
                return LineTooltipItem('${fecha.day}/${fecha.month}\n$valorTexto', const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold));
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalFiltroGalpones extends StatefulWidget {
  final List<QueryDocumentSnapshot> galpones;
  final Set<String> seleccionActual;

  const _ModalFiltroGalpones({required this.galpones, required this.seleccionActual});

  @override
  State<_ModalFiltroGalpones> createState() => _ModalFiltroGalponesState();
}

class _ModalFiltroGalponesState extends State<_ModalFiltroGalpones> {
  late Set<String> _seleccion;

  @override
  void initState() {
    super.initState();
    _seleccion = Set.from(widget.seleccionActual);
  }

  bool get _todosSeleccionados => _seleccion.isEmpty;

  @override
  Widget build(BuildContext context) {
    return hojaModal(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          manijaModal(),
          encabezadoModal('Filtrar por galpón', Icons.warehouse_outlined),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _seleccion.clear()),
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: _todosSeleccionados ? colorPrimario.withOpacity(0.08) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _todosSeleccionados ? colorPrimario : Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(_todosSeleccionados ? Icons.check_circle_rounded : Icons.circle_outlined, color: _todosSeleccionados ? colorPrimario : Colors.grey[400], size: 20),
                  const SizedBox(width: 10),
                  const Text('Todos los galpones', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 4),
          ...widget.galpones.map((doc) {
            final datos = doc.data() as Map<String, dynamic>;
            final marcado = _seleccion.contains(doc.id);
            return GestureDetector(
              onTap: () => setState(() => marcado ? _seleccion.remove(doc.id) : _seleccion.add(doc.id)),
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: marcado ? colorPrimario.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: marcado ? colorPrimario : Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(marcado ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: marcado ? colorPrimario : Colors.grey[400], size: 20),
                    const SizedBox(width: 10),
                    Text(datos['nombre_o_numero'] ?? 'Galpón'),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          botonGuardar(cargando: false, onPressed: () => Navigator.pop(context, _seleccion), texto: 'Aplicar filtro'),
        ],
      ),
    );
  }
}
