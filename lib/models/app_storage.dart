import 'package:nasa_apod/tasks/wallpaper_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*
Connection to Persistent Storage - SharedPreferences
*/
class AppStorage {
  static const FAVORITES_KEY = 'favorites';
  static const _ENABLE_DYNAMIC_WALLPAPER = 'enableDynamicWallpaper';

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

    return prefs.getBool(AppStorage._ENABLE_DYNAMIC_WALLPAPER) ?? false;
  }

  static void setDynamicWallpaper(bool newValue, double screenRatio) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(AppStorage._ENABLE_DYNAMIC_WALLPAPER, newValue);

    await updateWallpaperTask(newValue, screenRatio);
  }
}
