import 'package:nasa_apod/models/api.dart';
import 'package:nasa_apod/models/apod_model.dart';
import 'package:nasa_apod/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallpaper_manager/wallpaper_manager.dart';
import 'package:workmanager/workmanager.dart';

import 'notifications.dart';

const String NOTIFICATION_TITLE = 'APOD Daily Wallpaper';
const String CHANGE_WALLPAPER_TASKNAME = 'changeWallpaperTask';
const String WALLPAPER_CACHE_FILENAME = 'dynamic_wallpaper.png';
const String LAST_WALLPAPER_UPDATE_KEY = 'lastWallpaperUpdate';
// REFACTOR: change frequency duration. 15 minutes only for debugging
const int DYNAMIC_WALLPAPER_CHECK_FREQUENCY_MINUTES = 15;

void updateWallpaperTask(bool enable) {
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

    _setLastWallpaperDate(ApodApi.dateRange.end);
  }
}

Future<void> changeWallpaper() async {
  print('CHANGE_WALLPAPER_ATTEMPT');

  try {
    Apod apod = await ApodApi.fetchApodByDate(_getDateToday());
    DateTime _lastLoadedDate = await _getLastWallpaperDate();

    print('Last Loaded Date: $_lastLoadedDate');
    if (apod.mediaType == MediaType.image && apod.date != _lastLoadedDate) {
      // Download image, then set wallpaper
      String fileDir = await cacheImage(apod.url, WALLPAPER_CACHE_FILENAME);
      await WallpaperManager.setWallpaperFromFile(
          fileDir, WallpaperManager.HOME_SCREEN);

      await _setLastWallpaperDate(apod.date);

      sendNotification(
        NOTIFICATION_TITLE,
        'Wallpaper has been set to ${apod.title}',
      );
      print('CHANGE_WALLPAPER_SUCCESS');
    } else {
      print('CHANGE_WALLPAPER_ALREADY_DONE');
    }
  } catch (err) {
    print('CHANGE_WALLPAPER_FAILED');

    sendNotification(
      NOTIFICATION_TITLE,
      'Failed to set daily wallpaper',
    );
  }
}

DateTime _getDateToday() {
  final DateTime _dateToday = DateTime.now();
  return DateTime(_dateToday.year, _dateToday.month, _dateToday.day);
}

Future<DateTime> _getLastWallpaperDate() async {
  var prefs = await SharedPreferences.getInstance();

  return DateTime.tryParse(prefs.getString(LAST_WALLPAPER_UPDATE_KEY) ??
      ApodApi.dateRange.start.toIso8601String());
}

_setLastWallpaperDate(DateTime newDate) async {
  var prefs = await SharedPreferences.getInstance();

  prefs.setString(LAST_WALLPAPER_UPDATE_KEY, newDate.toIso8601String());
}
