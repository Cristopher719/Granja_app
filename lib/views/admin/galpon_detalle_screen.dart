import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';

class GalponDetalleScreen extends StatelessWidget {
  final String idGalpon;
  final String nombreGalpon;

  const GalponDetalleScreen({
    super.key,
    required this.idGalpon,
    required this.nombreGalpon,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarApp(nombreGalpon),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.obtenerLotes(idGalpon),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar lotes: ${snapshot.error}'),
            );
          }

          final lotes = snapshot.data?.docs ?? [];

          final loteActivoDoc = lotes
              .where(
                (d) => (d.data() as Map<String, dynamic>)['estado'] == 'activo',
              )
              .firstOrNull;

          final historial = lotes
              .where(
                (d) => (d.data() as Map<String, dynamic>)['estado'] != 'activo',
              )
              .toList();

          final hayLoteActivo = loteActivoDoc != null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _seccionTitulo('Ciclo actual'),
              const SizedBox(height: 8),
              if (hayLoteActivo)
                _TarjetaLoteActivo(
                  doc: loteActivoDoc,
                  idGalpon: idGalpon,
                  firestoreService: firestoreService,
                )
              else
                _tarjetaSinLote(context),

              if (historial.isNotEmpty) ...[
                const SizedBox(height: 24),
                _seccionTitulo('Historial de ciclos'),
                const SizedBox(height: 8),
                ...historial.map((doc) => _TarjetaLoteHistorial(doc: doc)),
              ],

              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.obtenerLotes(idGalpon),
        builder: (context, snapshot) {
          final lotes = snapshot.data?.docs ?? [];
          final hayActivo = lotes.any(
            (d) => (d.data() as Map<String, dynamic>)['estado'] == 'activo',
          );

          if (hayActivo) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            backgroundColor: colorPrimario,
            onPressed: () => _mostrarFormularioCrearLote(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Nuevo ciclo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _seccionTitulo(String titulo) {
    return Text(
      titulo.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey[500],
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _tarjetaSinLote(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.egg_outlined, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Sin ciclo activo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Presiona "Nuevo ciclo" para iniciar\nun nuevo ciclo de producción.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioCrearLote(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioCrearLote(idGalpon: idGalpon),
    );
  }
}

class _TarjetaLoteActivo extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String idGalpon;
  final FirestoreService firestoreService;

  const _TarjetaLoteActivo({
    required this.doc,
    required this.idGalpon,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    final datos = doc.data() as Map<String, dynamic>;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorPrimario, const Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorPrimario.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.egg_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                datos['raza'] ?? 'Sin raza',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Activo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _datoCiclo(
                Icons.numbers,
                '${datos['cantidad_inicial'] ?? '-'}',
                'aves',
              ),
              const SizedBox(width: 24),
              _datoCiclo(
                Icons.calendar_month_outlined,
                '${datos['edad_semanas'] ?? '-'}',
                'semanas',
              ),
            ],
          ),
          const SizedBox(height: 12),
          AvesVivasContador(
            idGalpon: idGalpon,
            idLote: doc.id,
            cantidadInicial: (datos['cantidad_inicial'] as int?) ?? 0,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmarFinalizar(context),
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text(
                'Finalizar ciclo',
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _datoCiclo(IconData icono, String valor, String etiqueta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              etiqueta,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _confirmarFinalizar(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar ciclo'),
        content: const Text(
          '¿Estás seguro? Esto cerrará el ciclo de producción actual '
          'y lo moverá al historial. No podrás agregar más registros '
          'diarios a este lote después de finalizar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await firestoreService.finalizarLote(
                idGalpon: idGalpon,
                idLote: doc.id,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorPrimario,
              foregroundColor: Colors.white,
            ),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }
}

class _TarjetaLoteHistorial extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _TarjetaLoteHistorial({required this.doc});

  @override
  Widget build(BuildContext context) {
    final datos = doc.data() as Map<String, dynamic>;
    final fechaIngreso = (datos['fecha_ingreso'] as Timestamp?)?.toDate();
    final fechaFin = (datos['fecha_fin'] as Timestamp?)?.toDate();

    String fmt(DateTime? d) =>
        d != null ? '${d.day}/${d.month}/${d.year}' : '-';

    return tarjetaItem(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconoCirculo(Icons.egg_outlined, color: Colors.grey),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  datos['raza'] ?? 'Sin raza',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${datos['cantidad_inicial'] ?? '-'} aves iniciales',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${fmt(fechaIngreso)} → ${fmt(fechaFin)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _TotalHuevosLote(
                  idGalpon: doc.reference.parent.parent!.id,
                  idLote: doc.id,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          badgeEstado('Finalizado', color: Colors.grey),
        ],
      ),
    );
  }
}

class _TotalHuevosLote extends StatelessWidget {
  final String idGalpon;
  final String idLote;
  const _TotalHuevosLote({required this.idGalpon, required this.idLote});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('galpones')
          .doc(idGalpon)
          .collection('lotes_aves')
          .doc(idLote)
          .collection('registros_diarios')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            'Calculando producción...',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          );
        }

        final totalHuevos = snapshot.data!.docs.fold<int>(
          0,
          (s, d) =>
              s +
              (((d.data() as Map<String, dynamic>)['huevos_buenos'] as int?) ??
                  0),
        );
        final totalDias = snapshot.data!.docs.length;

        return Row(
          children: [
            Icon(Icons.egg_rounded, size: 13, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              '$totalHuevos huevos en $totalDias días',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FormularioCrearLote extends StatefulWidget {
  final String idGalpon;
  const _FormularioCrearLote({required this.idGalpon});

  @override
  State<_FormularioCrearLote> createState() => _FormularioCrearLoteState();
}

class _FormularioCrearLoteState extends State<_FormularioCrearLote> {
  final _formKey = GlobalKey<FormState>();
  final _razaController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _edadController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _guardando = false;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      await _firestoreService.crearLote(
        idGalpon: widget.idGalpon,
        cantidadInicial: int.parse(_cantidadController.text.trim()),
        raza: _razaController.text.trim(),
        edadSemanas: int.parse(_edadController.text.trim()),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return hojaModal(
      context: context,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            manijaModal(),
            encabezadoModal('Nuevo ciclo de producción', Icons.egg_rounded),
            const SizedBox(height: 20),
            TextFormField(
              controller: _razaController,
              decoration: decoracionCampo('Raza', Icons.category_outlined),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingresa la raza' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _cantidadController,
              keyboardType: TextInputType.number,
              decoration: decoracionCampo(
                'Cantidad inicial de aves',
                Icons.numbers,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa la cantidad';
                if (int.tryParse(v) == null) return 'Debe ser un número';
                if (int.parse(v) <= 0) return 'Debe ser mayor a 0';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _edadController,
              keyboardType: TextInputType.number,
              decoration: decoracionCampo(
                'Edad actual (semanas)',
                Icons.calendar_month_outlined,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa la edad';
                if (int.tryParse(v) == null) return 'Debe ser un número';
                return null;
              },
            ),
            const SizedBox(height: 22),
            botonGuardar(
              cargando: _guardando,
              onPressed: _guardando ? null : _guardar,
              texto: 'Iniciar ciclo',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _razaController.dispose();
    _cantidadController.dispose();
    _edadController.dispose();
    super.dispose();
  }
}
