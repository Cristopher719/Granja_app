import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';
import '../../widgets/cambiar_contrasena_widget.dart';

class PerfilTab extends StatelessWidget {
  const PerfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final authService = AuthService();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: firestoreService.obtenerUsuario(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar el perfil: ${snapshot.error}'),
            );
          }

          final datos = snapshot.data;
          final nombre = datos?['nombre'] as String? ?? 'Sin nombre';
          final correo = datos?['correo'] as String? ?? '-';
          final rol = datos?['rol'] as String? ?? '-';

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: colorPrimario,
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Administrador',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Correo'),
                subtitle: Text(correo),
              ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Rol'),
                subtitle: Text(rol),
              ),
              const Divider(),
              const SizedBox(height: 16),
              const CambiarContrasenaWidget(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.science_outlined,
                          color: Colors.blue[700],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'DATOS DE DEMOSTRACIÓN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Carga datos de ejemplo para presentar la app. '
                      'Puedes borrarlos sin afectar datos reales.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                    ),
                    const SizedBox(height: 12),
                    _BotonesDemoWidget(uid: uid),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _confirmarCerrarSesion(context, authService),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmarCerrarSesion(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authService.cerrarSesion();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _BotonesDemoWidget extends StatefulWidget {
  final String uid;
  const _BotonesDemoWidget({required this.uid});

  @override
  State<_BotonesDemoWidget> createState() => _BotonesDemoWidgetState();
}

class _BotonesDemoWidgetState extends State<_BotonesDemoWidget> {
  final _firestoreService = FirestoreService();
  bool _cargando = false;

  Future<void> _cargarDemo() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cargar datos demo'),
        content: const Text(
          'Se crearán 2 galpones con 14 días de registros de ejemplo. '
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Cargar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _cargando = true);
    try {
      final resumen = await _firestoreService.cargarDatosDemo(
        adminId: widget.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Datos cargados: $resumen')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _limpiarDemo() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar datos demo'),
        content: const Text(
          'Se eliminarán todos los datos de demostración. '
          'Los datos reales no se verán afectados. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _cargando = true);
    try {
      final total = await _firestoreService.limpiarDatosDemo(
        adminId: widget.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$total documentos eliminados ✓')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _cargarDemo,
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Cargar demo', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[700],
              side: BorderSide(color: Colors.blue[300]!),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _limpiarDemo,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Limpiar demo', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[400],
              side: BorderSide(color: Colors.red[200]!),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
