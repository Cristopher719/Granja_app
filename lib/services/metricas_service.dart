import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class MetricasService {
  static final MetricasService _instancia = MetricasService._interno();
  factory MetricasService() => _instancia;
  MetricasService._interno();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _uidCache;
  String? _adminIdCache;

  Future<String?> _adminIdActual() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    if (_uidCache == uid && _adminIdCache != null) return _adminIdCache;
    final doc = await _db.collection('usuarios').doc(uid).get();
    final datos = doc.data();
    _uidCache = uid;
    _adminIdCache = datos?['rol'] == 'administrador'
        ? uid
        : datos?['creado_por'] as String?;
    return _adminIdCache;
  }

  Future<void> registrarDesempeno(String operacion, int milisegundos) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final adminId = await _adminIdActual();
      if (uid == null || adminId == null) return;
      await _db
          .collection('metricas_desempeno')
          .add({
            'operacion': operacion,
            'ms': milisegundos,
            'usuario_id': uid,
            'admin_id': adminId,
            'fecha': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('No se pudo guardar la métrica de desempeño: $e');
    }
  }

  Future<void> registrarAtencionAlerta(
    RemoteMessage mensaje,
    String modo,
  ) async {
    try {
      final tipo = mensaje.data['tipo'];
      if (tipo != 'mortalidad' && tipo != 'stock_bajo') return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final eventoMs = int.tryParse(mensaje.data['evento_en'] ?? '');
      final enviadoMs = int.tryParse(mensaje.data['enviado_en'] ?? '');
      if (eventoMs == null) return;
      await _db
          .collection('metricas_alertas')
          .add({
            'tipo': tipo,
            'galpon_id': mensaje.data['galpon_id'] ?? '',
            'evento_en': Timestamp.fromMillisecondsSinceEpoch(eventoMs),
            if (enviadoMs != null)
              'enviado_en': Timestamp.fromMillisecondsSinceEpoch(enviadoMs),
            'visto_en': FieldValue.serverTimestamp(),
            'modo': modo,
            'usuario_id': uid,
            'admin_id': uid,
          })
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('No se pudo guardar la atención de la alerta: $e');
    }
  }

  bool _enRango(Timestamp? t, DateTime desde, DateTime hasta) {
    final f = t?.toDate();
    if (f == null) return false;
    final d = DateTime(desde.year, desde.month, desde.day);
    final h = DateTime(hasta.year, hasta.month, hasta.day, 23, 59, 59);
    return !f.isBefore(d) && !f.isAfter(h);
  }

  Future<Map<String, double>> resumenAlertas({
    required String adminId,
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final snap = await _db
        .collection('metricas_alertas')
        .where('admin_id', isEqualTo: adminId)
        .get();
    final minutos = <double>[];
    for (final d in snap.docs) {
      final datos = d.data();
      final evento = datos['evento_en'] as Timestamp?;
      final visto = datos['visto_en'] as Timestamp?;
      if (evento == null || visto == null) continue;
      if (!_enRango(visto, desde, hasta)) continue;
      final seg = visto.toDate().difference(evento.toDate()).inSeconds;
      minutos.add(seg < 0 ? 0 : seg / 60);
    }
    if (minutos.isEmpty)
      return {'cantidad': 0, 'promedio_min': 0, 'pct_menos_1min': 0};
    final promedio = minutos.reduce((a, b) => a + b) / minutos.length;
    final rapidas = minutos.where((m) => m < 1).length;
    return {
      'cantidad': minutos.length.toDouble(),
      'promedio_min': promedio,
      'pct_menos_1min': rapidas * 100 / minutos.length,
    };
  }

  Future<Map<String, Map<String, double>>> resumenDesempeno({
    required String adminId,
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final snap = await _db
        .collection('metricas_desempeno')
        .where('admin_id', isEqualTo: adminId)
        .get();
    final porOperacion = <String, List<int>>{};
    for (final d in snap.docs) {
      final datos = d.data();
      if (!_enRango(datos['fecha'] as Timestamp?, desde, hasta)) continue;
      final op = datos['operacion'] as String? ?? 'otra';
      porOperacion
          .putIfAbsent(op, () => [])
          .add((datos['ms'] as num?)?.toInt() ?? 0);
    }
    return porOperacion.map((op, lista) {
      final promedio = lista.reduce((a, b) => a + b) / lista.length;
      final bajo3s = lista.where((ms) => ms < 3000).length;
      return MapEntry(op, {
        'cantidad': lista.length.toDouble(),
        'promedio_ms': promedio,
        'pct_menos_3s': bajo3s * 100 / lista.length,
      });
    });
  }
}
