import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';
import 'clientes_widgets.dart';

const List<String> tiposHuevoColombia = ['B', 'A', 'AA', 'AAA'];

class NuevaVentaTab extends StatefulWidget {
  const NuevaVentaTab({super.key});

  @override
  State<NuevaVentaTab> createState() => _NuevaVentaTabState();
}

class _NuevaVentaTabState extends State<NuevaVentaTab> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();
  final _clienteController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _telefonoController = TextEditingController();
  String? _clienteId;
  bool _guardarFrecuente = true;
  final _notasController = TextEditingController();

  String _tipoHuevo = 'A';
  bool _guardando = false;
  bool _cargandoStock = true;
  String? _errorMensaje;
  String? _adminId;
  Map<String, int> _stockPorTipo = {};

  static const _coloresTipo = {
    'B': Colors.brown,
    'A': Colors.orange,
    'AA': Colors.amber,
    'AAA': colorPrimario,
  };

  @override
  void initState() {
    super.initState();
    _cargarStock();
  }

  Future<void> _cargarStock() async {
    setState(() => _cargandoStock = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final datos = await _firestoreService.obtenerUsuario(uid);
      _adminId = datos?['creado_por'] as String?;

      if (_adminId != null) {
        final stock = await _firestoreService.calcularStockHuevosPorTipo(
          adminId: _adminId!,
        );
        setState(() => _stockPorTipo = stock);
      }
    } finally {
      setState(() => _cargandoStock = false);
    }
  }

  int get _stockTipoSeleccionado => _stockPorTipo[_tipoHuevo] ?? 0;

  double get _totalCalculado {
    final cantidad = int.tryParse(_cantidadController.text) ?? 0;
    final precio = double.tryParse(_precioController.text) ?? 0;
    return cantidad * precio;
  }

  bool get _superaStock {
    final cantidad = int.tryParse(_cantidadController.text) ?? 0;
    return cantidad > _stockTipoSeleccionado;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_superaStock) {
      final continuar = await _confirmarSobreStock();
      if (continuar != true) return;
    }

    setState(() {
      _guardando = true;
      _errorMensaje = null;
    });

    try {
      final vendedorId = FirebaseAuth.instance.currentUser!.uid;
      if (_adminId == null) {
        final datos = await _firestoreService.obtenerUsuario(vendedorId);
        _adminId = datos?['creado_por'] as String?;
      }
      if (_adminId == null) {
        throw Exception('No se encontró el administrador de este vendedor.');
      }
      String? clienteId = _clienteId;
      if (clienteId != null || _guardarFrecuente) {
        clienteId = await _firestoreService.guardarCliente(
          id: clienteId,
          adminId: _adminId!,
          usuarioId: vendedorId,
          nombre: _clienteController.text.trim(),
          cedula: _cedulaController.text.trim(),
          telefono: _telefonoController.text.trim(),
        );
      }

      await _firestoreService.registrarVenta(
        vendedorId: vendedorId,
        adminId: _adminId!,
        tipoHuevo: _tipoHuevo,
        cantidadUnidades: int.parse(_cantidadController.text.trim()),
        precioUnidad: double.parse(_precioController.text.trim()),
        cliente: _clienteController.text.trim(),
        clienteCedula: _cedulaController.text.trim(),
        clienteTelefono: _telefonoController.text.trim(),
        clienteId: clienteId,
        notas: _notasController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta registrada correctamente ✓')),
        );
        _limpiarFormulario();
        _cargarStock();
      }
    } catch (e) {
      setState(() => _errorMensaje = 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<bool?> _confirmarSobreStock() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stock insuficiente'),
        content: Text(
          'Solo hay $_stockTipoSeleccionado huevos tipo $_tipoHuevo en stock, '
          'pero estás vendiendo ${_cantidadController.text}. '
          '¿Deseas continuar de todas formas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<void> _elegirClienteFrecuente() async {
    final c = await seleccionarClienteFrecuente(context, _adminId!);
    if (c == null) return;
    setState(() {
      _clienteId = c['id'];
      _clienteController.text = c['nombre'] ?? '';
      _cedulaController.text = c['cedula'] ?? '';
      _telefonoController.text = c['telefono'] ?? '';
    });
  }

  void _limpiarFormulario() {
    _cantidadController.clear();
    _precioController.clear();
    _clienteController.clear();
    _cedulaController.clear();
    _telefonoController.clear();
    _clienteId = null;
    _guardarFrecuente = true;
    _notasController.clear();
    setState(() => _tipoHuevo = 'A');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarApp('Nueva Venta'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  tituloSeccion('Tipo de huevo', Icons.egg_outlined),
                  if (_cargandoStock)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    GestureDetector(
                      onTap: _cargarStock,
                      child: Icon(
                        Icons.refresh,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: tiposHuevoColombia.map((tipo) {
                  final seleccionado = _tipoHuevo == tipo;
                  final color = _coloresTipo[tipo] ?? colorPrimario;
                  final stock = _stockPorTipo[tipo] ?? 0;
                  final sinStock = !_cargandoStock && stock <= 0;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tipoHuevo = tipo),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: seleccionado ? color : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: seleccionado ? color : Colors.grey[200]!,
                          ),
                          boxShadow: seleccionado
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.egg_rounded,
                              color: seleccionado
                                  ? Colors.white
                                  : Colors.grey[400],
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tipo,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: seleccionado
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _cargandoStock ? '...' : '$stock uds',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: seleccionado
                                    ? Colors.white70
                                    : sinStock
                                    ? Colors.red
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (!_cargandoStock) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _stockTipoSeleccionado <= 0
                        ? Colors.red.withOpacity(0.08)
                        : colorPrimario.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _stockTipoSeleccionado <= 0
                          ? Colors.red.withOpacity(0.3)
                          : colorPrimario.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _stockTipoSeleccionado <= 0
                            ? Icons.error_outline
                            : Icons.inventory_2_outlined,
                        size: 16,
                        color: _stockTipoSeleccionado <= 0
                            ? Colors.red
                            : colorPrimario,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _stockTipoSeleccionado <= 0
                              ? 'Sin stock de huevo tipo $_tipoHuevo'
                              : 'Stock disponible: $_stockTipoSeleccionado huevos tipo $_tipoHuevo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _stockTipoSeleccionado <= 0
                                ? Colors.red
                                : colorPrimario,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              tituloSeccion('Cantidad y precio', Icons.numbers),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: decoracionCampo(
                        'Unidades',
                        Icons.egg_outlined,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (int.tryParse(v) == null) return 'Solo números';
                        if (int.parse(v) <= 0) return 'Mayor a 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _precioController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: decoracionCampo(
                        'Precio/ud',
                        Icons.attach_money,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Solo números';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              if (_superaStock && _cantidadController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'La cantidad supera el stock disponible ($_stockTipoSeleccionado uds).',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (_cantidadController.text.isNotEmpty &&
                  _precioController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total de la venta',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '\$${_totalCalculado.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: tituloSeccion('Cliente', Icons.person_outline),
                  ),
                  TextButton.icon(
                    onPressed: _adminId == null
                        ? null
                        : _elegirClienteFrecuente,
                    icon: const Icon(Icons.people_alt_outlined, size: 18),
                    label: const Text('Frecuentes'),
                  ),
                ],
              ),
              if (_clienteId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Cliente frecuente seleccionado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _clienteId = null;
                          _clienteController.clear();
                          _cedulaController.clear();
                          _telefonoController.clear();
                        }),
                        child: const Text(
                          'Quitar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _clienteController,
                textCapitalization: TextCapitalization.words,
                decoration: decoracionCampo(
                  'Nombre o razón social',
                  Icons.store_outlined,
                ),
                validator: validarNombre,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cedulaController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [formatoCedula],
                      decoration: decoracionCampo(
                        'Cédula o NIT',
                        Icons.badge_outlined,
                      ),
                      validator: validarCedula,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [formatoTelefono],
                      decoration: decoracionCampo(
                        'Teléfono',
                        Icons.phone_outlined,
                      ),
                      validator: validarTelefono,
                    ),
                  ),
                ],
              ),
              if (_clienteId == null)
                CheckboxListTile(
                  value: _guardarFrecuente,
                  onChanged: (v) =>
                      setState(() => _guardarFrecuente = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Guardar como cliente frecuente',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              const SizedBox(height: 12),
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
                texto: 'Registrar venta',
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
    _precioController.dispose();
    _clienteController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _notasController.dispose();
    super.dispose();
  }
}
