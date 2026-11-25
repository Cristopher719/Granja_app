import 'package:flutter/material.dart';
import 'mi_galpon_tab.dart';
import 'historial_tab.dart';
import 'perfil_tab.dart';

class GalponeroHomeScreen extends StatefulWidget {
  const GalponeroHomeScreen({super.key});

  @override
  State<GalponeroHomeScreen> createState() => _GalponeroHomeScreenState();
}

class _GalponeroHomeScreenState extends State<GalponeroHomeScreen> {
  int _indiceActual = 0;

  final List<Widget> _pestanas = const [
    MiGalponTab(),
    HistorialTab(),
    PerfilTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final Color colorPrimario = const Color(0xFF388E3C);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
                    indicatorColor: const Color(0xFFE8F5E9),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorPrimario,
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
                  onDestinationSelected: (indice) {
                    setState(() => _indiceActual = indice);
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(
                        Icons.warehouse_outlined,
                        color: Colors.grey,
                      ),
                      selectedIcon: Icon(
                        Icons.warehouse_rounded,
                        color: colorPrimario,
                      ),
                      label: 'Mi Galpón',
                    ),
                    NavigationDestination(
                      icon: const Icon(
                        Icons.history_outlined,
                        color: Colors.grey,
                      ),
                      selectedIcon: Icon(
                        Icons.history_rounded,
                        color: colorPrimario,
                      ),
                      label: 'Historial',
                    ),
                    NavigationDestination(
                      icon: const Icon(
                        Icons.person_outline,
                        color: Colors.grey,
                      ),
                      selectedIcon: Icon(
                        Icons.person_rounded,
                        color: colorPrimario,
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
