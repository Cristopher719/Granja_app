import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';

class UsuariosTab extends StatefulWidget {
  const UsuariosTab({super.key});

  @override
  State<UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<UsuariosTab> {
  String? _filtroRol;

  static const _coloresRol = {
    'administrador': Colors.purple,
    'propietario': Colors.blue,
    'galponero': Color(0xFF388E3C),
    'vendedor': Colors.orange,
    'bodeguero': Colors.brown,
  };

  static const _iconosRol = {
    'administrador': Icons.manage_accounts_rounded,
    'propietario': Icons.business_center_rounded,
    'galponero': Icons.warehouse_rounded,
    'vendedor': Icons.point_of_sale_rounded,
    'bodeguero': Icons.inventory_2_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final adminId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarApp('Usuarios'),
      body: Column(
        children: [
          _FiltroPorRol(
            filtroActual: _filtroRol,
            onCambio: (rol) => setState(() => _filtroRol = rol),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.obtenerTodosLosUsuarios(adminId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var usuarios = snapshot.data?.docs ?? [];

                if (_filtroRol != null) {
                  usuarios = usuarios.where((d) {
                    final datos = d.data() as Map<String, dynamic>;
                    return datos['rol'] == _filtroRol;
                  }).toList();
                }

                if (usuarios.isEmpty) {
                  return estadoVacio(
                    _filtroRol == null
                        ? 'Aún no has creado usuarios.\nUsa el botón +'
                        : 'No hay usuarios con rol "${AuthService.etiquetasRol[_filtroRol]}".',
                    Icons.people_outline,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    final datos =
                        usuarios[index].data() as Map<String, dynamic>;
                    final rol = datos['rol'] as String? ?? 'galponero';
                    final color = _coloresRol[rol] ?? colorPrimario;
                    final icono = _iconosRol[rol] ?? Icons.person_rounded;

                    return tarjetaItem(
                      child: Row(
                        children: [
                          iconoCirculo(icono, color: color),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  datos['nombre'] ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 12,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        datos['correo'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          badgeEstado(
                            AuthService.etiquetasRol[rol] ?? rol,
                            color: color,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorPrimario,
        onPressed: () => _mostrarFormularioCrearUsuario(context, adminId),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  void _mostrarFormularioCrearUsuario(BuildContext context, String adminId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioCrearUsuario(adminId: adminId),
    );
  }
}

class _FiltroPorRol extends StatelessWidget {
  final String? filtroActual;
  final ValueChanged<String?> onCambio;

  const _FiltroPorRol({required this.filtroActual, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    final opciones = [null, ...AuthService.rolesValidos];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: opciones.length,
        itemBuilder: (context, index) {
          final rol = opciones[index];
          final seleccionado = filtroActual == rol;
          final etiqueta = rol == null
              ? 'Todos'
              : AuthService.etiquetasRol[rol] ?? rol;

          return GestureDetector(
            onTap: () => onCambio(rol),
            child: Container(
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: seleccionado ? colorPrimario : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: seleccionado ? colorPrimario : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Text(
                  etiqueta,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: seleccionado ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FormularioCrearUsuario extends StatefulWidget {
  final String adminId;
  const _FormularioCrearUsuario({required this.adminId});

  @override
  State<_FormularioCrearUsuario> createState() =>
      _FormularioCrearUsuarioState();
}

class _FormularioCrearUsuarioState extends State<_FormularioCrearUsuario> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _authService = AuthService();

  String _rolSeleccionado = 'galponero';
  bool _guardando = false;
  String? _errorMensaje;

  static const _coloresRol = {
    'administrador': Colors.purple,
    'propietario': Colors.blue,
    'galponero': Color(0xFF388E3C),
    'vendedor': Colors.orange,
    'bodeguero': Colors.brown,
  };

  static const _iconosRol = {
    'administrador': Icons.manage_accounts_rounded,
    'propietario': Icons.business_center_rounded,
    'galponero': Icons.warehouse_rounded,
    'vendedor': Icons.point_of_sale_rounded,
    'bodeguero': Icons.inventory_2_rounded,
  };

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _errorMensaje = null;
    });

    try {
      await _authService.crearUsuario(
        nombre: _nombreController.text.trim(),
        correo: _correoController.text.trim(),
        contrasena: _contrasenaController.text.trim(),
        rol: _rolSeleccionado,
        creadoPorAdminId: widget.adminId,
      );

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMensaje = _mensajeError(e.code));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String _mensajeError(String codigo) {
    switch (codigo) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      default:
        return 'No se pudo crear la cuenta. Intenta de nuevo.';
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
            encabezadoModal('Nuevo usuario', Icons.person_add_alt_1),
            const SizedBox(height: 20),

            const Text(
              'Rol',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AuthService.rolesValidos.map((rol) {
                final seleccionado = _rolSeleccionado == rol;
                final color = _coloresRol[rol] ?? colorPrimario;
                final icono = _iconosRol[rol] ?? Icons.person;

                return GestureDetector(
                  onTap: () => setState(() => _rolSeleccionado = rol),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: seleccionado ? color : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: seleccionado ? color : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icono,
                          size: 14,
                          color: seleccionado ? Colors.white : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AuthService.etiquetasRol[rol] ?? rol,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: seleccionado
                                ? Colors.white
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nombreController,
              decoration: decoracionCampo(
                'Nombre completo',
                Icons.badge_outlined,
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingresa un nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              decoration: decoracionCampo('Correo', Icons.email_outlined),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingresa un correo' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contrasenaController,
              obscureText: true,
              decoration: decoracionCampo(
                'Contraseña temporal',
                Icons.lock_outline,
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 20),

            if (_errorMensaje != null) ...[
              Text(
                _errorMensaje!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],

            botonGuardar(
              cargando: _guardando,
              onPressed: _guardando ? null : _guardar,
              texto: 'Crear usuario',
            ),
            const SizedBox(height: 8),
            Text(
              'El usuario podrá cambiar su contraseña desde su perfil.',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }
}
