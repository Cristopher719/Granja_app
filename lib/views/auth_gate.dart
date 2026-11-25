import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';
import 'consentimiento_screen.dart';
import 'admin/admin_home_screen.dart';
import 'galponero/galponero_home_screen.dart';
import 'propietario/propietario_home_screen.dart';
import 'vendedor/vendedor_home_screen.dart';
import 'bodeguero/bodeguero_home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.cambiosDeUsuario,
      builder: (context, snapshotAuth) {
        if (snapshotAuth.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final usuario = snapshotAuth.data;
        if (usuario == null) return const LoginScreen();

        return FutureBuilder<Map<String, dynamic>?>(
          future: _firestoreService.obtenerUsuario(usuario.uid),
          builder: (context, snapshotUsuario) {
            if (snapshotUsuario.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final datos = snapshotUsuario.data;

            final aceptado =
                datos?['consentimiento_aceptado'] == true &&
                datos?['version_politica'] ==
                    FirestoreService.versionPoliticaDatos;
            if (datos != null && !aceptado) {
              return ConsentimientoScreen(onAceptado: () => setState(() {}));
            }

            switch (datos?['rol']) {
              case 'administrador':
                return const AdminHomeScreen();
              case 'propietario':
                return const PropietarioHomeScreen();
              case 'galponero':
                return const GalponeroHomeScreen();
              case 'vendedor':
                return const VendedorHomeScreen();
              case 'bodeguero':
                return const BodegueroHomeScreen();
              default:
                return const Scaffold(
                  body: Center(
                    child: Text(
                      'Rol no reconocido.\nContacta al administrador.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
            }
          },
        );
      },
    );
  }
}
