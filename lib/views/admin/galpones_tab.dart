import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';
import 'galpon_detalle_screen.dart';

class GalponesTab extends StatelessWidget {
  const GalponesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final adminId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarApp('Mis Galpones'),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.obtenerGalpones(adminId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar galpones: ${snapshot.error}'),
            );
          }

          final galpones = snapshot.data?.docs ?? [];

          if (galpones.isEmpty) {
            return estadoVacio(
              'Aún no tienes galpones.\nCrea el primero con el botón +',
              Icons.warehouse_outlined,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: galpones.length,
            itemBuilder: (context, index) {
              final doc = galpones[index];
              final datos = doc.data() as Map<String, dynamic>;
              final galponeroId = datos['galponero_id'] as String?;

              return tarjetaItem(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GalponDetalleScreen(
                        idGalpon: doc.id,
                        nombreGalpon: datos['nombre_o_numero'] ?? 'Galpón',
                      ),
                    ),
                  );
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    iconoCirculo(Icons.warehouse_rounded),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            datos['nombre_o_numero'] ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.egg_outlined,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${datos['capacidad_maxima'] ?? '-'} aves',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _GalponeroAsignadoChip(galponeroId: galponeroId),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      tooltip: 'Asignar o cambiar galponero',
                      onPressed: () => _mostrarFormularioAsignarGalponero(
                        context,
                        adminId: adminId,
                        idGalpon: doc.id,
                        galponeroIdActual: galponeroId,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorPrimario,
        onPressed: () => _mostrarFormularioCrearGalpon(context, adminId),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _mostrarFormularioCrearGalpon(BuildContext context, String adminId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioCrearGalpon(adminId: adminId),
    );
  }

  void _mostrarFormularioAsignarGalponero(
    BuildContext context, {
    required String adminId,
    required String idGalpon,
    required String? galponeroIdActual,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioAsignarGalponero(
        adminId: adminId,
        idGalpon: idGalpon,
        galponeroIdActual: galponeroIdActual,
      ),
    );
  }
}

class _GalponeroAsignadoChip extends StatelessWidget {
  final String? galponeroId;
  const _GalponeroAsignadoChip({required this.galponeroId});

  @override
  Widget build(BuildContext context) {
    if (galponeroId == null) {
      return badgeEstado('Sin asignar', color: Colors.grey);
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: FirestoreService().obtenerUsuario(galponeroId!),
      builder: (context, snapshot) {
        final nombre = snapshot.data?['nombre'] as String?;
        return badgeEstado(
          nombre ?? 'Cargando...',
          color: colorPrimario,
          icono: Icons.person,
        );
      },
    );
  }
}

class _FormularioCrearGalpon extends StatefulWidget {
  final String adminId;
  const _FormularioCrearGalpon({required this.adminId});

  @override
  State<_FormularioCrearGalpon> createState() => _FormularioCrearGalponState();
}

class _FormularioCrearGalponState extends State<_FormularioCrearGalpon> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _guardando = false;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      await _firestoreService.crearGalpon(
        nombreONumero: _nombreController.text.trim(),
        capacidadMaxima: int.parse(_capacidadController.text.trim()),
        administradorId: widget.adminId,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al crear el galpón: $e')));
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
            encabezadoModal('Nuevo galpón', Icons.warehouse_rounded),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nombreController,
              decoration: decoracionCampo(
                'Nombre o número del galpón',
                Icons.tag,
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingresa un nombre' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _capacidadController,
              keyboardType: TextInputType.number,
              decoration: decoracionCampo(
                'Capacidad máxima (aves)',
                Icons.numbers,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa la capacidad';
                if (int.tryParse(v) == null) return 'Debe ser un número';
                return null;
              },
            ),
            const SizedBox(height: 22),
            botonGuardar(
              cargando: _guardando,
              onPressed: _guardando ? null : _guardar,
              texto: 'Guardar galpón',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _capacidadController.dispose();
    super.dispose();
  }
}

class _FormularioAsignarGalponero extends StatefulWidget {
  final String adminId;
  final String idGalpon;
  final String? galponeroIdActual;

  const _FormularioAsignarGalponero({
    required this.adminId,
    required this.idGalpon,
    required this.galponeroIdActual,
  });

  @override
  State<_FormularioAsignarGalponero> createState() =>
      _FormularioAsignarGalponeroState();
}

class _FormularioAsignarGalponeroState
    extends State<_FormularioAsignarGalponero> {
  final _firestoreService = FirestoreService();
  String? _galponeroSeleccionado;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _galponeroSeleccionado = widget.galponeroIdActual;
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await _firestoreService.asignarGalponeroAGalpon(
        idGalpon: widget.idGalpon,
        galponeroId: _galponeroSeleccionado,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return hojaModal(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          manijaModal(),
          encabezadoModal('Asignar galponero', Icons.person_add_alt_1),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.obtenerGalponeros(widget.adminId),
            builder: (context, snapshot) {
              final galponeros = snapshot.data?.docs ?? [];
              return DropdownButtonFormField<String>(
                initialValue: _galponeroSeleccionado,
                decoration: decoracionCampo(
                  'Galponero responsable',
                  Icons.person_outline,
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sin asignar'),
                  ),
                  ...galponeros.map((doc) {
                    final datos = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(datos['nombre'] ?? doc.id),
                    );
                  }),
                ],
                onChanged: (valor) =>
                    setState(() => _galponeroSeleccionado = valor),
              );
            },
          ),
          const SizedBox(height: 22),
          botonGuardar(
            cargando: _guardando,
            onPressed: _guardando ? null : _guardar,
            texto: 'Guardar asignación',
          ),
        ],
      ),
    );
  }
}
