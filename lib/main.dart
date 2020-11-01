import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nasa_apod/screens/about_screen.dart';
import 'package:nasa_apod/screens/detail_screen.dart';
import 'package:nasa_apod/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/apod_model.dart';
import 'models/app_storage.dart';
import 'screens/home_screen.dart';

void main() {
  // DEBUG: Generate random data
  // generateMockData();

  runApp(ChangeNotifierProvider(
      create: (context) => ApodModel(), child: MainApp()));
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: appTheme,
      initialRoute: AppScaffold.routeName,
      routes: {
        AppScaffold.routeName: (context) => AppScaffold(),
        DetailScreen.routeName: (context) => DetailScreen(),
        MediaScreen.routeName: (context) => MediaScreen(),
        AboutScreen.routeName: (context) => AboutScreen(),
      },
    );
  }
}

// DEBUG: Generate mock values
void generateMockData() {
  DateTime _now = DateTime.now();
  List<String> mockDates = List.generate(
      10,
      (index) => (DateTime(_now.year, _now.month, _now.day)
          .subtract(Duration(days: index * 2))
          .toIso8601String()));

  AppData mockAppData = AppData(favoriteDates: mockDates);
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(
      {AppStorage.KEY: jsonEncode(mockAppData)});
}
