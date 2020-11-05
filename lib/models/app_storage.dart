// Encodes/Decodes AppData to for preparation for AppStorage
import 'dart:convert';

import 'package:nasa_apod/tasks/wallpaper_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppData {
  List<String> favoriteDates;

  AppData({this.favoriteDates});

  factory AppData.fromJson(Map<String, dynamic> json) {
    List<dynamic> _favoriteDates = json['favoriteDates'] ?? <dynamic>[];
    _favoriteDates = _favoriteDates.map((dates) => dates.toString()).toList();
    return AppData(
      favoriteDates: _favoriteDates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favoriteDates': this.favoriteDates,
    };
  }

  static List<String> convertListDateTimeToString(List<DateTime> setDateTime) {
    return setDateTime.map((datetime) => datetime.toIso8601String()).toList();
  }

  static List<DateTime> convertListStringToDateTime(List<String> listStr) {
    return listStr.map((dateStr) => DateTime.parse(dateStr)).toList();
  }
}

/*
Connection to Persistent Storage - SharedPreferences
Saves object of type AppData
*/
class AppStorage {
  static const FAVORITES_KEY = 'favorites';
  static const _ENABLE_DYNAMIC_WALLPAPER = 'enableDynamicWallpaper';

  Future<AppData> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    AppData blankAppData = AppData(favoriteDates: []);
    String blankAppDataStr = jsonEncode(blankAppData);

    // return AppData from SharedPreferences<Json>
    return AppData.fromJson(jsonDecode(
        prefs.getString(AppStorage.FAVORITES_KEY) ?? blankAppDataStr));
  }

  void saveFavorites(AppData appData) async {
    final prefs = await SharedPreferences.getInstance();

    // Set AppData value encoded to String<Json> to SharedPreferences
    await prefs.setString(AppStorage.FAVORITES_KEY, jsonEncode(appData));
  }

  static Future<bool> getDynamicWallpaper() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(AppStorage._ENABLE_DYNAMIC_WALLPAPER) ?? false;
  }

  static void setDynamicWallpaper(bool newValue, double screenRatio) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(AppStorage._ENABLE_DYNAMIC_WALLPAPER, newValue);

    await updateWallpaperTask(newValue, screenRatio);
  }
}
