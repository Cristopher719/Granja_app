import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/form_helpers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();

  bool _cargando = false;
  bool _verContrasena = false;
  String? _errorMensaje;

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    try {
      await _authService.iniciarSesion(
        correo: _correoController.text.trim(),
        contrasena: _contrasenaController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMensaje = _mensajeError(e.code));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _mensajeError(String codigo) {
    switch (codigo) {
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde.';
      default:
        return 'Ocurrió un error al iniciar sesión. Intenta de nuevo.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _Cabecera(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Inicia sesión',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ingresa con tu cuenta asignada por el administrador.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 28),

                    TextFormField(
                      controller: _correoController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: decoracionCampo(
                        'Correo',
                        Icons.email_outlined,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu correo';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _contrasenaController,
                      obscureText: !_verContrasena,
                      decoration:
                          decoracionCampo(
                            'Contraseña',
                            Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _verContrasena
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: colorPrimario,
                              ),
                              onPressed: () => setState(
                                () => _verContrasena = !_verContrasena,
                              ),
                            ),
                          ),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    if (_errorMensaje != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red[700],
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMensaje!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    botonGuardar(
                      cargando: _cargando,
                      onPressed: _cargando ? null : _iniciarSesion,
                      texto: 'Ingresar',
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              'Granja App © ${DateTime.now().year}',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }
}

class _Cabecera extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [colorPrimario, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.egg_alt_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Granja App',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gestión de galpones de gallinas ponedoras',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
