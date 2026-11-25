import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/form_helpers.dart';
import 'registro_diario_screen.dart';
import 'registro_sanitario_screen.dart';

class MiGalponTab extends StatelessWidget {
  const MiGalponTab({super.key});

  static const _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  static const _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  String _fechaDeHoy() {
    final hoy = DateTime.now();
    return '${_diasSemana[hoy.weekday - 1]}, ${hoy.day} de ${_meses[hoy.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final galponeroId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Mi Galpón',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: FutureBuilder<Map<String, dynamic>?>(
              future: firestoreService.obtenerUsuario(galponeroId),
              builder: (context, snapshot) {
                final nombre = snapshot.data?['nombre'] as String? ?? '';
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre.isNotEmpty ? 'Hola, $nombre 👋' : 'Hola 👋',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fechaDeHoy(),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.obtenerGalponesAsignados(galponeroId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar tu galpón: ${snapshot.error}'),
                  );
                }

                final galpones = snapshot.data?.docs ?? [];

                if (galpones.isEmpty) {
                  return estadoVacio(
                    'Aún no tienes un galpón asignado.\nContacta a tu administrador.',
                    Icons.warehouse_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: galpones.length,
                  itemBuilder: (context, index) {
                    final doc = galpones[index];
                    final datos = doc.data() as Map<String, dynamic>;
                    return _TarjetaGalpon(
                      idGalpon: doc.id,
                      datos: datos,
                      firestoreService: firestoreService,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaGalpon extends StatelessWidget {
  final String idGalpon;
  final Map<String, dynamic> datos;
  final FirestoreService firestoreService;

  const _TarjetaGalpon({
    required this.idGalpon,
    required this.datos,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QueryDocumentSnapshot?>(
      future: firestoreService.obtenerLoteActivo(idGalpon),
      builder: (context, snapshotLote) {
        final loteActivo = snapshotLote.data;
        final idLote = loteActivo?.id;
        final loteData = loteActivo?.data() as Map<String, dynamic>?;
        final cantidadInicial = (loteData?['cantidad_inicial'] as int?) ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorPrimario, const Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warehouse_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        datos['nombre_o_numero'] ?? 'Sin nombre',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${datos['capacidad_maxima'] ?? '-'} aves',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (idLote != null)
                      _ResumenUltimoRegistro(
                        idGalpon: idGalpon,
                        idLote: idLote,
                        firestoreService: firestoreService,
                      )
                    else
                      _sinLoteActivo(),

                    const SizedBox(height: 14),

                    if (idLote != null) ...[
                      AvesVivasContador(
                        idGalpon: idGalpon,
                        idLote: idLote,
                        cantidadInicial: cantidadInicial,
                      ),
                      const SizedBox(height: 14),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: idLote == null
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RegistroDiarioScreen(
                                    idGalpon: idGalpon,
                                    nombreGalpon:
                                        datos['nombre_o_numero'] ?? 'Galpón',
                                  ),
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorPrimario,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: const Text(
                          'Registrar Datos Diarios',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: idLote == null
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RegistroSanitarioScreen(
                                    idGalpon: idGalpon,
                                    nombreGalpon:
                                        datos['nombre_o_numero'] ?? 'Galpón',
                                  ),
                                ),
                              ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: colorPrimario),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          Icons.medical_services_outlined,
                          color: colorPrimario,
                        ),
                        label: Text(
                          'Registrar Evento Sanitario',
                          style: TextStyle(
                            color: colorPrimario,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sinLoteActivo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sin ciclo activo. Contacta al administrador.',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenUltimoRegistro extends StatelessWidget {
  final String idGalpon;
  final String idLote;
  final FirestoreService firestoreService;

  const _ResumenUltimoRegistro({
    required this.idGalpon,
    required this.idLote,
    required this.firestoreService,
  });

  bool _esHoy(DateTime fecha) {
    final hoy = DateTime.now();
    return fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: firestoreService.obtenerUltimoRegistroDiario(
        idGalpon: idGalpon,
        idLote: idLote,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        final registro = snapshot.data;

        if (registro == null) {
          return _badgePendiente('Aún no hay registros en este ciclo');
        }

        final timestamp = registro['fecha'] as Timestamp?;
        final fecha = timestamp?.toDate();
        final yaRegistroHoy = fecha != null && _esHoy(fecha);

        if (yaRegistroHoy) {
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorPrimario.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: colorPrimario,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ya registraste hoy ✓',
                      style: TextStyle(
                        color: colorPrimario,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _miniDato(
                    Icons.egg_rounded,
                    '${registro['huevos_buenos'] ?? 0}',
                    'buenos',
                    colorPrimario,
                  ),
                  _miniDato(
                    Icons.egg_outlined,
                    '${registro['huevos_rotos'] ?? 0}',
                    'rotos',
                    Colors.orange,
                  ),
                  _miniDato(
                    Icons.monitor_heart_outlined,
                    '${registro['mortalidad'] ?? 0}',
                    'muertas',
                    (registro['mortalidad'] ?? 0) > 5
                        ? Colors.red
                        : Colors.grey,
                  ),
                  _miniDato(
                    Icons.grain,
                    '${registro['alimento_kg'] ?? 0} kg',
                    'alimento',
                    Colors.brown,
                  ),
                ],
              ),
            ],
          );
        } else {
          final diasStr = fecha != null
              ? 'Último: ${fecha.day}/${fecha.month}/${fecha.year}'
              : 'Sin registros recientes';
          return _badgePendiente(diasStr);
        }
      },
    );
  }

  Widget _badgePendiente(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.orange[700], size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Pendiente · $texto',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniDato(IconData icono, String valor, String etiqueta, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icono, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
          Text(
            etiqueta,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
