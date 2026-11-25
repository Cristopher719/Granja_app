import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';

class RegistroSanitarioScreen extends StatefulWidget {
  final String idGalpon;
  final String nombreGalpon;

  const RegistroSanitarioScreen({
    super.key,
    required this.idGalpon,
    required this.nombreGalpon,
  });

  @override
  State<RegistroSanitarioScreen> createState() =>
      _RegistroSanitarioScreenState();
}

class _RegistroSanitarioScreenState extends State<RegistroSanitarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  final _productoController = TextEditingController();
  final _dosisController = TextEditingController();
  final _unidadController = TextEditingController();

  String _tipoEvento = 'vacunacion';
  XFile? _fotoSeleccionada;
  bool _guardando = false;
  String? _errorMensaje;

  static const _tiposEvento = [
    {'valor': 'vacunacion', 'etiqueta': 'Vacunación', 'icono': Icons.vaccines},
    {'valor': 'medicacion', 'etiqueta': 'Medicación', 'icono': Icons.medication_outlined},
    {'valor': 'desinfeccion', 'etiqueta': 'Desinfección', 'icono': Icons.cleaning_services_outlined},
  ];

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final foto = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (foto != null) setState(() => _fotoSeleccionada = foto);
  }

  Future<String?> _subirFoto(String idLote) async {
    if (_fotoSeleccionada == null) return null;

    final nombreArchivo =
        '${widget.idGalpon}_${idLote}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = FirebaseStorage.instance
        .ref()
        .child('registros_sanitarios/$nombreArchivo');

    await ref.putFile(File(_fotoSeleccionada!.path));
    return await ref.getDownloadURL();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _errorMensaje = null;
    });

    try {
      final loteActivo =
          await _firestoreService.obtenerLoteActivo(widget.idGalpon);

      if (loteActivo == null) {
        setState(() {
          _errorMensaje =
              'Este galpón no tiene un ciclo activo. '
              'Contacta al administrador.';
        });
        return;
      }

      final fotoUrl = await _subirFoto(loteActivo.id);
      final galponeroId = FirebaseAuth.instance.currentUser!.uid;

      await _firestoreService.registrarEventoSanitario(
        idGalpon: widget.idGalpon,
        idLote: loteActivo.id,
        tipoEvento: _tipoEvento,
        productoAplicado: _productoController.text.trim(),
        dosis: {
          'cantidad': double.tryParse(_dosisController.text.trim()) ?? 0,
          'unidad': _unidadController.text.trim(),
        },
        fotoUrl: fotoUrl ?? '',
        registradoPor: galponeroId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento sanitario guardado correctamente ✓'),
          ),
        );
        Navigator.pop(context);
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
      appBar: appBarApp('Evento sanitario'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tituloSeccion('Tipo de evento', Icons.medical_services_outlined),
              const SizedBox(height: 12),
              Row(
                children: _tiposEvento.map((tipo) {
                  final seleccionado = _tipoEvento == tipo['valor'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _tipoEvento = tipo['valor'] as String),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: seleccionado
                              ? colorPrimario
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: seleccionado
                                ? colorPrimario
                                : Colors.grey[200]!,
                          ),
                          boxShadow: seleccionado
                              ? [
                                  BoxShadow(
                                    color: colorPrimario.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              tipo['icono'] as IconData,
                              color: seleccionado
                                  ? Colors.white
                                  : Colors.grey[500],
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tipo['etiqueta'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: seleccionado
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              tituloSeccion(
                _tipoEvento == 'desinfeccion'
                    ? 'Producto de desinfección'
                    : 'Producto',
                Icons.science_outlined,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _productoController,
                decoration: decoracionCampo(
                  _tipoEvento == 'desinfeccion'
                      ? 'Producto utilizado'
                      : 'Nombre del producto aplicado',
                  Icons.label_outline,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingresa el producto' : null,
              ),
              if (_tipoEvento != 'desinfeccion') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _dosisController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: decoracionCampo('Dosis', Icons.numbers),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (double.tryParse(v) == null) return 'Solo números';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unidadController,
                        decoration: decoracionCampo('Unidad', Icons.straighten),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.teal.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.teal[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'La desinfección es un proceso al galpón — '
                          'no requiere dosis por ave.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.teal[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              tituloSeccion('Foto comprobante', Icons.camera_alt_outlined),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _seleccionarFoto,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _fotoSeleccionada != null
                          ? colorPrimario
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: _fotoSeleccionada != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(_fotoSeleccionada!.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 36,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toca para tomar una foto\n(opcional)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              if (_errorMensaje != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMensaje!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],

              const SizedBox(height: 24),
              botonGuardar(
                cargando: _guardando,
                onPressed: _guardando ? null : _guardar,
                texto: 'Guardar evento sanitario',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget tituloSeccion(String titulo, IconData icono) {
    return Row(
      children: [
        Icon(icono, size: 18, color: colorPrimario),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _productoController.dispose();
    _dosisController.dispose();
    _unidadController.dispose();
    super.dispose();
  }
}
