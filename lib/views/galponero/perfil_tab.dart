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
                  'Galponero',
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
              const Divider(),
              const SizedBox(height: 24),
              const SizedBox(height: 8),
              const CambiarContrasenaWidget(),
              const SizedBox(height: 12),
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
