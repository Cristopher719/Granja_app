import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'form_helpers.dart';

class CambiarContrasenaWidget extends StatelessWidget {
  const CambiarContrasenaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _mostrarModal(context),
      icon: const Icon(Icons.lock_outline),
      label: const Text('Cambiar contraseña'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: colorPrimario),
        foregroundColor: colorPrimario,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  void _mostrarModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FormularioCambioContrasena(),
    );
  }
}

class _FormularioCambioContrasena extends StatefulWidget {
  const _FormularioCambioContrasena();

  @override
  State<_FormularioCambioContrasena> createState() =>
      _FormularioCambioContrasenaState();
}

class _FormularioCambioContrasenaState
    extends State<_FormularioCambioContrasena> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _verActual = false;
  bool _verNueva = false;
  bool _verConfirmar = false;
  bool _guardando = false;
  String? _errorMensaje;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _errorMensaje = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final credencial = EmailAuthProvider.credential(
        email: user.email!,
        password: _actualController.text.trim(),
      );
      await user.reauthenticateWithCredential(credencial);

      await _authService.cambiarContrasena(
          _nuevaController.text.trim());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada correctamente ✓'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMensaje = _mensajeError(e.code));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String _mensajeError(String codigo) {
    switch (codigo) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'La contraseña actual es incorrecta.';
      case 'weak-password':
        return 'La nueva contraseña debe tener al menos 6 caracteres.';
      case 'requires-recent-login':
        return 'Cierra sesión e inicia de nuevo antes de cambiar la contraseña.';
      default:
        return 'No se pudo cambiar la contraseña. Intenta de nuevo.';
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
            encabezadoModal('Cambiar contraseña', Icons.lock_outline),
            const SizedBox(height: 20),

            TextFormField(
              controller: _actualController,
              obscureText: !_verActual,
              decoration: decoracionCampo(
                'Contraseña actual',
                Icons.lock_outline,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _verActual
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: colorPrimario,
                  ),
                  onPressed: () =>
                      setState(() => _verActual = !_verActual),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Ingresa tu contraseña actual'
                  : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _nuevaController,
              obscureText: !_verNueva,
              decoration: decoracionCampo(
                'Nueva contraseña',
                Icons.lock_reset_outlined,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _verNueva
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: colorPrimario,
                  ),
                  onPressed: () =>
                      setState(() => _verNueva = !_verNueva),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Ingresa la nueva contraseña';
                }
                if (v.length < 6) {
                  return 'Mínimo 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _confirmarController,
              obscureText: !_verConfirmar,
              decoration: decoracionCampo(
                'Confirmar nueva contraseña',
                Icons.lock_reset_outlined,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _verConfirmar
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: colorPrimario,
                  ),
                  onPressed: () =>
                      setState(() => _verConfirmar = !_verConfirmar),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Confirma la nueva contraseña';
                }
                if (v != _nuevaController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

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
                    Icon(Icons.error_outline,
                        color: Colors.red[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMensaje!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            botonGuardar(
              cargando: _guardando,
              onPressed: _guardando ? null : _guardar,
              texto: 'Actualizar contraseña',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }
}
