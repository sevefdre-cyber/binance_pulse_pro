import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'debug_logger.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _notifId = 100;

  Future<void> init() async {
    if (_initialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    _initialized = true;
    DebugLogger.instance.log('NOTIF', 'Service de notification initialisé.');
  }

  Future<void> showExplosionAlert({
    required String symbol,
    required int jumps,
    required int windowSec,
    required double price,
    required double change24h,
    required String btcBias,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'explosion_alerts',
      'Alertes Explosion Jetons',
      channelDescription: 'Notifications immédiates de mouvements rapides',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);
    _notifId++;

    await _plugin.show(
      _notifId,
      '🚀 $symbol se prépare à exploser !',
      '+$jumps rangs en ${windowSec}s | Prix: $price | 24h: ${change24h.toStringAsFixed(2)}% | BTC: $btcBias',
      details,
    );
  }
}
