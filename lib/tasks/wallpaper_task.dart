import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nasa_apod/models/api.dart';
import 'package:nasa_apod/models/apod_model.dart';
import 'package:nasa_apod/models/app_storage.dart';
import 'package:nasa_apod/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallpaper_manager/wallpaper_manager.dart';
import 'package:workmanager/workmanager.dart';

import 'notifications.dart';

const String NOTIFICATION_TITLE = 'APOD Daily Wallpaper';
const String CHANGE_WALLPAPER_UNIQUE_NAME = 'changeWallpaperTask';
const String CHANGE_WALLPAPER_TASKNAME = 'changeWallpaperTask';
const String WALLPAPER_CACHE_FILENAME = 'dynamic_wallpaper.png';
const String LAST_WALLPAPER_UPDATE_KEY = 'lastWallpaperUpdate';
// DEBUG: change frequency duration
const int DYNAMIC_WALLPAPER_CHECK_FREQUENCY_MINUTES = 45;

Future<void> updateWallpaperTask(bool enable, double screenRatio) async {
  if (enable) {
    print('CHANGE_WALLPAPER_TASK_START');
    await Workmanager.registerPeriodicTask(
      CHANGE_WALLPAPER_UNIQUE_NAME,
      CHANGE_WALLPAPER_TASKNAME,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      frequency: Duration(minutes: DYNAMIC_WALLPAPER_CHECK_FREQUENCY_MINUTES),
      inputData: {'screenRatio': screenRatio},
    );
  } else {
    print('CHANGE_WALLPAPER_TASK_CLEAR');
    await Workmanager.cancelByUniqueName(CHANGE_WALLPAPER_UNIQUE_NAME);

    await _setLastWallpaperDate(ApodApi.dateRange.start);
  }
}

Future<void> attemptChangeWallpaper(double screenRatio) async {
  print('CHANGE_WALLPAPER_ATTEMPT');

  DateTime dateToday = _getDateToday();
  DateTime _lastLoadedDate = await getLastWallpaperDate();

  if (dateToday != _lastLoadedDate) {
    try {
      Apod apod = await ApodApi.fetchApodByDate(dateToday);

      switch (apod.mediaType) {
        case MediaType.image:
          try {
            await changeWallpaper(apod, screenRatio);
            await _setLastWallpaperDate(apod.date);
            sendNotification(NotificationChannel.wallpaperUpdates,
                NOTIFICATION_TITLE, 'Wallpaper has been set to ${apod.title}');
          } catch (err) {
            sendNotification(NotificationChannel.wallpaperUpdates,
                NOTIFICATION_TITLE, 'Error while changing wallpaper');
          }
          break;

        // If apod today is video, skip
        case MediaType.video:
          await _setLastWallpaperDate(apod.date);
          sendNotification(
              NotificationChannel.wallpaperUpdates,
              NOTIFICATION_TITLE,
              'APOD for today is a video, and cannot be set as wallpaper.');
          break;
      }
    } catch (err) {
      rethrow;
    }
  }
}

Future<void> changeWallpaper(Apod apod, double screenRatio) async {
  try {
    // Download image, get file path
    String downloadUrl =
        (await AppStorage.getHdSetting()) ? apod.hdurl : apod.url;
    String fileDir = await cacheImage(downloadUrl, WALLPAPER_CACHE_FILENAME);

    // Crop image
    File imageFile = File(fileDir);
    var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());

    int widthMid = (decodedImage.width / 2).floor();
    int widthOffset = ((decodedImage.height * screenRatio) / 2).floor();

    int top = 0;
    int bottom = decodedImage.height;
    int left = widthMid - widthOffset;
    int right = widthMid + widthOffset;

    // DEBUG
    print('Screen Ratio: $screenRatio');
    print('Image Height: ${decodedImage.height}');
    print('Image Width: ${decodedImage.width}');
    print('Image Middle: $widthMid');
    print('Top: $top');
    print('Bottom: $bottom');
    print('Left: $left');
    print('Right: $right');

    print(imageFile);

    // Set Wallpaper
    await WallpaperManager.setWallpaperFromFileWithCrop(
        fileDir, WallpaperManager.HOME_SCREEN, left, top, right, bottom);
  } catch (_) {
    rethrow;
  }
}

DateTime _getDateToday() {
  final DateTime _dateToday = DateTime.now();
  return DateTime(_dateToday.year, _dateToday.month, _dateToday.day);
}

Future<DateTime> getLastWallpaperDate() async {
  var prefs = await SharedPreferences.getInstance();

  return DateTime.tryParse(prefs.getString(LAST_WALLPAPER_UPDATE_KEY) ??
      ApodApi.dateRange.start.toIso8601String());
}

_setLastWallpaperDate(DateTime newDate) async {
  var prefs = await SharedPreferences.getInstance();

  await prefs.setString(LAST_WALLPAPER_UPDATE_KEY, newDate.toIso8601String());
}
