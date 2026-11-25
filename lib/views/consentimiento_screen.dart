import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/form_helpers.dart';

class ConsentimientoScreen extends StatefulWidget {
  final VoidCallback onAceptado;
  const ConsentimientoScreen({super.key, required this.onAceptado});

  @override
  State<ConsentimientoScreen> createState() => _ConsentimientoScreenState();
}

class _ConsentimientoScreenState extends State<ConsentimientoScreen> {
  bool _acepta = false;
  bool _guardando = false;
  String? _error;

  static const _secciones = [
    (
      'Finalidad',
      'Tus datos se usarán únicamente para operar la aplicación de gestión de la granja '
          '(registros de producción, sanidad, inventario y ventas) y para evaluar su funcionamiento '
          'dentro del trabajo de grado de las Unidades Tecnológicas de Santander.',
    ),
    (
      'Datos que se recolectan',
      'De ti: nombre completo, correo electrónico y rol en la granja. De la operación: producción, '
          'consumo de alimento y agua, mortalidad, eventos sanitarios (con fotografías de comprobantes), '
          'clasificación de huevos, inventario y ventas. No se recolectan documentos de identidad, '
          'datos financieros personales ni datos sensibles.',
    ),
    (
      'Almacenamiento y seguridad',
      'La información se guarda en Google Firebase (Cloud Firestore y Cloud Storage), cifrada en '
          'tránsito y en reposo. Cada rol solo accede a la información que le corresponde y cada registro '
          'guarda quién lo creó y cuándo.',
    ),
    (
      'Conservación',
      'Los datos se conservarán durante la ejecución del proyecto; al finalizar, se entregarán al '
          'propietario de la granja o se eliminarán según su decisión. Los resultados que se publiquen '
          'no identificarán a las granjas ni a los participantes.',
    ),
    (
      'Tus derechos',
      'Puedes conocer, actualizar, rectificar y solicitar la supresión de tus datos, así como revocar '
          'esta autorización, comunicándote con el administrador de la granja o con los autores del proyecto.',
    ),
  ];

  Future<void> _aceptar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirestoreService().registrarConsentimiento(uid);
      widget.onAceptado();
    } catch (e) {
      setState(() => _error = 'No se pudo guardar tu aceptación: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _rechazar() async {
    await AuthService().cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Tratamiento de datos personales',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Antes de usar la aplicación, lee cómo se tratarán tus datos, conforme a la '
                    'Ley 1581 de 2012 y el Decreto 1377 de 2013 (compilado en el Decreto 1074 de 2015).',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  ..._secciones.map(
                    (s) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.$1,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(s.$2, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckboxListTile(
                    value: _acepta,
                    onChanged: (v) => setState(() => _acepta = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: colorPrimario,
                    title: const Text(
                      'He leído la información y autorizo de manera previa, expresa e informada el tratamiento de mis datos.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  botonGuardar(
                    cargando: _guardando,
                    onPressed: (_acepta && !_guardando) ? _aceptar : null,
                    texto: 'Aceptar y continuar',
                  ),
                  TextButton(
                    onPressed: _guardando ? null : _rechazar,
                    child: const Text('No acepto (cerrar sesión)'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
