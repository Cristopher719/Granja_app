import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';

class CorreccionRegistroScreen extends StatefulWidget {
  final String idGalpon;
  final String nombreGalpon;
  final String idLote;
  final Map<String, dynamic> registroOriginal;

  const CorreccionRegistroScreen({
    super.key,
    required this.idGalpon,
    required this.nombreGalpon,
    required this.idLote,
    required this.registroOriginal,
  });

  @override
  State<CorreccionRegistroScreen> createState() =>
      _CorreccionRegistroScreenState();
}

class _CorreccionRegistroScreenState
    extends State<CorreccionRegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  late final TextEditingController _huevosBuenosController;
  late final TextEditingController _huevosRotosController;
  late final TextEditingController _alimentoController;
  late final TextEditingController _aguaController;
  late final TextEditingController _mortalidadController;
  late final TextEditingController _novedadesController;
  final TextEditingController _motivoController = TextEditingController();

  bool _guardando = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    final r = widget.registroOriginal;
    _huevosBuenosController = TextEditingController(
        text: '${r['huevos_buenos'] ?? 0}');
    _huevosRotosController = TextEditingController(
        text: '${r['huevos_rotos'] ?? 0}');
    _alimentoController = TextEditingController(
        text: '${r['alimento_kg'] ?? 0}');
    _aguaController = TextEditingController(
        text: '${r['agua_litros'] ?? 0}');
    _mortalidadController = TextEditingController(
        text: '${r['mortalidad'] ?? 0}');
    _novedadesController = TextEditingController(
        text: '${r['novedades'] ?? ''}');
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _errorMensaje = null;
    });

    try {
      final galponeroId = FirebaseAuth.instance.currentUser!.uid;

      await _firestoreService.registrarDatoDiario(
        idGalpon: widget.idGalpon,
        idLote: widget.idLote,
        huevosBuenos: int.parse(_huevosBuenosController.text.trim()),
        huevosPorTipo: {},
        huevosRotos: int.parse(_huevosRotosController.text.trim()),
        alimentoKg: double.parse(_alimentoController.text.trim()),
        aguaLitros: double.parse(_aguaController.text.trim()),
        mortalidad: int.parse(_mortalidadController.text.trim()),
        novedades: _novedadesController.text.trim(),
        registradoPor: galponeroId,
        esCorreccion: true,
        motivoCorreccion: _motivoController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Corrección registrada correctamente ✓')),
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
      appBar: appBarApp('Registrar corrección'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.orange[700], size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'El registro original se conserva. '
                        'Esta corrección queda marcada con tu justificación '
                        'y solo es válida el mismo día del registro.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              tituloSeccion('Motivo de la corrección',
                  Icons.edit_note_rounded),
              const SizedBox(height: 12),
              TextFormField(
                controller: _motivoController,
                maxLines: 3,
                decoration: decoracionCampo(
                  'Explica por qué estás corrigiendo este registro',
                  Icons.notes_rounded,
                ).copyWith(alignLabelWithHint: true),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El motivo de corrección es obligatorio'
                    : null,
              ),
              const SizedBox(height: 20),

              tituloSeccion(
                  'Valores corregidos', Icons.egg_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _huevosBuenosController,
                      keyboardType: TextInputType.number,
                      decoration: decoracionCampo(
                          'Buenos', Icons.check_circle_outline),
                      validator: _validarEntero,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _huevosRotosController,
                      keyboardType: TextInputType.number,
                      decoration:
                          decoracionCampo('Rotos', Icons.cancel_outlined),
                      validator: _validarEntero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _alimentoController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration:
                    decoracionCampo('Alimento (kg)', Icons.grain),
                validator: _validarDecimal,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aguaController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: decoracionCampo(
                    'Agua (litros)', Icons.water_drop_outlined),
                validator: _validarDecimal,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mortalidadController,
                keyboardType: TextInputType.number,
                decoration:
                    decoracionCampo('Mortalidad', Icons.crisis_alert),
                validator: _validarEntero,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _novedadesController,
                maxLines: 2,
                decoration: decoracionCampo(
                  'Novedades (opcional)',
                  Icons.edit_note,
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
                  child: Text(_errorMensaje!,
                      style: TextStyle(color: Colors.red[700])),
                ),
              ],

              const SizedBox(height: 24),
              botonGuardar(
                cargando: _guardando,
                onPressed: _guardando ? null : _guardar,
                texto: 'Guardar corrección',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String? _validarEntero(String? v) {
    if (v == null || v.isEmpty) return 'Requerido';
    if (int.tryParse(v) == null) return 'Solo números';
    if (int.parse(v) < 0) return 'No negativo';
    return null;
  }

  String? _validarDecimal(String? v) {
    if (v == null || v.isEmpty) return 'Requerido';
    if (double.tryParse(v) == null) return 'Solo números';
    if (double.parse(v) < 0) return 'No negativo';
    return null;
  }

  @override
  void dispose() {
    _huevosBuenosController.dispose();
    _huevosRotosController.dispose();
    _alimentoController.dispose();
    _aguaController.dispose();
    _mortalidadController.dispose();
    _novedadesController.dispose();
    _motivoController.dispose();
    super.dispose();
  }
}
