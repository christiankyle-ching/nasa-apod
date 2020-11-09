import 'package:nasa_apod/tasks/wallpaper_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallpaper_manager/wallpaper_manager.dart';

/*
Connection to Persistent Storage - SharedPreferences
*/
class AppStorage {
  static const FAVORITES_KEY = 'favorites';
  static const ENABLE_DAILY_WALLPAPER = 'enableDailyWallpaper';
  static const ENABLE_HD_DOWNLOADS = 'enableHdDownloads';
  static const DAILY_WALLPAPER_LOCATION = 'dailyWallpaperLocation';

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getStringList(AppStorage.FAVORITES_KEY) ?? [];
  }

  void saveFavorites(List<String> favoriteApodDates) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(AppStorage.FAVORITES_KEY, favoriteApodDates);
  }

  static Future<bool> getDynamicWallpaper() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(AppStorage.ENABLE_DAILY_WALLPAPER) ?? false;
  }

  static void setDynamicWallpaper(bool newValue, double screenRatio) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(AppStorage.ENABLE_DAILY_WALLPAPER, newValue);

    await updateWallpaperTask(newValue, screenRatio);
  }

  static Future<bool> getHdSetting() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(AppStorage.ENABLE_HD_DOWNLOADS) ?? false;
  }

  static void setHdSetting(bool newValue) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(AppStorage.ENABLE_HD_DOWNLOADS, newValue);
  }

  static Future<int> getDailyWallpaperLocation() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(AppStorage.DAILY_WALLPAPER_LOCATION) ??
        WallpaperManager.HOME_SCREEN;
  }

  static void setDailyWallpaperLocation(int newValue) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(AppStorage.DAILY_WALLPAPER_LOCATION, newValue);
  }
}
