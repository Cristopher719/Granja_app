import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';

class EntradaAlimentoTab extends StatefulWidget {
  final String? idGalponInicial;

  final bool cerrarAlGuardar;

  final bool conteoInicial;

  const EntradaAlimentoTab({
    super.key,
    this.idGalponInicial,
    this.cerrarAlGuardar = false,
    this.conteoInicial = false,
  });

  @override
  State<EntradaAlimentoTab> createState() => _EntradaAlimentoTabState();
}

class _EntradaAlimentoTabState extends State<EntradaAlimentoTab> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _cantidadController = TextEditingController();
  final _notasController = TextEditingController();

  String? _galponSeleccionado;
  String? _adminId;
  bool _guardando = false;
  late bool _esConteo = widget.conteoInicial;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _galponSeleccionado = widget.idGalponInicial;
    _cargarAdminId();
  }

  Future<void> _cargarAdminId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final datos = await _firestoreService.obtenerUsuario(uid);
    setState(() => _adminId = datos?['creado_por'] as String?);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_galponSeleccionado == null) {
      setState(() => _errorMensaje = 'Selecciona el galpón destino.');
      return;
    }

    setState(() {
      _guardando = true;
      _errorMensaje = null;
    });

    try {
      final bodegueroId = FirebaseAuth.instance.currentUser!.uid;
      await _firestoreService.registrarEntradaAlimento(
        bodegueroId: bodegueroId,
        idGalpon: _galponSeleccionado!,
        cantidadKg: double.parse(_cantidadController.text.trim()),
        precioKg: 0,
        proveedor: 'Empresa propia',
        tipo: _esConteo ? 'conteo' : 'entrada',
        notas: _notasController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrada registrada correctamente ✓')),
        );
        if (widget.cerrarAlGuardar) {
          Navigator.pop(context, true);
          return;
        }
        _cantidadController.clear();
        _notasController.clear();
        setState(() => _galponSeleccionado = null);
      }
    } catch (e) {
      setState(() => _errorMensaje = 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarApp(
        _esConteo ? 'Conteo físico de alimento' : 'Entrada de Alimento',
      ),
      body: _adminId == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tituloSeccion('Galpón destino', Icons.warehouse_outlined),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestoreService.obtenerGalpones(_adminId!),
                      builder: (context, snapshot) {
                        final galpones = snapshot.data?.docs ?? [];
                        return DropdownButtonFormField<String>(
                          value: _galponSeleccionado,
                          decoration: decoracionCampo(
                            'Selecciona el galpón',
                            Icons.warehouse_rounded,
                          ),
                          items: galpones.map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(d['nombre_o_numero'] ?? doc.id),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _galponSeleccionado = v),
                          validator: (_) => _galponSeleccionado == null
                              ? 'Selecciona un galpón'
                              : null,
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    tituloSeccion('Tipo de registro', Icons.swap_vert),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Entrada'),
                          icon: Icon(Icons.add_box_outlined),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Conteo físico'),
                          icon: Icon(Icons.fact_check_outlined),
                        ),
                      ],
                      selected: {_esConteo},
                      onSelectionChanged: (s) =>
                          setState(() => _esConteo = s.first),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _esConteo
                          ? 'Pesa o cuenta el alimento que hay hoy en la bodega para este galpón. Ese valor pasa a ser el stock real y desde ahí se descuenta el consumo diario.'
                          : 'Registra el alimento que llega a la bodega para este galpón. Se suma al stock disponible.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    tituloSeccion('Cantidad', Icons.scale_outlined),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cantidadController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: decoracionCampo(
                        _esConteo
                            ? 'Cantidad contada en bodega (kg)'
                            : 'Cantidad que llega (kg)',
                        Icons.grain,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Solo números';
                        if (double.parse(v) < 0 ||
                            (!_esConteo && double.parse(v) == 0))
                          return _esConteo
                              ? 'No puede ser negativo'
                              : 'Mayor a 0';
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _notasController,
                      maxLines: 2,
                      decoration: decoracionCampo(
                        'Notas (opcional)',
                        Icons.notes_rounded,
                      ).copyWith(alignLabelWithHint: true),
                    ),

                    if (_errorMensaje != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          _errorMensaje!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    botonGuardar(
                      cargando: _guardando,
                      onPressed: _guardando ? null : _guardar,
                      texto: _esConteo ? 'Guardar conteo' : 'Registrar entrada',
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _notasController.dispose();
    super.dispose();
  }
}
