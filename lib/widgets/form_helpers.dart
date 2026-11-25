import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color colorPrimario = Color(0xFF388E3C);

Widget manijaModal() {
  return Center(
    child: Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

Widget encabezadoModal(String titulo, IconData icono) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorPrimario.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icono, color: colorPrimario),
      ),
      const SizedBox(width: 12),
      Text(
        titulo,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

InputDecoration decoracionCampo(String label, IconData icono) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icono, color: colorPrimario),
    filled: true,
    fillColor: Colors.grey[50],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: colorPrimario, width: 2),
    ),
  );
}

Widget hojaModal({required BuildContext context, required Widget child}) {
  return Container(
    padding: EdgeInsets.only(
      left: 24,
      right: 24,
      top: 20,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: child,
  );
}

Widget botonGuardar({
  required bool cargando,
  required VoidCallback? onPressed,
  required String texto,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: cargando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
    ),
  );
}

AppBar appBarApp(String titulo) {
  return AppBar(
    title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    elevation: 0,
    scrolledUnderElevation: 0,
  );
}

Widget badgeEstado(String texto, {required Color color, IconData? icono}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icono != null) ...[
          Icon(icono, size: 12, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          texto,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget tarjetaItem({required Widget child, VoidCallback? onTap}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      ),
    ),
  );
}

Widget iconoCirculo(IconData icono, {Color? color}) {
  final c = color ?? colorPrimario;
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icono, color: c),
  );
}

Widget estadoVacio(String mensaje, IconData icono) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    ),
  );
}

Widget tituloSeccion(String titulo, IconData icono) {
  return Row(
    children: [
      Icon(icono, size: 18, color: colorPrimario),
      const SizedBox(width: 8),
      Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ],
  );
}

class AvesVivasContador extends StatelessWidget {
  final String idGalpon;
  final String idLote;
  final int cantidadInicial;

  const AvesVivasContador({
    super.key,
    required this.idGalpon,
    required this.idLote,
    required this.cantidadInicial,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _calcularAvesVivas(),
      builder: (context, snapshot) {
        final vivas = snapshot.data ?? cantidadInicial;
        final porcentaje = cantidadInicial > 0
            ? (vivas / cantidadInicial)
            : 1.0;
        final color = porcentaje >= 0.95
            ? colorPrimario
            : porcentaje >= 0.85
            ? Colors.orange
            : Colors.red;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.hive_outlined, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aves vivas actualmente',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      snapshot.connectionState == ConnectionState.waiting
                          ? 'Calculando...'
                          : '$vivas de $cantidadInicial aves',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: snapshot.hasData ? porcentaje : null,
                      strokeWidth: 4,
                      backgroundColor: color.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  if (snapshot.hasData)
                    Text(
                      '${(porcentaje * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<int> _calcularAvesVivas() async {
    final snap = await FirebaseFirestore.instance
        .collection('galpones')
        .doc(idGalpon)
        .collection('lotes_aves')
        .doc(idLote)
        .collection('registros_diarios')
        .get();

    final totalMortalidad = snap.docs.fold<int>(
      0,
      (suma, doc) => suma + ((doc.data()['mortalidad'] as int?) ?? 0),
    );

    return (cantidadInicial - totalMortalidad).clamp(0, cantidadInicial);
  }
}
