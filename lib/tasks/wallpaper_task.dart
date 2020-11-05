import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nasa_apod/models/api.dart';
import 'package:nasa_apod/models/apod_model.dart';
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
// DEBUG: change frequency duration. 15 minutes only for debugging
const int DYNAMIC_WALLPAPER_CHECK_FREQUENCY_MINUTES = 15;

Future<void> updateWallpaperTask(bool enable, double screenRatio) async {
  if (enable) {
    print('CHANGE_WALLPAPER_TASK_START');
    Workmanager.registerPeriodicTask(
      CHANGE_WALLPAPER_UNIQUE_NAME,
      CHANGE_WALLPAPER_TASKNAME,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      frequency: Duration(minutes: DYNAMIC_WALLPAPER_CHECK_FREQUENCY_MINUTES),
      inputData: {'screenRatio': screenRatio},
    );
  } else {
    print('CHANGE_WALLPAPER_TASK_CLEAR');
    Workmanager.cancelByUniqueName(CHANGE_WALLPAPER_UNIQUE_NAME);

    await _setLastWallpaperDate(ApodApi.dateRange.start);
  }
}

Future<void> attemptChangeWallpaper(double screenRatio) async {
  print('CHANGE_WALLPAPER_ATTEMPT');

  DateTime dateToday = _getDateToday();
  DateTime _lastLoadedDate = await getLastWallpaperDate();

  // DEBUG
  print('BEFORE_ATTEMPT - Last Loaded Date: $_lastLoadedDate');

  if (dateToday != _lastLoadedDate) {
    try {
      Apod apod = await ApodApi.fetchApodByDate(dateToday);

      switch (apod.mediaType) {
        case MediaType.image:
          try {
            await changeWallpaper(apod, screenRatio);
            print('CHANGE_WALLPAPER_SUCCESS');
            sendNotification(
                NOTIFICATION_TITLE, 'Wallpaper has been set to ${apod.title}');
          } catch (err) {
            // DEBUG
            print('CHANGE_WALLPAPER_ERROR');
            sendNotification(NOTIFICATION_TITLE, 'Error while setting image');
          }
          break;

        // If apod today is video, skip
        case MediaType.video:
          await _setLastWallpaperDate(apod.date);
          print('CHANGE_WALLPAPER_SKIPPED');
          // DEBUG
          sendNotification(NOTIFICATION_TITLE, 'APOD is video. SKIPPING');
          break;
      }
    } catch (err) {
      // DEBUG
      print('CHANGE_WALLPAPER_API_ERROR');
      sendNotification(NOTIFICATION_TITLE, 'Problem fetching Apod from API');
    }
  } else {
    // if last loaded date is today, already done
    print('CHANGE_WALLPAPER_ALREADY_DONE');

    // DEBUG
    sendNotification(
        NOTIFICATION_TITLE, 'Changed Wallpaper Already for this day');
  }
}

Future<void> changeWallpaper(Apod apod, double screenRatio) async {
  try {
    // Download image, get file path
    String fileDir = await cacheImage(apod.url, WALLPAPER_CACHE_FILENAME);

    // Crop image
    File imageFile = File(fileDir);
    var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());

    int widthMid = (decodedImage.width / 2).floor();
    int widthOffset = ((decodedImage.width / screenRatio) / 2).floor();

    int top = 0;
    int bottom = decodedImage.height;
    int left = widthMid - widthOffset;
    int right = widthMid + widthOffset;

    // DEBUG
    // print('Image Height: ${decodedImage.height}');
    // print('Image Width: ${decodedImage.width}');
    // print('Image Middle: $widthMid');
    // print('Left: $left');
    // print('Right: $right');

    // Set Wallpaper
    await WallpaperManager.setWallpaperFromFileWithCrop(
        fileDir, WallpaperManager.HOME_SCREEN, left, top, right, bottom);

    await _setLastWallpaperDate(apod.date);
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
