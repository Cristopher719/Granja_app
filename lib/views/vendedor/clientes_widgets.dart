import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';

const Color colorVendedorClientes = Colors.orange;

String? validarCedula(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return 'Ingresa la cédula o NIT';
  if (!RegExp(r'^\d{5,12}(-\d)?$').hasMatch(t)) {
    return 'Solo números (NIT con guion: 900123456-7)';
  }
  return null;
}

String? validarTelefono(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return 'Ingresa el teléfono';
  if (!RegExp(r'^\d{7,10}$').hasMatch(t)) return 'Entre 7 y 10 dígitos';
  return null;
}

String? validarNombre(String? v) =>
    (v ?? '').trim().length < 3 ? 'Ingresa el nombre del cliente' : null;

final formatoCedula = FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'));
final formatoTelefono = FilteringTextInputFormatter.digitsOnly;

Future<Map<String, String>?> seleccionarClienteFrecuente(
  BuildContext context,
  String adminId,
) {
  return showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SelectorClientes(adminId: adminId),
  );
}

class _SelectorClientes extends StatefulWidget {
  final String adminId;
  const _SelectorClientes({required this.adminId});

  @override
  State<_SelectorClientes> createState() => _SelectorClientesState();
}

class _SelectorClientesState extends State<_SelectorClientes> {
  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    return hojaModal(
      context: context,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            manijaModal(),
            encabezadoModal('Clientes frecuentes', Icons.people_alt_outlined),
            const SizedBox(height: 12),
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
                adminId: widget.adminId,
                filtro: _filtro,
                onTap: (id, d) => Navigator.pop(context, {
                  'id': id,
                  'nombre': d['nombre'] ?? '',
                  'cedula': d['cedula'] ?? '',
                  'telefono': d['telefono'] ?? '',
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListaClientes extends StatelessWidget {
  final String adminId;
  final String filtro;
  final void Function(String id, Map<String, dynamic> datos) onTap;
  final Widget Function(String id, Map<String, dynamic> datos)? acciones;

  const ListaClientes({
    super.key,
    required this.adminId,
    required this.filtro,
    required this.onTap,
    this.acciones,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService().obtenerClientes(adminId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs =
            (snap.data?.docs ?? []).where((d) {
              final m = d.data() as Map<String, dynamic>;
              final texto = '${m['nombre'] ?? ''} ${m['cedula'] ?? ''}'
                  .toLowerCase();
              return filtro.isEmpty || texto.contains(filtro);
            }).toList()..sort(
              (a, b) => ((a.data() as Map)['nombre'] ?? '')
                  .toString()
                  .toLowerCase()
                  .compareTo(
                    ((b.data() as Map)['nombre'] ?? '')
                        .toString()
                        .toLowerCase(),
                  ),
            );

        if (docs.isEmpty) {
          return estadoVacio(
            filtro.isEmpty
                ? 'Aún no hay clientes frecuentes.\nSe guardan al registrar una venta o desde la pestaña Clientes.'
                : 'Ningún cliente coincide con la búsqueda.',
            Icons.people_outline,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return tarjetaItem(
              onTap: () => onTap(docs[i].id, d),
              child: Row(
                children: [
                  iconoCirculo(
                    Icons.person_outline,
                    color: colorVendedorClientes,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['nombre'] ?? 'Sin nombre',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'C.C./NIT ${d['cedula'] ?? '-'}  ·  Tel. ${d['telefono'] ?? '-'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (acciones != null) acciones!(docs[i].id, d),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> abrirFormularioCliente(
  BuildContext context, {
  required String adminId,
  String? id,
  Map<String, dynamic>? datos,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FormularioCliente(adminId: adminId, id: id, datos: datos),
  );
}

class _FormularioCliente extends StatefulWidget {
  final String adminId;
  final String? id;
  final Map<String, dynamic>? datos;
  const _FormularioCliente({required this.adminId, this.id, this.datos});

  @override
  State<_FormularioCliente> createState() => _FormularioClienteState();
}

class _FormularioClienteState extends State<_FormularioCliente> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(
    text: widget.datos?['nombre'] ?? '',
  );
  late final _cedula = TextEditingController(
    text: widget.datos?['cedula'] ?? '',
  );
  late final _telefono = TextEditingController(
    text: widget.datos?['telefono'] ?? '',
  );
  bool _guardando = false;
  String? _error;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await FirestoreService().guardarCliente(
        id: widget.id,
        adminId: widget.adminId,
        usuarioId: FirebaseAuth.instance.currentUser!.uid,
        nombre: _nombre.text.trim(),
        cedula: _cedula.text.trim(),
        telefono: _telefono.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'No se pudo guardar: $e');
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
            encabezadoModal(
              widget.id == null ? 'Nuevo cliente' : 'Editar cliente',
              Icons.person_add_alt_1_outlined,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              decoration: decoracionCampo(
                'Nombre o razón social',
                Icons.store_outlined,
              ),
              validator: validarNombre,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cedula,
              keyboardType: TextInputType.number,
              inputFormatters: [formatoCedula],
              decoration: decoracionCampo('Cédula o NIT', Icons.badge_outlined),
              validator: validarCedula,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              inputFormatters: [formatoTelefono],
              decoration: decoracionCampo('Teléfono', Icons.phone_outlined),
              validator: validarTelefono,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            botonGuardar(
              cargando: _guardando,
              onPressed: _guardando ? null : _guardar,
              texto: 'Guardar cliente',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombre.dispose();
    _cedula.dispose();
    _telefono.dispose();
    super.dispose();
  }
}
