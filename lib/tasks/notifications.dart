import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationChannel {
  wallpaperUpdates,
}

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

void sendNotification(
  NotificationChannel channel,
  String title,
  String message,
) async {
  String channelId = 'com.ckchingdev.nasa_apod_$channel';

  AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
          channelId, 'Wallpaper Updates', 'For wallpaper updates and changes',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');
  NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
      0, title, message, platformChannelSpecifics);
}
