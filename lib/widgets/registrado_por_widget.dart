import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'form_helpers.dart';

class RegistradoPorWidget extends StatelessWidget {
  final String? uid;
  final Color? color;

  const RegistradoPorWidget({super.key, required this.uid, this.color});

  @override
  Widget build(BuildContext context) {
    if (uid == null || uid!.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: FirestoreService().obtenerUsuario(uid!),
      builder: (context, snapshot) {
        final nombre = snapshot.data?['nombre'] as String? ?? 'Desconocido';

        final c = color ?? Colors.grey[600]!;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 12, color: c),
            const SizedBox(width: 4),
            Text(
              snapshot.connectionState == ConnectionState.waiting
                  ? 'Cargando...'
                  : nombre,
              style: TextStyle(
                fontSize: 11,
                color: c,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}
