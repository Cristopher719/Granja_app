import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';
import 'clientes_widgets.dart';

class ClientesTab extends StatefulWidget {
  const ClientesTab({super.key});

  @override
  State<ClientesTab> createState() => _ClientesTabState();
}

class _ClientesTabState extends State<ClientesTab> {
  String? _adminId;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _cargarAdmin();
  }

  Future<void> _cargarAdmin() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final datos = await FirestoreService().obtenerUsuario(uid);
    if (mounted) setState(() => _adminId = datos?['creado_por'] as String?);
  }

  Future<void> _eliminar(String id, String nombre) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text(
          '¿Eliminar a "$nombre" de los clientes frecuentes? '
          'Las ventas ya registradas no se modifican.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) await FirestoreService().eliminarCliente(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarApp('Clientes frecuentes'),
      floatingActionButton: _adminId == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: colorVendedorClientes,
              foregroundColor: Colors.white,
              onPressed: () =>
                  abrirFormularioCliente(context, adminId: _adminId!),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Nuevo cliente'),
            ),
      body: _adminId == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  TextField(
                    decoration: decoracionCampo(
                      'Buscar por nombre o cédula',
                      Icons.search,
                    ),
                    onChanged: (v) =>
                        setState(() => _filtro = v.trim().toLowerCase()),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListaClientes(
                      adminId: _adminId!,
                      filtro: _filtro,
                      onTap: (id, d) => abrirFormularioCliente(
                        context,
                        adminId: _adminId!,
                        id: id,
                        datos: d,
                      ),
                      acciones: (id, d) => IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Eliminar',
                        onPressed: () => _eliminar(id, d['nombre'] ?? ''),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
