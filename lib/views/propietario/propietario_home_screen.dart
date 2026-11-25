import 'package:flutter/material.dart';
import 'dashboard_tab.dart';
import 'ventas_tab.dart';
import 'perfil_propietario_tab.dart';

class PropietarioHomeScreen extends StatefulWidget {
  const PropietarioHomeScreen({super.key});

  @override
  State<PropietarioHomeScreen> createState() => _PropietarioHomeScreenState();
}

class _PropietarioHomeScreenState extends State<PropietarioHomeScreen> {
  int _indiceActual = 0;

  final List<Widget> _pestanas = const [
    DashboardPropietarioTab(),
    VentasPropietarioTab(),
    PerfilPropietarioTab(),
  ];

  @override
  Widget build(BuildContext context) {
    const Color colorPropietario = Color(0xFF1565C0);

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
                    indicatorColor: colorPropietario.withOpacity(0.12),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorPropietario,
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
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(
                        Icons.dashboard_outlined,
                        color: Colors.grey,
                      ),
                      selectedIcon: Icon(
                        Icons.dashboard_rounded,
                        color: colorPropietario,
                      ),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: const Icon(
                        Icons.point_of_sale_outlined,
                        color: Colors.grey,
                      ),
                      selectedIcon: Icon(
                        Icons.point_of_sale_rounded,
                        color: colorPropietario,
                      ),
                      label: 'Ventas',
                    ),
                    NavigationDestination(
                      icon: const Icon(
                        Icons.person_outline,
                        color: Colors.grey,
                      ),
                      selectedIcon: Icon(
                        Icons.person_rounded,
                        color: colorPropietario,
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
