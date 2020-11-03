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
// DEBUG: change frequency duration. 15 minutes only for debugging
const int DYNAMIC_WALLPAPER_CHECK_FREQUENCY_MINUTES = 15;

Future<void> updateWallpaperTask(bool enable) async {
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

    await _setLastWallpaperDate(ApodApi.dateRange.start);
  }
}

Future<void> attemptChangeWallpaper() async {
  print('CHANGE_WALLPAPER_ATTEMPT');

  DateTime dateToday = _getDateToday();
  DateTime _lastLoadedDate = await _getLastWallpaperDate();

  if (dateToday != _lastLoadedDate) {
    Apod apod = await ApodApi.fetchApodByDate(dateToday);

    switch (apod.mediaType) {
      case MediaType.image:
        try {
          await changeWallpaper(apod);
          sendNotification(
              NOTIFICATION_TITLE, 'Wallpaper has been set to ${apod.title}');
        } catch (err) {
          print('CHANGE_WALLPAPER_ERROR');
        }

        print('CHANGE_WALLPAPER_SUCCESS');
        break;

      // If apod today is video, skip
      case MediaType.video:
        await _setLastWallpaperDate(apod.date);
        print('CHANGE_WALLPAPER_SKIPPED');
        break;
    }
  } else {
    // if last loaded date is today, already done
    print('CHANGE_WALLPAPER_ALREADY_DONE');
  }
}

Future<void> changeWallpaper(Apod apod) async {
  try {
    // Download image, then set wallpaper
    String fileDir = await cacheImage(apod.url, WALLPAPER_CACHE_FILENAME);
    await WallpaperManager.setWallpaperFromFile(
        fileDir, WallpaperManager.HOME_SCREEN);
    await _setLastWallpaperDate(apod.date);
  } catch (_) {
    rethrow;
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
