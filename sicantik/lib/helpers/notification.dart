import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


class LocalNotification {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future initLocalNotification() async {
    tz.initializeTimeZones();

    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();

    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    // Only work for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // If you want, callback on clicking the local notifaction, modify the initialize
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void scheduleNotification(
      int id,
      String title,
      String body,
      tz.TZDateTime datetime
    ) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        datetime,
        const NotificationDetails(
            android: AndroidNotificationDetails(
                'your channel id', 'your channel name',
                channelDescription: 'your channel description')),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime);
  }

  void removeNotification(int id) async {
    // cancel the notification with id value of zero
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
