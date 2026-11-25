import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';
import 'clasificador_por_peso.dart';

const List<String> tiposHuevoColombia = ['B', 'A', 'AA', 'AAA'];

class ClasificacionHuevosTab extends StatefulWidget {
  const ClasificacionHuevosTab({super.key});

  @override
  State<ClasificacionHuevosTab> createState() => _ClasificacionHuevosTabState();
}

class _ClasificacionHuevosTabState extends State<ClasificacionHuevosTab> {
  final _firestoreService = FirestoreService();
  String? _adminId;
  String? _galponSeleccionado;
  bool _cargando = true;

  final Map<String, TextEditingController> _controllers = {
    for (final tipo in tiposHuevoColombia)
      tipo: TextEditingController(text: '0'),
  };
  final _formKey = GlobalKey<FormState>();
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarAdmin();
  }

  Future<void> _cargarAdmin() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final datos = await _firestoreService.obtenerUsuario(uid);
    setState(() {
      _adminId = datos?['creado_por'] as String?;
      _cargando = false;
    });
  }

  void _sumarUno(String categoria) {
    final c = _controllers[categoria];
    if (c == null) return;
    setState(() => c.text = '${(int.tryParse(c.text) ?? 0) + 1}');
  }

  int get _totalClasificado => tiposHuevoColombia.fold(
    0,
    (s, t) => s + (int.tryParse(_controllers[t]!.text) ?? 0),
  );

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_galponSeleccionado == null) {
      setState(() => _error = 'Selecciona un galpón.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final bodegueroId = FirebaseAuth.instance.currentUser!.uid;
      final clasificacion = {
        for (final tipo in tiposHuevoColombia)
          tipo: int.tryParse(_controllers[tipo]!.text) ?? 0,
      };

      await _firestoreService.registrarClasificacionHuevos(
        bodegueroId: bodegueroId,
        idGalpon: _galponSeleccionado!,
        clasificacion: clasificacion,
        total: _totalClasificado,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clasificación registrada ✓')),
        );
        for (final c in _controllers.values) c.text = '0';
        setState(() => _galponSeleccionado = null);
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarApp('Clasificar Huevos'),
      body: _cargando || _adminId == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tituloSeccion('Galpón de origen', Icons.warehouse_outlined),
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
                    tituloSeccion('Clasificar por peso', Icons.scale_outlined),
                    const SizedBox(height: 12),
                    ClasificadorPorPeso(onSumar: _sumarUno),

                    const SizedBox(height: 20),
                    tituloSeccion('Cantidad por tipo', Icons.egg_rounded),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 2.5,
                            children: tiposHuevoColombia.map((tipo) {
                              final colores = {
                                'B': Colors.brown,
                                'A': Colors.orange,
                                'AA': Colors.amber,
                                'AAA': colorPrimario,
                              };
                              return TextFormField(
                                controller: _controllers[tipo],
                                keyboardType: TextInputType.number,
                                decoration: decoracionCampo(
                                  'Huevo $tipo',
                                  Icons.egg_outlined,
                                ).copyWith(prefixIconColor: colores[tipo]),
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Req.';
                                  if (int.tryParse(v) == null) return 'Núm.';
                                  if (int.parse(v) < 0) return 'Pos.';
                                  return null;
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colorPrimario.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total clasificado',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '$_totalClasificado huevos',
                                  style: TextStyle(
                                    color: colorPrimario,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    botonGuardar(
                      cargando: _guardando,
                      onPressed: _guardando ? null : _guardar,
                      texto: 'Registrar clasificación',
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
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }
}
