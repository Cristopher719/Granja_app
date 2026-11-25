import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';

class RegistroDiarioScreen extends StatefulWidget {
  final String idGalpon;
  final String nombreGalpon;

  const RegistroDiarioScreen({
    super.key,
    required this.idGalpon,
    required this.nombreGalpon,
  });

  @override
  State<RegistroDiarioScreen> createState() => _RegistroDiarioScreenState();
}

class _RegistroDiarioScreenState extends State<RegistroDiarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  final _huevosBuenosController = TextEditingController(text: '0');
  final _huevosRotosController = TextEditingController(text: '0');
  final _alimentoController = TextEditingController();
  final _aguaController = TextEditingController();
  final _mortalidadController = TextEditingController(text: '0');
  final _novedadesController = TextEditingController();

  bool _guardando = false;
  bool _verificando = true;
  bool _yaRegistroHoy = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _verificarRegistroHoy();
  }

  Future<void> _verificarRegistroHoy() async {
    try {
      final loteActivo =
          await _firestoreService.obtenerLoteActivo(widget.idGalpon);
      if (loteActivo != null) {
        final yaRegistro = await _firestoreService.verificarRegistroHoy(
          idGalpon: widget.idGalpon,
          idLote: loteActivo.id,
        );
        setState(() => _yaRegistroHoy = yaRegistro);
      }
    } finally {
      setState(() => _verificando = false);
    }
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
        setState(() => _errorMensaje =
            'Este galpón no tiene ciclo activo. Contacta al administrador.');
        return;
      }

      final galponeroId = FirebaseAuth.instance.currentUser!.uid;

      await _firestoreService.registrarDatoDiario(
        idGalpon: widget.idGalpon,
        idLote: loteActivo.id,
        huevosBuenos: int.parse(_huevosBuenosController.text.trim()),
        huevosPorTipo: {},
        huevosRotos: int.parse(_huevosRotosController.text.trim()),
        alimentoKg: double.parse(_alimentoController.text.trim()),
        aguaLitros: double.parse(_aguaController.text.trim()),
        mortalidad: int.parse(_mortalidadController.text.trim()),
        novedades: _novedadesController.text.trim(),
        registradoPor: galponeroId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro guardado correctamente ✓')),
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
      appBar: appBarApp('Registro diario'),
      body: _verificando
          ? const Center(child: CircularProgressIndicator())
          : _yaRegistroHoy
              ? _pantallaYaRegistrado()
              : _formulario(),
    );
  }

  Widget _pantallaYaRegistrado() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorPrimario.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: colorPrimario,
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ya registraste hoy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Los datos de hoy ya fueron reportados.\n'
              'Si necesitas hacer una corrección, ve al historial.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            botonGuardar(
              cargando: false,
              onPressed: () => Navigator.pop(context),
              texto: 'Volver',
            ),
          ],
        ),
      ),
    );
  }

  Widget _formulario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cabecera(),
            const SizedBox(height: 20),

            tituloSeccion('Producción de huevos', Icons.egg_rounded),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _huevosBuenosController,
                    keyboardType: TextInputType.number,
                    decoration:
                        decoracionCampo('Buenos', Icons.check_circle_outline),
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El bodeguero clasificará los huevos por tipo '
                      '(B, A, AA, AAA) al recibirlos.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            tituloSeccion('Consumo', Icons.restaurant_outlined),
            const SizedBox(height: 12),
            TextFormField(
              controller: _alimentoController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  decoracionCampo('Alimento consumido (kg)', Icons.grain),
              validator: _validarDecimal,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _aguaController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: decoracionCampo(
                  'Agua consumida (litros)', Icons.water_drop_outlined),
              validator: _validarDecimal,
            ),

            const SizedBox(height: 20),
            tituloSeccion('Mortalidad', Icons.monitor_heart_outlined),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mortalidadController,
              keyboardType: TextInputType.number,
              decoration:
                  decoracionCampo('Aves muertas hoy', Icons.crisis_alert),
              validator: _validarEntero,
            ),

            const SizedBox(height: 20),
            tituloSeccion('Novedades', Icons.notes_rounded),
            const SizedBox(height: 12),
            TextFormField(
              controller: _novedadesController,
              maxLines: 3,
              decoration: decoracionCampo(
                'Observaciones del día (opcional)',
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
              texto: 'Guardar registro del día',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _cabecera() {
    final hoy = DateTime.now();
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return Container(
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
      child: Row(
        children: [
          iconoCirculo(Icons.warehouse_rounded),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.nombreGalpon,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                '${hoy.day} de ${meses[hoy.month - 1]} de ${hoy.year}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
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
    super.dispose();
  }
}
