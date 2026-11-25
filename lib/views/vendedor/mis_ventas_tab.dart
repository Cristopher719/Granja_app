import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';

class MisVentasTab extends StatelessWidget {
  const MisVentasTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vendedorId = FirebaseAuth.instance.currentUser!.uid;
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarApp('Mis Ventas'),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.obtenerVentasDeVendedor(vendedorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final ventas = snapshot.data?.docs ?? [];

          if (ventas.isEmpty) {
            return estadoVacio(
              'Aún no has registrado ventas.',
              Icons.point_of_sale_outlined,
            );
          }

          final totalIngresos = ventas.fold<double>(
            0,
            (s, d) =>
                s +
                (((d.data() as Map<String, dynamic>)['total'] as num?)
                        ?.toDouble() ??
                    0),
          );

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Color(0xFFE65100)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _dato(
                        '\$${totalIngresos.toStringAsFixed(0)}',
                        'Total ingresos',
                        Icons.attach_money_rounded,
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white24),
                    Expanded(
                      child: _dato(
                        '${ventas.length}',
                        'Ventas realizadas',
                        Icons.receipt_outlined,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: ventas.length,
                  itemBuilder: (context, index) {
                    final datos = ventas[index].data() as Map<String, dynamic>;
                    final fecha = (datos['fecha'] as Timestamp?)?.toDate();
                    final fechaStr = fecha != null
                        ? '${fecha.day}/${fecha.month}/${fecha.year} '
                              '${fecha.hour.toString().padLeft(2, '0')}:'
                              '${fecha.minute.toString().padLeft(2, '0')}'
                        : '-';
                    final total = (datos['total'] as num?)?.toDouble() ?? 0;
                    final tipo = datos['tipo_huevo'] as String? ?? '-';
                    final coloresTipo = {
                      'A': Colors.amber,
                      'B': Colors.orange,
                      'C': Colors.brown,
                    };
                    final color = coloresTipo[tipo] ?? Colors.orange;

                    return tarjetaItem(
                      onTap: () => _mostrarDetalle(context, datos, fechaStr),
                      child: Row(
                        children: [
                          iconoCirculo(
                            Icons.point_of_sale_rounded,
                            color: color,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  datos['cliente'] ?? 'Sin cliente',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  fechaStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    badgeEstado(
                                      'Tipo $tipo',
                                      color: color,
                                      icono: Icons.egg_rounded,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${datos['cantidad_unidades'] ?? 0} uds',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dato(String valor, String etiqueta, IconData icono) {
    return Column(
      children: [
        Icon(icono, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          etiqueta,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _mostrarDetalle(
    BuildContext context,
    Map<String, dynamic> datos,
    String fecha,
  ) {
    final total = (datos['total'] as num?)?.toDouble() ?? 0;
    final dosis = datos['dosis'] as Map<String, dynamic>?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => hojaModal(
        context: context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            manijaModal(),
            encabezadoModal('Detalle de venta', Icons.receipt_long_outlined),
            const SizedBox(height: 20),
            _fila('Cliente', datos['cliente'] ?? '-', Colors.orange),
            if ((datos['cliente_cedula'] ?? '').toString().isNotEmpty)
              _fila('Cédula / NIT', datos['cliente_cedula'], Colors.orange),
            if ((datos['cliente_telefono'] ?? '').toString().isNotEmpty)
              _fila('Teléfono', datos['cliente_telefono'], Colors.orange),
            _fila(
              'Tipo huevo',
              'Tipo ${datos['tipo_huevo'] ?? '-'}',
              Colors.orange,
            ),
            _fila(
              'Cantidad',
              '${datos['cantidad_unidades'] ?? 0} unidades',
              Colors.orange,
            ),
            _fila(
              'Precio/ud',
              '\$${(datos['precio_unidad'] as num?)?.toStringAsFixed(2) ?? '-'}',
              Colors.orange,
            ),
            _fila('Total', '\$${total.toStringAsFixed(2)}', Colors.orange),
            _fila('Fecha', fecha, Colors.grey),
            if ((datos['notas'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Notas',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(datos['notas'] as String),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _fila(String etiqueta, String valor, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(etiqueta, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(
            valor,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
