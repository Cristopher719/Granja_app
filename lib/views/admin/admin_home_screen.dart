import 'package:flutter/material.dart';
import 'dashboard_tab.dart';
import 'galpones_tab.dart';
import 'usuarios_tab.dart';
import 'perfil_tab.dart';
import 'reportes_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _indiceActual = 0;

  final List<Widget> _pestanas = [
    const DashboardAdminTab(),
    const GalponesTab(),
    const ReportesTab(),
    const UsuariosTab(),
    const PerfilTab(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color colorPrimario = Colors.green[700]!;
    final Color colorFondoBarra = Colors.white;

    return Scaffold(
      backgroundColor:
          Colors.grey[100],
      body: IndexedStack(index: _indiceActual, children: _pestanas),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            12,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorFondoBarra,
              borderRadius: BorderRadius.circular(
                24,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    0.08,
                  ),
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
                    indicatorColor:
                        Colors.green[50],
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
                        Icons.dashboard_outlined,
                        color: Colors.grey,
                      ),
                      selectedIcon: Icon(
                        Icons.dashboard_rounded,
                        color: colorPrimario,
                      ),
                      label: 'Inicio',
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined, color: Colors.grey),
                      selectedIcon: Icon(
                        Icons.home_rounded,
                        color: colorPrimario,
                      ),
                      label: 'Galpones',
                    ),
                    NavigationDestination(
                      icon: const Icon(
                        Icons.bar_chart_outlined,
                        color: Colors.grey,
                      ),
                      selectedIcon: Icon(
                        Icons.bar_chart_rounded,
                        color: colorPrimario,
                      ),
                      label: 'Reportes',
                    ),
                    NavigationDestination(
                      icon: const Icon(
                        Icons.people_outline,
                        color: Colors.grey,
                      ),
                      selectedIcon: Icon(
                        Icons.people_alt_rounded,
                        color: colorPrimario,
                      ),
                      label: 'Usuarios',
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
