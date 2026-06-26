import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
bool _initialized = false;

Future<void> initNotifications() async {
  if (_initialized) return;
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await _plugin.initialize(settings: initSettings);

  // Request POST_NOTIFICATIONS permission on Android 13+
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (android != null) {
    await android.requestNotificationsPermission();
  }

  _initialized = true;
}

Future<void> showLocalNotification({
  required int id,
  required String title,
  required String body,
  String? payload,
}) async {
  const androidDetails = AndroidNotificationDetails(
    'campus_connect_channel',
    'Campus Connect',
    channelDescription: 'Notifikasi Campus Connect',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    playSound: true,
  );
  const details = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(),
  );
  await _plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: details,
    payload: payload,
  );
}
