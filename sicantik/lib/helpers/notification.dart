import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sicantik/screens/view_note_screen.dart';
import 'package:sicantik/utils.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void onDidReceiveNotificationResponse(NotificationResponse details) {
  Get.to(() => ViewNoteScreen(), arguments: {"noteId": details.payload});
}

Future initLocalNotification() async {
  tz.initializeTimeZones();

  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestPermission();

  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  // Only work for Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  // If you want, callback on clicking the local notification, modify the initialize
  await flutterLocalNotificationsPlugin
      .initialize(initializationSettings,
          onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
          onDidReceiveBackgroundNotificationResponse:
              onDidReceiveNotificationResponse)
      .then((_) {
    logger.d("LocalNotification setup successfully");

  }).catchError((Object error) {
    logger.e("Error: $error");
  });
}

Future<int> scheduleNotification(
    String title, String body, String noteId, tz.TZDateTime datetime) async {
  final remindersStorage = GetStorage("reminders");
  int id = remindersStorage.read("currentFreeId") ?? 0;
  await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      datetime,
      const NotificationDetails(
          android: AndroidNotificationDetails(
              'note reminders 000', 'note reminders')),
      payload: noteId,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime);
  await remindersStorage.write("currentFreeId", id + 1);
  return id;
}

Future removeNotification(int id) async {
  // cancel the notification with id value of zero
  await flutterLocalNotificationsPlugin.cancel(id);
}
