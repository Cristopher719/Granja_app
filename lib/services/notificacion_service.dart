import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'metricas_service.dart';

class NotificacionService {
  static final NotificacionService _instancia = NotificacionService._interno();
  factory NotificacionService() => _instancia;
  NotificacionService._interno();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _canalAlerta =
      AndroidNotificationChannel(
        'alertas_granja',
        'Alertas de Granja',
        description: 'Alertas críticas de mortalidad y stock',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  static const AndroidNotificationChannel _canalInfo =
      AndroidNotificationChannel(
        'info_granja',
        'Información de Granja',
        description: 'Registros y novedades del día',
        importance: Importance.defaultImportance,
      );

  Future<void> inicializar() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    final androidPlugin = _localPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_canalAlerta);
    await androidPlugin?.createNotificationChannel(_canalInfo);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _localPlugin.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      MetricasService().registrarAtencionAlerta(message, 'primer_plano');

      final notification = message.notification;
      if (notification == null) return;

      final esAlerta =
          message.data['tipo'] == 'mortalidad' ||
          message.data['tipo'] == 'stock_bajo';

      _localPlugin.show(
        message.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            esAlerta ? 'alertas_granja' : 'info_granja',
            esAlerta ? 'Alertas de Granja' : 'Información de Granja',
            channelDescription: esAlerta
                ? 'Alertas críticas de mortalidad y stock'
                : 'Registros y novedades del día',
            importance: esAlerta
                ? Importance.max
                : Importance.defaultImportance,
            priority: esAlerta ? Priority.high : Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen(
      (m) => MetricasService().registrarAtencionAlerta(m, 'abierta'),
    );
    final inicial = await _fcm.getInitialMessage();
    if (inicial != null) {
      MetricasService().registrarAtencionAlerta(inicial, 'abierta');
    }

    debugPrint('NotificacionService inicializado');
  }

  Future<void> suscribirATopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    debugPrint('Suscrito al topic: $topic');
  }

  Future<void> desuscribirDeTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    debugPrint('Desuscrito del topic: $topic');
  }

  static String topicAdmin(String adminId) => 'alertas_admin_$adminId';
}

@pragma('vm:entry-point')
Future<void> manejarMensajeEnSegundoPlano(RemoteMessage message) async {
  debugPrint('Mensaje en segundo plano: ${message.notification?.title}');
}
