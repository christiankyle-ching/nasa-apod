import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nasa_apod/models/api.dart';
import 'package:nasa_apod/models/apod_model.dart';
import 'package:nasa_apod/models/app_storage.dart';
import 'package:nasa_apod/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallpaper_manager/wallpaper_manager.dart';
import 'package:workmanager/workmanager.dart';

import 'notifications.dart';

const String CHANGE_WALLPAPER_TASKNAME = 'changeWallpaperTask';
const String WALLPAPER_CACHE_FILENAME = 'dynamic_wallpaper.png';
const String LAST_WALLPAPER_UPDATE_KEY = 'lastWallpaperUpdate';
const int DYNAMIC_WALLPAPER_CHECK_FREQUENCY_MINUTES = 15;

// Register tasks
void initializeWallpaperTask() async {
  Workmanager.initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  updateWorkManager(await AppStorage.getDynamicWallpaper());
}

void updateWorkManager(bool enable) {
  if (enable) {
    print('START TASK');
    Workmanager.registerPeriodicTask(
      '1',
      CHANGE_WALLPAPER_TASKNAME,
      frequency: Duration(minutes: DYNAMIC_WALLPAPER_CHECK_FREQUENCY_MINUTES),
    );
  } else {
    print('CLEAR TASK');
    Workmanager.cancelByUniqueName('1');
  }
}

// Gets called for every task called
void callbackDispatcher() {
  Workmanager.executeTask((task, inputData) async {
    print("Native called background task: $task");

    switch (task) {
      case CHANGE_WALLPAPER_TASKNAME:
        await changeWallpaper();
        return true;
      default:
        return true;
    }
  });
}

Future<void> changeWallpaper() async {
  print('CHANGE_WALLPAPER_ATTEMPT');

  try {
    Apod apod = await ApodApi.fetchApodByDate(_getDateToday());
    DateTime _lastLoadedDate = await _getLastWallpaperDate();

    print('Last Loaded Date: $_lastLoadedDate');
    if (apod.mediaType == MediaType.image && apod.date != _lastLoadedDate) {
      String fileDir = await cacheImage(apod.url, WALLPAPER_CACHE_FILENAME);
      await WallpaperManager.setWallpaperFromFile(
          fileDir, WallpaperManager.HOME_SCREEN);

      await _setLastWallpaperDate(apod.date);

      _sendNotification('Wallpaper has been set to ${apod.title}');
      print('CHANGE_WALLPAPER_SUCCESS');
    }
  } catch (err) {
    print('CHANGE_WALLPAPER_FAILED');

    _sendNotification('Failed to set daily wallpaper');
  }
}

DateTime _getDateToday() {
  final DateTime _dateToday = DateTime.now();
  return DateTime(_dateToday.year, _dateToday.month, _dateToday.day);
}

_setLastWallpaperDate(DateTime newDate) async {
  var prefs = await SharedPreferences.getInstance();

  prefs.setString(LAST_WALLPAPER_UPDATE_KEY, newDate.toIso8601String());
}

Future<DateTime> _getLastWallpaperDate() async {
  var prefs = await SharedPreferences.getInstance();

  return DateTime.tryParse(prefs.getString(LAST_WALLPAPER_UPDATE_KEY) ??
      ApodApi.dateRange.start.toIso8601String());
}

void _sendNotification(String message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails('com.ckchingdev.nasa_apod',
          'nasa-apod-channel', 'Notifications for NASA APoD',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
    0,
    'APOD Daily Wallpaper',
    message,
    platformChannelSpecifics,
  );
}
