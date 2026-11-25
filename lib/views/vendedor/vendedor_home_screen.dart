import 'package:flutter/material.dart';
import 'nueva_venta_tab.dart';
import 'mis_ventas_tab.dart';
import 'clientes_tab.dart';
import 'perfil_vendedor_tab.dart';

class VendedorHomeScreen extends StatefulWidget {
  const VendedorHomeScreen({super.key});

  @override
  State<VendedorHomeScreen> createState() => _VendedorHomeScreenState();
}

class _VendedorHomeScreenState extends State<VendedorHomeScreen> {
  int _indiceActual = 0;

  final List<Widget> _pestanas = const [
    NuevaVentaTab(),
    MisVentasTab(),
    ClientesTab(),
    PerfilVendedorTab(),
  ];

  @override
  Widget build(BuildContext context) {
    const Color colorVendedor = Colors.orange;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: IndexedStack(index: _indiceActual, children: _pestanas),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Theme(
                data: Theme.of(context).copyWith(
                  navigationBarTheme: NavigationBarThemeData(
                    indicatorColor: colorVendedor.withOpacity(0.12),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorVendedor,
                        );
                      }
                      return TextStyle(fontSize: 12, color: Colors.grey[600]);
                    }),
                  ),
                ),
                child: NavigationBar(
                  height: 68,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  selectedIndex: _indiceActual,
                  onDestinationSelected: (i) =>
                      setState(() => _indiceActual = i),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.add_circle_outline, color: Colors.grey),
                      selectedIcon: Icon(
                        Icons.add_circle_rounded,
                        color: colorVendedor,
                      ),
                      label: 'Nueva Venta',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        Icons.receipt_long_outlined,
                        color: Colors.grey,
                      ),
                      selectedIcon: Icon(
                        Icons.receipt_long_rounded,
                        color: colorVendedor,
                      ),
                      label: 'Mis Ventas',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outline, color: Colors.grey),
                      selectedIcon: Icon(
                        Icons.people_alt_rounded,
                        color: colorVendedor,
                      ),
                      label: 'Clientes',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline, color: Colors.grey),
                      selectedIcon: Icon(
                        Icons.person_rounded,
                        color: colorVendedor,
                      ),
                      label: 'Perfil',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
