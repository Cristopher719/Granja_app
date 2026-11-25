import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'metricas_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _escribir(String operacion, Future<void> escritura) async {
    final reloj = Stopwatch()..start();
    var enLinea = true;
    await escritura.timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        enLinea = false;
        escritura.catchError((e) => debugPrint('Escritura pendiente: $e'));
      },
    );
    reloj.stop();
    if (enLinea) {
      MetricasService().registrarDesempeno(
        operacion,
        reloj.elapsedMilliseconds,
      );
    }
  }

  Future<void> registrarConsentimiento(String uid) async {
    await _db.collection('usuarios').doc(uid).update({
      'consentimiento_aceptado': true,
      'fecha_consentimiento': FieldValue.serverTimestamp(),
      'version_politica': versionPoliticaDatos,
    });
  }

  static const String versionPoliticaDatos = '1.0';

  Future<void> crearUsuario({
    required String uid,
    required String nombre,
    required String correo,
    required String rol,
    String? creadoPor,
  }) async {
    await _db.collection('usuarios').doc(uid).set({
      'uid': uid,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'creado_por': creadoPor,
      'creado_en': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> obtenerUsuario(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    return doc.data();
  }

  Stream<QuerySnapshot> obtenerTodosLosUsuarios(String creadoPor) {
    return _db
        .collection('usuarios')
        .where('creado_por', isEqualTo: creadoPor)
        .snapshots();
  }

  Stream<QuerySnapshot> obtenerGalponeros(String creadoPor) {
    return _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'galponero')
        .where('creado_por', isEqualTo: creadoPor)
        .snapshots();
  }

  Future<String> crearGalpon({
    required String nombreONumero,
    required int capacidadMaxima,
    required String administradorId,
    String? galponeroId,
  }) async {
    final ref = await _db.collection('galpones').add({
      'nombre_o_numero': nombreONumero,
      'capacidad_maxima': capacidadMaxima,
      'fecha_creacion': FieldValue.serverTimestamp(),
      'administrador_id': administradorId,
      'galponero_id': galponeroId,
    });
    return ref.id;
  }

  Stream<QuerySnapshot> obtenerGalpones(String administradorId) {
    return _db
        .collection('galpones')
        .where('administrador_id', isEqualTo: administradorId)
        .snapshots();
  }

  Future<void> asignarGalponeroAGalpon({
    required String idGalpon,
    required String? galponeroId,
  }) async {
    await _db.collection('galpones').doc(idGalpon).update({
      'galponero_id': galponeroId,
    });
  }

  Stream<QuerySnapshot> obtenerGalponesAsignados(String galponeroId) {
    return _db
        .collection('galpones')
        .where('galponero_id', isEqualTo: galponeroId)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialDiario({
    required String idGalpon,
    required String idLote,
    int limite = 30,
  }) async {
    final snap = await _db
        .collection('galpones')
        .doc(idGalpon)
        .collection('lotes_aves')
        .doc(idLote)
        .collection('registros_diarios')
        .orderBy('fecha', descending: true)
        .limit(limite)
        .get();

    return snap.docs
        .map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id})
        .toList();
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialSanitario({
    required String idGalpon,
    required String idLote,
    int limite = 30,
  }) async {
    final snap = await _db
        .collection('galpones')
        .doc(idGalpon)
        .collection('lotes_aves')
        .doc(idLote)
        .collection('registros_sanitarios')
        .orderBy('fecha', descending: true)
        .limit(limite)
        .get();

    return snap.docs
        .map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id})
        .toList();
  }

  Future<Map<String, dynamic>?> obtenerUltimoRegistroDiario({
    required String idGalpon,
    required String idLote,
  }) async {
    final snap = await _db
        .collection('galpones')
        .doc(idGalpon)
        .collection('lotes_aves')
        .doc(idLote)
        .collection('registros_diarios')
        .orderBy('fecha', descending: true)
        .limit(1)
        .get();

    return snap.docs.isEmpty ? null : snap.docs.first.data();
  }

  Future<int> calcularAvesVivas({
    required String idGalpon,
    required String idLote,
    required int cantidadInicial,
  }) async {
    final snap = await _db
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

  Future<String> crearLote({
    required String idGalpon,
    required int cantidadInicial,
    required String raza,
    required int edadSemanas,
  }) async {
    final loteActivo = await _db
        .collection('galpones')
        .doc(idGalpon)
        .collection('lotes_aves')
        .where('estado', isEqualTo: 'activo')
        .limit(1)
        .get();

    if (loteActivo.docs.isNotEmpty) {
      throw Exception(
        'Este galpón ya tiene un lote activo. '
        'Finalízalo antes de crear uno nuevo.',
      );
    }

    final galpon = await _db.collection('galpones').doc(idGalpon).get();
    final capacidad = galpon.data()?['capacidad_maxima'] as int? ?? 0;
    if (cantidadInicial > capacidad) {
      throw Exception(
        'La cantidad ($cantidadInicial) supera la capacidad '
        'máxima del galpón ($capacidad aves).',
      );
    }

    final ref = await _db
        .collection('galpones')
        .doc(idGalpon)
        .collection('lotes_aves')
        .add({
          'cantidad_inicial': cantidadInicial,
          'raza': raza,
          'fecha_ingreso': FieldValue.serverTimestamp(),
          'edad_semanas': edadSemanas,
          'estado': 'activo',
        });
    return ref.id;
  }

  Stream<QuerySnapshot> obtenerLotes(String idGalpon) {
    return _db
        .collection('galpones')
        .doc(idGalpon)
        .collection('lotes_aves')
        .snapshots();
  }

  Future<void> finalizarLote({
    required String idGalpon,
    required String idLote,
  }) async {
    await _db
        .collection('galpones')
        .doc(idGalpon)
        .collection('lotes_aves')
        .doc(idLote)
        .update({
          'estado': 'finalizado',
          'fecha_fin': FieldValue.serverTimestamp(),
        });
  }

  Future<QueryDocumentSnapshot?> obtenerLoteActivo(String idGalpon) async {
    final resultado = await _db
        .collection('galpones')
        .doc(idGalpon)
        .collection('lotes_aves')
        .where('estado', isEqualTo: 'activo')
        .limit(1)
        .get();

    return resultado.docs.firstOrNull;
  }

  Future<bool> verificarRegistroHoy({
    required String idGalpon,
    required String idLote,
  }) async {
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);

    final snap = await _db
        .collection('galpones')
        .doc(idGalpon)
        .collection('lotes_aves')
        .doc(idLote)
        .collection('registros_diarios')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(finDia))
        .where('es_correccion', isEqualTo: false)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  Future<void> registrarDatoDiario({
    required String idGalpon,
    required String idLote,
    required int huevosBuenos,
    required Map<String, int> huevosPorTipo,
    required int huevosRotos,
    required double alimentoKg,
    required double aguaLitros,
    required int mortalidad,
    required String registradoPor,
    String novedades = '',
    bool esCorreccion = false,
    String motivoCorreccion = '',
  }) async {
    await _escribir(
      'registro_diario',
      _db
          .collection('galpones')
          .doc(idGalpon)
          .collection('lotes_aves')
          .doc(idLote)
          .collection('registros_diarios')
          .doc()
          .set({
            'fecha': FieldValue.serverTimestamp(),
            'huevos_buenos': huevosBuenos,
            'huevos_por_tipo': huevosPorTipo,
            'huevos_rotos': huevosRotos,
            'alimento_kg': alimentoKg,
            'agua_litros': aguaLitros,
            'mortalidad': mortalidad,
            'novedades': novedades,
            'registrado_por': registradoPor,
            'es_correccion': esCorreccion,
            'motivo_correccion': motivoCorreccion,
          }),
    );
  }

  Stream<QuerySnapshot> obtenerRegistrosDiarios(
    String idGalpon,
    String idLote,
  ) {
    return _db
        .collection('galpones')
        .doc(idGalpon)
        .collection('lotes_aves')
        .doc(idLote)
        .collection('registros_diarios')
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> obtenerGalpon(String idGalpon) async {
    final doc = await _db.collection('galpones').doc(idGalpon).get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> obtenerRegistrosDeGalpon({
    required String idGalpon,
    required int dias,
  }) async {
    final desde = Timestamp.fromDate(
      DateTime.now().subtract(Duration(days: dias)),
    );

    final lotesSnap = await _db
        .collection('galpones')
        .doc(idGalpon)
        .collection('lotes_aves')
        .get();

    final registros = <Map<String, dynamic>>[];

    for (final lote in lotesSnap.docs) {
      final regSnap = await _db
          .collection('galpones')
          .doc(idGalpon)
          .collection('lotes_aves')
          .doc(lote.id)
          .collection('registros_diarios')
          .where('fecha', isGreaterThanOrEqualTo: desde)
          .orderBy('fecha', descending: false)
          .get();

      for (final reg in regSnap.docs) {
        registros.add({...reg.data(), 'id_lote': lote.id});
      }
    }

    return registros;
  }

  Future<List<Map<String, dynamic>>> obtenerRegistrosConsolidados({
    required String adminId,
    int? dias,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    List<String>? galponIds,
  }) async {
    final desde =
        fechaDesde ?? DateTime.now().subtract(Duration(days: dias ?? 30));
    final hasta = fechaHasta ?? DateTime.now();
    final desdeTs = Timestamp.fromDate(
      DateTime(desde.year, desde.month, desde.day),
    );
    final hastaTs = Timestamp.fromDate(
      DateTime(hasta.year, hasta.month, hasta.day, 23, 59, 59),
    );

    final galponesSnap = await _db
        .collection('galpones')
        .where('administrador_id', isEqualTo: adminId)
        .get();

    final galponesFiltrados = (galponIds == null || galponIds.isEmpty)
        ? galponesSnap.docs
        : galponesSnap.docs.where((d) => galponIds.contains(d.id)).toList();

    final registros = <Map<String, dynamic>>[];

    for (final galpon in galponesFiltrados) {
      final lotesSnap = await _db
          .collection('galpones')
          .doc(galpon.id)
          .collection('lotes_aves')
          .get();

      for (final lote in lotesSnap.docs) {
        final regSnap = await _db
            .collection('galpones')
            .doc(galpon.id)
            .collection('lotes_aves')
            .doc(lote.id)
            .collection('registros_diarios')
            .where('fecha', isGreaterThanOrEqualTo: desdeTs)
            .where('fecha', isLessThanOrEqualTo: hastaTs)
            .orderBy('fecha', descending: false)
            .get();

        for (final reg in regSnap.docs) {
          final datos = reg.data();
          registros.add({
            ...datos,
            'id_galpon': galpon.id,
            'nombre_galpon': galpon.data()['nombre_o_numero'] ?? '',
            'id_lote': lote.id,
          });
        }
      }
    }

    return registrosEfectivos(registros);
  }

  Future<void> registrarEventoSanitario({
    required String idGalpon,
    required String idLote,
    required String tipoEvento,
    required String productoAplicado,
    required Map<String, dynamic> dosis,
    required String fotoUrl,
    required String registradoPor,
  }) async {
    await _escribir(
      'registro_sanitario',
      _db
          .collection('galpones')
          .doc(idGalpon)
          .collection('lotes_aves')
          .doc(idLote)
          .collection('registros_sanitarios')
          .doc()
          .set({
            'fecha': FieldValue.serverTimestamp(),
            'tipo_evento': tipoEvento,
            'producto_aplicado': productoAplicado,
            'dosis': dosis,
            'foto_url': fotoUrl,
            'registrado_por': registradoPor,
          }),
    );
  }

  Stream<QuerySnapshot> obtenerRegistrosSanitarios(
    String idGalpon,
    String idLote,
  ) {
    return _db
        .collection('galpones')
        .doc(idGalpon)
        .collection('lotes_aves')
        .doc(idLote)
        .collection('registros_sanitarios')
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  Future<void> registrarVenta({
    required String vendedorId,
    required String adminId,
    String idGalpon = '',
    required String tipoHuevo,
    required int cantidadUnidades,
    required double precioUnidad,
    required String cliente,
    String clienteCedula = '',
    String clienteTelefono = '',
    String? clienteId,
    String notas = '',
  }) async {
    final total = cantidadUnidades * precioUnidad;
    await _escribir(
      'registro_venta',
      _db.collection('ventas').doc().set({
        'cliente_cedula': clienteCedula,
        'cliente_telefono': clienteTelefono,
        if (clienteId != null) 'cliente_id': clienteId,
        'vendedor_id': vendedorId,
        'admin_id': adminId,
        'id_galpon': idGalpon,
        'tipo_huevo': tipoHuevo,
        'cantidad_unidades': cantidadUnidades,
        'precio_unidad': precioUnidad,
        'total': total,
        'cliente': cliente,
        'notas': notas,
        'fecha': FieldValue.serverTimestamp(),
      }),
    );
  }

  Stream<QuerySnapshot> obtenerClientes(String adminId) {
    return _db
        .collection('clientes')
        .where('admin_id', isEqualTo: adminId)
        .snapshots();
  }

  Future<String> guardarCliente({
    String? id,
    required String adminId,
    required String usuarioId,
    required String nombre,
    required String cedula,
    required String telefono,
  }) async {
    var ref = id != null ? _db.collection('clientes').doc(id) : null;
    if (ref == null) {
      final existente = await _db
          .collection('clientes')
          .where('admin_id', isEqualTo: adminId)
          .where('cedula', isEqualTo: cedula)
          .limit(1)
          .get();
      if (existente.docs.isNotEmpty) ref = existente.docs.first.reference;
    }
    final datos = {
      'nombre': nombre,
      'cedula': cedula,
      'telefono': telefono,
      'admin_id': adminId,
      'actualizado_en': FieldValue.serverTimestamp(),
    };
    if (ref == null) {
      ref = _db.collection('clientes').doc();
      await _escribir(
        'cliente',
        ref.set({
          ...datos,
          'creado_por': usuarioId,
          'fecha_creacion': FieldValue.serverTimestamp(),
        }),
      );
    } else {
      await _escribir('cliente', ref.update(datos));
    }
    return ref.id;
  }

  Future<void> eliminarCliente(String id) async {
    await _escribir('cliente', _db.collection('clientes').doc(id).delete());
  }

  Future<List<Map<String, dynamic>>> _ventasDelAdmin(String adminId) async {
    final porId = <String, Map<String, dynamic>>{};
    void agregar(QuerySnapshot snap) {
      for (final d in snap.docs) {
        porId[d.id] = {...(d.data() as Map<String, dynamic>), 'id': d.id};
      }
    }

    agregar(
      await _db
          .collection('ventas')
          .where('admin_id', isEqualTo: adminId)
          .get(),
    );

    final galpones = await _db
        .collection('galpones')
        .where('administrador_id', isEqualTo: adminId)
        .get();
    final galponIds = galpones.docs.map((d) => d.id).toList();
    for (var i = 0; i < galponIds.length; i += 30) {
      final bloque = galponIds.sublist(
        i,
        i + 30 > galponIds.length ? galponIds.length : i + 30,
      );
      agregar(
        await _db
            .collection('ventas')
            .where('id_galpon', whereIn: bloque)
            .get(),
      );
    }

    try {
      final vendedores = await _db
          .collection('usuarios')
          .where('creado_por', isEqualTo: adminId)
          .where('rol', isEqualTo: 'vendedor')
          .get();
      final ids = [adminId, ...vendedores.docs.map((d) => d.id)];
      for (var i = 0; i < ids.length; i += 30) {
        final bloque = ids.sublist(
          i,
          i + 30 > ids.length ? ids.length : i + 30,
        );
        final snap = await _db
            .collection('ventas')
            .where('vendedor_id', whereIn: bloque)
            .get();
        for (final d in snap.docs) {
          final datos = d.data();
          if (datos['admin_id'] == null) {
            porId[d.id] = {...datos, 'id': d.id};
          }
        }
      }
    } catch (_) {
    }

    return porId.values.toList();
  }

  Stream<QuerySnapshot> obtenerVentasDeVendedor(String vendedorId) {
    return _db
        .collection('ventas')
        .where('vendedor_id', isEqualTo: vendedorId)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> obtenerVentasConsolidadas({
    required String adminId,
    int? dias,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    List<String>? galponIds,
  }) async {
    final d = fechaDesde ?? DateTime.now().subtract(Duration(days: dias ?? 30));
    final h = fechaHasta ?? DateTime.now();
    final desde = DateTime(d.year, d.month, d.day);
    final hasta = DateTime(h.year, h.month, h.day, 23, 59, 59);

    final todas = await _ventasDelAdmin(adminId);
    final ventas = todas.where((v) {
      final f = (v['fecha'] as Timestamp?)?.toDate();
      if (f == null || f.isBefore(desde) || f.isAfter(hasta)) return false;
      final g = (v['id_galpon'] as String?) ?? '';
      if (g.isNotEmpty && galponIds != null && galponIds.isNotEmpty) {
        return galponIds.contains(g);
      }
      return true;
    }).toList();

    ventas.sort((a, b) {
      final fa = (a['fecha'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final fb = (b['fecha'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return fa.compareTo(fb);
    });
    return ventas;
  }

  Future<void> registrarEntradaAlimento({
    required String bodegueroId,
    required String idGalpon,
    required double cantidadKg,
    required double precioKg,
    required String proveedor,
    String notas = '',
    String tipo = 'entrada',
  }) async {
    await _escribir(
      'entrada_alimento',
      _db.collection('inventario_alimento').doc().set({
        'tipo': tipo,
        'bodeguero_id': bodegueroId,
        'id_galpon': idGalpon,
        'cantidad_kg': cantidadKg,
        'precio_kg': precioKg,
        'total': cantidadKg * precioKg,
        'proveedor': proveedor,
        'notas': notas,
        'fecha': FieldValue.serverTimestamp(),
      }),
    );
  }

  static List<Map<String, dynamic>> registrosEfectivos(
    List<Map<String, dynamic>> registros,
  ) {
    String clave(Map<String, dynamic> r) {
      final f = (r['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();
      return '${r['id_lote'] ?? ''}|${f.year}-${f.month}-${f.day}';
    }

    final correcciones = <String, Map<String, dynamic>>{};
    for (final r in registros) {
      if (r['es_correccion'] == true) {
        final k = clave(r);
        final previa = correcciones[k];
        final fr = (r['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();
        final fp = (previa?['fecha'] as Timestamp?)?.toDate();
        if (previa == null || (fp != null && fr.isAfter(fp)))
          correcciones[k] = r;
      }
    }
    return [
      ...registros.where(
        (r) =>
            r['es_correccion'] != true && !correcciones.containsKey(clave(r)),
      ),
      ...correcciones.values,
    ];
  }

  Future<Map<String, double>> obtenerResumenAlimento(String idGalpon) async {
    final ahora = DateTime.now();
    DateTime fechaDe(dynamic t) =>
        (t as Timestamp?)?.toDate() ?? ahora;

    final movimientos = await _db
        .collection('inventario_alimento')
        .where('id_galpon', isEqualTo: idGalpon)
        .get();

    Map<String, dynamic>? ultimoConteo;
    for (final d in movimientos.docs) {
      final m = d.data();
      if (m['tipo'] != 'conteo') continue;
      if (ultimoConteo == null ||
          fechaDe(m['fecha']).isAfter(fechaDe(ultimoConteo['fecha']))) {
        ultimoConteo = m;
      }
    }
    final corte = ultimoConteo == null ? null : fechaDe(ultimoConteo['fecha']);
    final base = (ultimoConteo?['cantidad_kg'] as num?)?.toDouble() ?? 0;

    double entradas = 0;
    for (final d in movimientos.docs) {
      final m = d.data();
      if (m['tipo'] != 'entrada') continue;
      if (corte == null || fechaDe(m['fecha']).isAfter(corte)) {
        entradas += (m['cantidad_kg'] as num?)?.toDouble() ?? 0;
      }
    }

    final lotes = await _db
        .collection('galpones')
        .doc(idGalpon)
        .collection('lotes_aves')
        .get();
    final registros = <Map<String, dynamic>>[];
    for (final lote in lotes.docs) {
      final snap = await lote.reference.collection('registros_diarios').get();
      for (final r in snap.docs) {
        registros.add({...r.data(), 'id_lote': lote.id});
      }
    }
    final hace7Dias = ahora.subtract(const Duration(days: 7));
    double consumo = 0, consumo7Dias = 0;
    for (final r in registrosEfectivos(registros)) {
      final kg = (r['alimento_kg'] as num?)?.toDouble() ?? 0;
      final f = fechaDe(r['fecha']);
      if (corte == null || f.isAfter(corte)) consumo += kg;
      if (f.isAfter(hace7Dias)) consumo7Dias += kg;
    }

    final disponibleTotal = base + entradas;
    final saldo = disponibleTotal - consumo;
    final stock = saldo < 0 ? 0.0 : saldo;
    final promedioDiario = consumo7Dias / 7;

    return {
      'stock': stock,
      'entradas': disponibleTotal,
      'consumo_total': consumo,
      'faltante': saldo < 0 ? -saldo : 0,
      'promedio_diario': promedioDiario,
      'dias_estimados': promedioDiario > 0 ? stock / promedioDiario : -1.0,
      'ultimo_conteo_ms': corte?.millisecondsSinceEpoch.toDouble() ?? -1,
    };
  }

  Future<double> calcularStockAlimento(String idGalpon) async =>
      (await obtenerResumenAlimento(idGalpon))['stock']!;

  Stream<QuerySnapshot> obtenerMovimientosInventario(String idGalpon) {
    return _db
        .collection('inventario_alimento')
        .where('id_galpon', isEqualTo: idGalpon)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> obtenerInventarioConsolidado() async {
    final snap = await _db
        .collection('inventario_alimento')
        .orderBy('fecha', descending: true)
        .get();

    return snap.docs
        .map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id})
        .toList();
  }

  Future<void> registrarClasificacionHuevos({
    required String bodegueroId,
    required String idGalpon,
    required Map<String, int> clasificacion,
    required int total,
  }) async {
    await _escribir(
      'clasificacion_huevos',
      _db.collection('clasificacion_huevos').doc().set({
        'bodeguero_id': bodegueroId,
        'id_galpon': idGalpon,
        'clasificacion': clasificacion,
        'total': total,
        'fecha': FieldValue.serverTimestamp(),
      }),
    );
  }

  Future<Map<String, int>> calcularStockHuevosPorTipo({
    required String adminId,
  }) async {
    final tipos = ['B', 'A', 'AA', 'AAA'];
    final stock = {for (final t in tipos) t: 0};

    final galponesSnap = await _db
        .collection('galpones')
        .where('administrador_id', isEqualTo: adminId)
        .get();

    final galponIds = galponesSnap.docs.map((d) => d.id).toList();
    if (galponIds.isEmpty) return stock;

    for (var i = 0; i < galponIds.length; i += 30) {
      final bloque = galponIds.sublist(
        i,
        i + 30 > galponIds.length ? galponIds.length : i + 30,
      );
      final clasifSnap = await _db
          .collection('clasificacion_huevos')
          .where('id_galpon', whereIn: bloque)
          .get();
      for (final doc in clasifSnap.docs) {
        final clasif = doc.data()['clasificacion'] as Map<String, dynamic>?;
        if (clasif == null) continue;
        for (final tipo in tipos) {
          stock[tipo] = stock[tipo]! + ((clasif[tipo] as num?)?.toInt() ?? 0);
        }
      }
    }

    for (final v in await _ventasDelAdmin(adminId)) {
      final tipo = v['tipo_huevo'] as String?;
      final cantidad = (v['cantidad_unidades'] as num?)?.toInt() ?? 0;
      if (tipo != null && stock.containsKey(tipo)) {
        stock[tipo] = stock[tipo]! - cantidad;
      }
    }

    for (final tipo in tipos) {
      if (stock[tipo]! < 0) stock[tipo] = 0;
    }
    return stock;
  }

  Future<String> cargarDatosDemo({required String adminId}) async {
    final galpones = [
      {
        'nombre_o_numero': 'Galpón A',
        'capacidad_maxima': 5000,
        'raza': 'Hy-Line Brown',
        'cantidad_inicial': 4800,
        'edad_semanas': 32,
      },
      {
        'nombre_o_numero': 'Galpón B',
        'capacidad_maxima': 3000,
        'raza': 'Lohmann Brown',
        'cantidad_inicial': 2900,
        'edad_semanas': 48,
      },
    ];

    final batchFase1 = _db.batch();
    final batchLotes = _db.batch();
    final galponRefs = <Map<String, dynamic>>[];

    for (final g in galpones) {
      final galponRef = _db.collection('galpones').doc();
      batchFase1.set(galponRef, {
        'nombre_o_numero': g['nombre_o_numero'],
        'capacidad_maxima': g['capacidad_maxima'],
        'administrador_id': adminId,
        'galponero_id': null,
        'fecha_creacion': FieldValue.serverTimestamp(),
        'es_demo': true,
      });

      final loteRef = galponRef.collection('lotes_aves').doc();
      batchLotes.set(loteRef, {
        'raza': g['raza'],
        'cantidad_inicial': g['cantidad_inicial'],
        'edad_semanas': g['edad_semanas'],
        'fecha_ingreso': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 90)),
        ),
        'estado': 'activo',
        'es_demo': true,
      });

      galponRefs.add({'galponRef': galponRef, 'loteRef': loteRef, 'datos': g});
    }

    await batchFase1.commit();
    await batchLotes.commit();

    var batch = _db.batch();
    var operacionesEnBatch = 0;
    int totalRegistros = 0;

    Future<void> flushSiHaceFalta() async {
      if (operacionesEnBatch >= 400) {
        await batch.commit();
        batch = _db.batch();
        operacionesEnBatch = 0;
      }
    }

    for (final item in galponRefs) {
      final galponRef = item['galponRef'];
      final loteRef = item['loteRef'];
      final g = item['datos'] as Map<String, dynamic>;
      final capacidad = g['cantidad_inicial'] as int;

      for (int dia = 13; dia >= 0; dia--) {
        final fecha = DateTime.now().subtract(Duration(days: dia));
        final huevos =
            (capacidad * 0.82 +
                    (dia % 3 == 0
                        ? -80
                        : dia % 2 == 0
                        ? 50
                        : 0))
                .toInt();

        final regRef = loteRef.collection('registros_diarios').doc();
        batch.set(regRef, {
          'fecha': Timestamp.fromDate(fecha),
          'huevos_buenos': huevos,
          'huevos_rotos': (huevos * 0.02).toInt(),
          'alimento_kg': (capacidad * 0.12 / 1000 * capacidad)
              .clamp(80, 200)
              .toDouble(),
          'agua_litros': 350.0,
          'mortalidad': dia == 5 ? 8 : (dia == 10 ? 6 : 1),
          'novedades': dia == 5
              ? 'Se detectó alta mortalidad, se reportó al administrador.'
              : '',
          'registrado_por': adminId,
          'es_demo': true,
        });
        totalRegistros++;
        operacionesEnBatch++;
        await flushSiHaceFalta();
      }

      final sanitarioRef1 = loteRef.collection('registros_sanitarios').doc();
      batch.set(sanitarioRef1, {
        'fecha': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 10)),
        ),
        'tipo_evento': 'vacunacion',
        'producto_aplicado': 'Newcastle + Bronquitis',
        'dosis': {'cantidad': 1.0, 'unidad': 'ml por ave'},
        'foto_url': '',
        'registrado_por': adminId,
        'es_demo': true,
      });
      operacionesEnBatch++;
      await flushSiHaceFalta();

      final sanitarioRef2 = loteRef.collection('registros_sanitarios').doc();
      batch.set(sanitarioRef2, {
        'fecha': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 3)),
        ),
        'tipo_evento': 'desinfeccion',
        'producto_aplicado': 'Glutaraldehído al 2%',
        'dosis': {'cantidad': 10.0, 'unidad': 'litros'},
        'foto_url': '',
        'registrado_por': adminId,
        'es_demo': true,
      });
      operacionesEnBatch++;
      await flushSiHaceFalta();

      final conteoRef = _db.collection('inventario_alimento').doc();
      batch.set(conteoRef, {
        'tipo': 'conteo',
        'bodeguero_id': adminId,
        'id_galpon': galponRef.id,
        'cantidad_kg': 3000.0,
        'precio_kg': 0.0,
        'total': 0.0,
        'proveedor': '',
        'notas': 'Conteo inicial de demostración',
        'fecha': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 15)),
        ),
        'es_demo': true,
      });
      operacionesEnBatch++;
      await flushSiHaceFalta();

      final invRef = _db.collection('inventario_alimento').doc();
      batch.set(invRef, {
        'tipo': 'entrada',
        'bodeguero_id': adminId,
        'id_galpon': galponRef.id,
        'cantidad_kg': 500.0,
        'precio_kg': 1.2,
        'total': 600.0,
        'proveedor': 'AgroInsumos Demo S.A.',
        'notas': 'Carga de demostración',
        'fecha': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 7)),
        ),
        'es_demo': true,
      });
      operacionesEnBatch++;
      await flushSiHaceFalta();

      for (int i = 0; i < 5; i++) {
        final fechaClasif = DateTime.now().subtract(Duration(days: i * 2));
        final totalDia = (capacidad * 0.15).toInt();
        final clasifRef = _db.collection('clasificacion_huevos').doc();
        batch.set(clasifRef, {
          'bodeguero_id': adminId,
          'id_galpon': galponRef.id,
          'clasificacion': {
            'B': (totalDia * 0.15).toInt(),
            'A': (totalDia * 0.35).toInt(),
            'AA': (totalDia * 0.35).toInt(),
            'AAA': (totalDia * 0.15).toInt(),
          },
          'total': totalDia,
          'fecha': Timestamp.fromDate(fechaClasif),
          'es_demo': true,
        });
        operacionesEnBatch++;
        await flushSiHaceFalta();
      }

      final ventasDemo = [
        {
          'tipo': 'AAA',
          'cantidad': 180,
          'precio': 0.45,
          'cliente': 'Supermercado El Ahorro',
        },
        {
          'tipo': 'AA',
          'cantidad': 240,
          'precio': 0.38,
          'cliente': 'Distribuidora San José',
        },
        {
          'tipo': 'A',
          'cantidad': 300,
          'precio': 0.32,
          'cliente': 'Tienda La Esquina',
        },
        {
          'tipo': 'B',
          'cantidad': 150,
          'precio': 0.25,
          'cliente': 'Panadería Doña Rosa',
        },
      ];

      for (int i = 0; i < ventasDemo.length; i++) {
        final v = ventasDemo[i];
        final cantidad = v['cantidad'] as int;
        final precio = v['precio'] as double;
        final ventaRef = _db.collection('ventas').doc();
        batch.set(ventaRef, {
          'vendedor_id': adminId,
          'admin_id': adminId,
          'id_galpon': galponRef.id,
          'tipo_huevo': v['tipo'],
          'cantidad_unidades': cantidad,
          'precio_unidad': precio,
          'total': cantidad * precio,
          'cliente': v['cliente'],
          'notas': 'Venta de demostración',
          'fecha': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: i + 1)),
          ),
          'es_demo': true,
        });
        operacionesEnBatch++;
        await flushSiHaceFalta();
      }
    }

    if (operacionesEnBatch > 0) {
      await batch.commit();
    }

    return '2 galpones · 2 lotes · $totalRegistros registros diarios · '
        '4 eventos sanitarios · 2 entradas de inventario · '
        '10 clasificaciones de huevos · 8 ventas';
  }

  Future<int> limpiarDatosDemo({required String adminId}) async {
    int totalBorrados = 0;

    final galponesSnap = await _db
        .collection('galpones')
        .where('administrador_id', isEqualTo: adminId)
        .where('es_demo', isEqualTo: true)
        .get();

    for (final galpon in galponesSnap.docs) {
      final lotesSnap = await galpon.reference.collection('lotes_aves').get();

      for (final lote in lotesSnap.docs) {
        final diariosSnap = await lote.reference
            .collection('registros_diarios')
            .where('es_demo', isEqualTo: true)
            .get();
        for (final d in diariosSnap.docs) {
          await d.reference.delete();
          totalBorrados++;
        }

        final sanitariosSnap = await lote.reference
            .collection('registros_sanitarios')
            .where('es_demo', isEqualTo: true)
            .get();
        for (final s in sanitariosSnap.docs) {
          await s.reference.delete();
          totalBorrados++;
        }

        await lote.reference.delete();
        totalBorrados++;
      }

      await galpon.reference.delete();
      totalBorrados++;
    }

    final invSnap = await _db
        .collection('inventario_alimento')
        .where('es_demo', isEqualTo: true)
        .get();
    for (final d in invSnap.docs) {
      await d.reference.delete();
      totalBorrados++;
    }

    final clasifSnap = await _db
        .collection('clasificacion_huevos')
        .where('es_demo', isEqualTo: true)
        .get();
    for (final d in clasifSnap.docs) {
      await d.reference.delete();
      totalBorrados++;
    }

    final ventasSnap = await _db
        .collection('ventas')
        .where('es_demo', isEqualTo: true)
        .get();
    for (final d in ventasSnap.docs) {
      await d.reference.delete();
      totalBorrados++;
    }

    return totalBorrados;
  }
}
