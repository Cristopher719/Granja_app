import 'package:flutter/material.dart';
import 'stock_tab.dart';
import 'clasificacion_huevos_tab.dart';
import 'stock_alimento_tab.dart';
import 'perfil_bodeguero_tab.dart';

class BodegueroHomeScreen extends StatefulWidget {
  const BodegueroHomeScreen({super.key});

  @override
  State<BodegueroHomeScreen> createState() => _BodegueroHomeScreenState();
}

class _BodegueroHomeScreenState extends State<BodegueroHomeScreen> {
  int _indiceActual = 0;

  final List<Widget> _pestanas = const [
    StockTab(),
    ClasificacionHuevosTab(),
    StockAlimentoTab(),
    PerfilBodegueroTab(),
  ];

  @override
  Widget build(BuildContext context) {
    const Color colorBodeguero = Colors.brown;

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
                    indicatorColor: colorBodeguero.withOpacity(0.12),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorBodeguero,
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
                      icon: Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.grey,
                      ),
                      selectedIcon: Icon(
                        Icons.inventory_2_rounded,
                        color: colorBodeguero,
                      ),
                      label: 'Stock',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.egg_outlined, color: Colors.grey),
                      selectedIcon: Icon(
                        Icons.egg_rounded,
                        color: colorBodeguero,
                      ),
                      label: 'Clasificar',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.add_box_outlined, color: Colors.grey),
                      selectedIcon: Icon(
                        Icons.add_box_rounded,
                        color: colorBodeguero,
                      ),
                      label: 'Alimento',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline, color: Colors.grey),
                      selectedIcon: Icon(
                        Icons.person_rounded,
                        color: colorBodeguero,
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
