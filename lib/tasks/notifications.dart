import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('logo');

  final IOSInitializationSettings initializationSettingsIOS =
      IOSInitializationSettings(
          onDidReceiveLocalNotification: onDidReceiveLocalNotification);
  final MacOSInitializationSettings initializationSettingsMacOS =
      MacOSInitializationSettings();

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
    macOS: initializationSettingsMacOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: selectNotification);
}

Future<dynamic> selectNotification(String payload) async {
  if (payload != null) {
    print(payload);
  }
}

Future onDidReceiveLocalNotification(
    int id, String title, String body, String payload) async {
  /* 
  TODO: implement this
  Will be called when notification is called on foreground
  By default, IOS won't send notification when app is in use
  Handle by showing dialog instead, or not at all.
  */
}

void sendNotification(String title, String message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails('com.ckchingdev.nasa_apod',
          'nasa-apod-channel', 'Notifications for NASA APoD',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
      0, title, message, platformChannelSpecifics);
}
