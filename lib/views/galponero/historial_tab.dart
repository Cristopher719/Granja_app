import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';
import '../../widgets/registrado_por_widget.dart';
import '../../widgets/selector_rango_fechas.dart';
import 'correccion_registro_screen.dart';

class HistorialTab extends StatefulWidget {
  const HistorialTab({super.key});

  @override
  State<HistorialTab> createState() => _HistorialTabState();
}

class _HistorialTabState extends State<HistorialTab> {
  final _firestoreService = FirestoreService();
  bool _mostrandoDiarios = true;

  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  int _rangoRapido = 30;

  @override
  Widget build(BuildContext context) {
    final galponeroId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Mi Historial',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.date_range_outlined,
              color: (_fechaDesde != null || _fechaHasta != null)
                  ? colorPrimario
                  : Colors.grey,
            ),
            tooltip: 'Filtrar por fecha',
            onPressed: () => _mostrarFiltroFecha(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.obtenerGalponesAsignados(galponeroId),
        builder: (context, snapshotGalpones) {
          if (snapshotGalpones.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final galpones = snapshotGalpones.data?.docs ?? [];

          if (galpones.isEmpty) {
            return estadoVacio(
              'No tienes galpones asignados.',
              Icons.warehouse_outlined,
            );
          }

          return FutureBuilder<QueryDocumentSnapshot?>(
            future: _firestoreService.obtenerLoteActivo(galpones.first.id),
            builder: (context, snapshotLote) {
              if (snapshotLote.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final loteActivo = snapshotLote.data;

              if (loteActivo == null) {
                return estadoVacio(
                  'No hay ciclo activo.\nLos registros se muestran\ncuando hay un ciclo en curso.',
                  Icons.egg_outlined,
                );
              }

              final loteData = loteActivo.data() as Map<String, dynamic>;

              return Column(
                children: [
                  _CabeceraCiclo(datos: loteData),

                  _SelectorRangoRapido(
                    rangoActual: _rangoRapido,
                    tieneFiltroPersonalizado:
                        _fechaDesde != null || _fechaHasta != null,
                    onCambio: (rango) => setState(() {
                      _rangoRapido = rango;
                      _fechaDesde = null;
                      _fechaHasta = null;
                    }),
                    onLimpiar: () => setState(() {
                      _fechaDesde = null;
                      _fechaHasta = null;
                      _rangoRapido = 30;
                    }),
                    fechaDesde: _fechaDesde,
                    fechaHasta: _fechaHasta,
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _ToggleTipo(
                      mostrandoDiarios: _mostrandoDiarios,
                      onCambio: (valor) =>
                          setState(() => _mostrandoDiarios = valor),
                    ),
                  ),

                  Expanded(
                    child: _mostrandoDiarios
                        ? _ListaDiarios(
                            idGalpon: galpones.first.id,
                            idLote: loteActivo.id,
                            firestoreService: _firestoreService,
                            fechaDesde:
                                _fechaDesde ??
                                DateTime.now().subtract(
                                  Duration(days: _rangoRapido),
                                ),
                            fechaHasta: _fechaHasta ?? DateTime.now(),
                          )
                        : _ListaSanitarios(
                            idGalpon: galpones.first.id,
                            idLote: loteActivo.id,
                            firestoreService: _firestoreService,
                            fechaDesde:
                                _fechaDesde ??
                                DateTime.now().subtract(
                                  Duration(days: _rangoRapido),
                                ),
                            fechaHasta: _fechaHasta ?? DateTime.now(),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _mostrarFiltroFecha(BuildContext context) async {
    final rango = await mostrarSelectorRangoFechas(
      context: context,
      fechaDesdeActual:
          _fechaDesde ?? DateTime.now().subtract(const Duration(days: 30)),
      fechaHastaActual: _fechaHasta ?? DateTime.now(),
    );

    if (rango != null) {
      setState(() {
        _fechaDesde = rango.start;
        _fechaHasta = rango.end;
      });
    }
  }
}

class _CabeceraCiclo extends StatelessWidget {
  final Map<String, dynamic> datos;
  const _CabeceraCiclo({required this.datos});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorPrimario.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorPrimario.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          iconoCirculo(Icons.egg_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ciclo activo: ${datos['raza'] ?? '-'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${datos['cantidad_inicial'] ?? '-'} aves · '
                  '${datos['edad_semanas'] ?? '-'} semanas',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          badgeEstado('Activo', color: colorPrimario),
        ],
      ),
    );
  }
}

class _ToggleTipo extends StatelessWidget {
  final bool mostrandoDiarios;
  final ValueChanged<bool> onCambio;

  const _ToggleTipo({required this.mostrandoDiarios, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _botonToggle(
            'Registros diarios',
            Icons.edit_calendar_outlined,
            seleccionado: mostrandoDiarios,
            onTap: () => onCambio(true),
          ),
          _botonToggle(
            'Eventos sanitarios',
            Icons.medical_services_outlined,
            seleccionado: !mostrandoDiarios,
            onTap: () => onCambio(false),
          ),
        ],
      ),
    );
  }

  Widget _botonToggle(
    String texto,
    IconData icono, {
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: seleccionado ? colorPrimario : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icono,
                size: 16,
                color: seleccionado ? Colors.white : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                texto,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: seleccionado ? Colors.white : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListaDiarios extends StatelessWidget {
  final String idGalpon;
  final String idLote;
  final FirestoreService firestoreService;
  final DateTime fechaDesde;
  final DateTime fechaHasta;

  const _ListaDiarios({
    required this.idGalpon,
    required this.idLote,
    required this.firestoreService,
    required this.fechaDesde,
    required this.fechaHasta,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: firestoreService.obtenerHistorialDiario(
        idGalpon: idGalpon,
        idLote: idLote,
        limite: 200,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final todos = snapshot.data ?? [];
        final registros = todos.where((r) {
          final fecha = (r['fecha'] as Timestamp?)?.toDate();
          if (fecha == null) return false;
          final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
          final desde = DateTime(
            fechaDesde.year,
            fechaDesde.month,
            fechaDesde.day,
          );
          final hasta = DateTime(
            fechaHasta.year,
            fechaHasta.month,
            fechaHasta.day,
          );
          return !soloFecha.isBefore(desde) && !soloFecha.isAfter(hasta);
        }).toList();

        if (registros.isEmpty) {
          return estadoVacio(
            'Aún no tienes registros diarios\nen este ciclo.',
            Icons.edit_calendar_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: registros.length,
          itemBuilder: (context, index) {
            final r = registros[index];
            final fecha = (r['fecha'] as Timestamp?)?.toDate();
            final fechaStr = fecha != null
                ? '${fecha.day}/${fecha.month}/${fecha.year}'
                : '-';
            final mortalidad = (r['mortalidad'] as int?) ?? 0;
            final esCorreccion = r['es_correccion'] as bool? ?? false;
            final esHoy =
                fecha != null &&
                fecha.day == DateTime.now().day &&
                fecha.month == DateTime.now().month &&
                fecha.year == DateTime.now().year;

            return tarjetaItem(
              onTap: () => _mostrarDetalle(context, r, fechaStr),
              child: Row(
                children: [
                  iconoCirculo(
                    esCorreccion
                        ? Icons.edit_calendar_rounded
                        : Icons.calendar_today_outlined,
                    color: esCorreccion ? Colors.orange : colorPrimario,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              fechaStr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (esCorreccion) ...[
                              const SizedBox(width: 6),
                              badgeEstado(
                                'Corrección',
                                color: Colors.orange,
                                icono: Icons.edit_outlined,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '🥚 ${r['huevos_buenos'] ?? 0} buenos · '
                          '${r['huevos_rotos'] ?? 0} rotos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '🌾 ${r['alimento_kg'] ?? 0} kg · '
                          '💧 ${r['agua_litros'] ?? 0} L',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (mortalidad > 0)
                        badgeEstado(
                          '$mortalidad muertas',
                          color: mortalidad > 5 ? Colors.red : Colors.orange,
                          icono: Icons.monitor_heart_outlined,
                        )
                      else
                        badgeEstado('Sin mortalidad', color: colorPrimario),
                      if (esHoy && !esCorreccion) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CorreccionRegistroScreen(
                                idGalpon: idGalpon,
                                nombreGalpon: 'Galpón',
                                idLote: idLote,
                                registroOriginal: r,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'Corregir',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDetalle(
    BuildContext context,
    Map<String, dynamic> r,
    String fecha,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => hojaModal(
        context: context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            manijaModal(),
            encabezadoModal(
              (r['es_correccion'] as bool? ?? false)
                  ? 'Corrección del $fecha'
                  : 'Registro del $fecha',
              (r['es_correccion'] as bool? ?? false)
                  ? Icons.edit_calendar_rounded
                  : Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 20),
            if (r['es_correccion'] as bool? ?? false) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Corrección registrada',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    if ((r['motivo_correccion'] as String?)?.isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 4),
                      Text(
                        r['motivo_correccion'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _filaDetalle(
              'Huevos buenos',
              '${r['huevos_buenos'] ?? 0}',
              Icons.egg_rounded,
              colorPrimario,
            ),
            _filaDetalle(
              'Huevos rotos',
              '${r['huevos_rotos'] ?? 0}',
              Icons.egg_outlined,
              Colors.orange,
            ),
            _filaDetalle(
              'Alimento',
              '${r['alimento_kg'] ?? 0} kg',
              Icons.grain,
              Colors.brown,
            ),
            _filaDetalle(
              'Agua',
              '${r['agua_litros'] ?? 0} litros',
              Icons.water_drop_outlined,
              Colors.blue,
            ),
            _filaDetalle(
              'Mortalidad',
              '${r['mortalidad'] ?? 0} aves',
              Icons.monitor_heart_outlined,
              (r['mortalidad'] ?? 0) > 5 ? Colors.red : Colors.grey,
            ),
            if ((r['registrado_por'] as String?) != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    'Registrado por: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  RegistradoPorWidget(
                    uid: r['registrado_por'] as String?,
                    color: colorPrimario,
                  ),
                ],
              ),
            ],
            if ((r['novedades'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Novedades',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(r['novedades'] as String),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _filaDetalle(
    String etiqueta,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: 10),
          Text(etiqueta, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(
            valor,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _ListaSanitarios extends StatelessWidget {
  final String idGalpon;
  final String idLote;
  final FirestoreService firestoreService;
  final DateTime fechaDesde;
  final DateTime fechaHasta;

  const _ListaSanitarios({
    required this.idGalpon,
    required this.idLote,
    required this.firestoreService,
    required this.fechaDesde,
    required this.fechaHasta,
  });

  static const _iconosTipo = {
    'vacunacion': Icons.vaccines,
    'medicacion': Icons.medication_outlined,
    'desinfeccion': Icons.cleaning_services_outlined,
  };

  static const _coloresTipo = {
    'vacunacion': Colors.blue,
    'medicacion': Colors.purple,
    'desinfeccion': Colors.teal,
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: firestoreService.obtenerHistorialSanitario(
        idGalpon: idGalpon,
        idLote: idLote,
        limite: 200,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final todos = snapshot.data ?? [];
        final registros = todos.where((r) {
          final fecha = (r['fecha'] as Timestamp?)?.toDate();
          if (fecha == null) return false;
          final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
          final desde = DateTime(
            fechaDesde.year,
            fechaDesde.month,
            fechaDesde.day,
          );
          final hasta = DateTime(
            fechaHasta.year,
            fechaHasta.month,
            fechaHasta.day,
          );
          return !soloFecha.isBefore(desde) && !soloFecha.isAfter(hasta);
        }).toList();

        if (registros.isEmpty) {
          return estadoVacio(
            'Aún no tienes eventos sanitarios\nen este ciclo.',
            Icons.medical_services_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: registros.length,
          itemBuilder: (context, index) {
            final r = registros[index];
            final tipo = r['tipo_evento'] as String? ?? 'vacunacion';
            final fecha = (r['fecha'] as Timestamp?)?.toDate();
            final fechaStr = fecha != null
                ? '${fecha.day}/${fecha.month}/${fecha.year}'
                : '-';
            final dosis = r['dosis'] as Map<String, dynamic>?;
            final color = _coloresTipo[tipo] ?? colorPrimario;
            final icono = _iconosTipo[tipo] ?? Icons.medical_services_outlined;
            final etiqueta = tipo == 'vacunacion'
                ? 'Vacunación'
                : tipo == 'medicacion'
                ? 'Medicación'
                : 'Desinfección';

            return tarjetaItem(
              onTap: () =>
                  _mostrarDetalle(context, r, fechaStr, etiqueta, color, icono),
              child: Row(
                children: [
                  iconoCirculo(icono, color: color),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['producto_aplicado'] ?? 'Sin producto',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fechaStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (dosis != null)
                          Text(
                            'Dosis: ${dosis['cantidad']} ${dosis['unidad']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  badgeEstado(etiqueta, color: color),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDetalle(
    BuildContext context,
    Map<String, dynamic> r,
    String fecha,
    String etiqueta,
    Color color,
    IconData icono,
  ) {
    final dosis = r['dosis'] as Map<String, dynamic>?;
    final fotoUrl = r['foto_url'] as String?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => hojaModal(
        context: context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            manijaModal(),
            encabezadoModal(etiqueta, icono),
            const SizedBox(height: 20),
            _fila('Producto', r['producto_aplicado'] ?? '-', color),
            if (dosis != null)
              _fila('Dosis', '${dosis['cantidad']} ${dosis['unidad']}', color),
            _fila('Fecha', fecha, color),
            if (fotoUrl != null && fotoUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Foto comprobante',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  fotoUrl,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 60,
                    color: Colors.grey[100],
                    child: Center(
                      child: Text(
                        'No se pudo cargar la foto',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _fila(String etiqueta, String valor, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(etiqueta, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(
            valor,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _SelectorRangoRapido extends StatelessWidget {
  final int rangoActual;
  final bool tieneFiltroPersonalizado;
  final ValueChanged<int> onCambio;
  final VoidCallback onLimpiar;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;

  const _SelectorRangoRapido({
    required this.rangoActual,
    required this.tieneFiltroPersonalizado,
    required this.onCambio,
    required this.onLimpiar,
    this.fechaDesde,
    this.fechaHasta,
  });

  String _formatFecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tieneFiltroPersonalizado && fechaDesde != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorPrimario.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorPrimario.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range_outlined,
                    size: 14,
                    color: colorPrimario,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatFecha(fechaDesde!)} → ${_formatFecha(fechaHasta ?? DateTime.now())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorPrimario,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onLimpiar,
                    child: Icon(Icons.close, size: 14, color: colorPrimario),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                _botonRango('Hoy', 0),
                const SizedBox(width: 8),
                _botonRango('7 días', 7),
                const SizedBox(width: 8),
                _botonRango('30 días', 30),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _botonRango(String texto, int dias) {
    final seleccionado =
        !tieneFiltroPersonalizado &&
        (dias == 0 ? rangoActual == 1 : rangoActual == dias);

    return GestureDetector(
      onTap: () => onCambio(dias == 0 ? 1 : dias),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: seleccionado ? colorPrimario : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? colorPrimario : Colors.grey[300]!,
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: seleccionado ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
