import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../screens/seguimiento_screen.dart';

class PushNotificationsService {
  static const String _channelId = 'mamma_pizza_orders';
  static const String _channelName = 'Pedidos';
  static const String _channelDescription =
      'Actualizaciones de pedidos Mamma Pizza';

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static Map<String, dynamic>? _pendingNavigation;
  static bool _firebaseReady = false;
  static String? _currentFid;
  static Completer<String>? _pendingUnregistration;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;

      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_notification'),
      );
      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDescription,
              importance: Importance.max,
            ),
          );

      FirebaseMessaging.onMessage.listen((message) {
        unawaited(_showForegroundNotification(message));
      });
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
      FirebaseMessaging.instance.onRegistered.listen(
        (fid) => unawaited(_registerIfSignedIn(fid)),
        onError: (Object error, StackTrace stackTrace) {
          debugPrint(
              '[FCM cliente] No se pudo registrar la instalación: $error');
        },
      );
      FirebaseMessaging.instance.onUnregistered.listen(
        _onFidUnregistered,
        onError: (Object error, StackTrace stackTrace) {
          debugPrint(
              '[FCM cliente] No se pudo desregistrar la instalación: $error');
        },
      );

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _pendingNavigation = initialMessage.data;
      }
    } catch (error, stackTrace) {
      _firebaseReady = false;
      debugPrint('[FCM cliente] No se pudo inicializar Firebase: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> syncInstallation() async {
    if (!_firebaseReady) return;

    try {
      final permission = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus != AuthorizationStatus.authorized &&
          permission.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint('[FCM cliente] Permiso de notificaciones no concedido.');
        return;
      }

      await FirebaseMessaging.instance.register();
    } catch (error, stackTrace) {
      debugPrint('[FCM cliente] No se pudo registrar la instalación: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> unregisterDevice() async {
    if (!_firebaseReady) return;

    final fidAnterior = _currentFid;
    final registroPendiente = Completer<String>();
    _pendingUnregistration = registroPendiente;
    try {
      await FirebaseMessaging.instance.unregister();

      String? fid;
      try {
        fid =
            await registroPendiente.future.timeout(const Duration(seconds: 5));
      } on TimeoutException {
        fid = fidAnterior;
      }
      if (fid != null) {
        try {
          await ApiClient.delete(
            '/notificaciones/instalacion',
            {'fid': fid},
          ).timeout(const Duration(seconds: 10));
        } catch (error, stackTrace) {
          debugPrint(
              '[FCM cliente] No se pudo retirar la instalación del backend: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      } else {
        debugPrint(
            '[FCM cliente] No se recibió el FID para retirar del backend.');
      }
    } catch (error, stackTrace) {
      debugPrint(
          '[FCM cliente] No se pudo cerrar el registro de notificaciones: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (_pendingUnregistration == registroPendiente) {
        _pendingUnregistration = null;
      }
    }
  }

  static void processPendingNavigation() {
    final pending = _pendingNavigation;
    if (pending == null) return;
    _pendingNavigation = null;
    _openFromData(pending);
  }

  static Future<void> _registerIfSignedIn(String fid) async {
    _currentFid = fid;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getString('token') == null) return;
      await _registerFid(fid);
    } catch (error, stackTrace) {
      debugPrint('[FCM cliente] No se pudo registrar el FID: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static void _onFidUnregistered(String fid) {
    _currentFid = null;
    final pending = _pendingUnregistration;
    if (pending != null && !pending.isCompleted) {
      pending.complete(fid);
    }
  }

  static Future<void> _registerFid(String fid) async {
    await ApiClient.post('/notificaciones/instalacion', {
      'app': 'cliente',
      'fid': fid,
    });
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Mamma Pizza';
    final body = message.notification?.body;
    if (body == null || body.isEmpty) return;

    try {
      await _localNotifications.show(
        id: message.messageId?.hashCode ??
            DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (error, stackTrace) {
      debugPrint('[FCM cliente] No se pudo mostrar la notificación: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static void _onMessageOpened(RemoteMessage message) {
    _openFromData(message.data);
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        debugPrint(
            '[FCM cliente] La notificación no contiene datos de navegación válidos.');
        return;
      }
      _openFromData(Map<String, dynamic>.from(decoded));
    } catch (error, stackTrace) {
      debugPrint('[FCM cliente] No se pudo procesar la notificación: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static void _openFromData(Map<String, dynamic> data) {
    final pedidoId = int.tryParse(data['pedidoId']?.toString() ?? '');
    if (data['tipo'] != 'estado_pedido' || pedidoId == null) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingNavigation = data;
      return;
    }
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => SeguimientoScreen(pedidoId: pedidoId),
      ),
    );
  }
}
