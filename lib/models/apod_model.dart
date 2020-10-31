import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:nasa_apod/models/api.dart';
import 'package:nasa_apod/models/app_storage.dart';

// Base Apod Class
class Apod {
  final String copyright;
  final DateTime date;
  final String explanation;
  final String hdurl;
  final String url;
  final String mediaType;
  final String serviceVersion;
  final String title;

  Apod({
    this.copyright,
    this.date,
    this.explanation,
    this.hdurl,
    this.url,
    this.mediaType,
    this.serviceVersion,
    this.title,
  });

  factory Apod.fromJson(Map<String, dynamic> json) {
    DateTime date = DateTime.parse(json['date']);
    String httpUrl = ApodApi.convertUrlToHttp(json['url'].toString());
    String httpUrlHd = ApodApi.convertUrlToHttp(json['hdurl'].toString());

    return Apod(
      copyright: json['copyright'] ?? '',
      date: date,
      explanation: json['explanation'],
      hdurl: httpUrlHd,
      url: httpUrl,
      mediaType: json['media_type'],
      serviceVersion: json['service_version'],
      title: json['title'],
    );
  }

  @override
  String toString() {
    return '${this.date} - ${this.title}';
  }
}

// Provider / ChangeNotifier
class ApodModel extends ChangeNotifier {
  final AppStorage appStorage = AppStorage();

  final List<DateTime> _favoriteApodDates = List<DateTime>();

  UnmodifiableListView<DateTime> get favoriteApodDates =>
      UnmodifiableListView(_favoriteApodDates);

  final List<Apod> _favoriteApods = List<Apod>();

  UnmodifiableListView<Apod> get favoriteApods =>
      UnmodifiableListView(_favoriteApods);

  final List<Apod> _listOfApods = List<Apod>();

  UnmodifiableListView<Apod> get listOfApods =>
      UnmodifiableListView(_listOfApods);

  DateTime _lastLoadedDate = ApodApi.initDate;

  ApodModel() {
    // Get Local Storage Data, then set to runtime variables
    appStorage.getData().then((appData) {
      // Map date string list to DateTime objects
      List<DateTime> storageFavorites =
          AppData.convertListStringToDateTime(appData.favoriteDates);

      _favoriteApodDates.addAll(storageFavorites);
      fetchAllFavoriteApods();

      notifyListeners();
    });
  }

  // Recents List
  bool _isRecentsLoading = false;
  bool get isRecentsLoading => _isRecentsLoading;

  Future<void> fetchNextApods() async {
    if (!isRecentsLoading) {
      print('FETCH NEXT 5');
      _isRecentsLoading = true;
      for (int i = 0; i < ApodApi.itemPerPage; i++) {
        final DateTime dateToFetch =
            _lastLoadedDate.subtract(Duration(days: i));
        try {
          Apod apod = await ApodApi.fetchApodByDate(dateToFetch);
          _listOfApods.add(apod);
        } on SocketException catch (_) {
          rethrow;
        } catch (_) {
          rethrow;
        }

        if (i == ApodApi.itemPerPage - 1) {
          _lastLoadedDate = dateToFetch.subtract(Duration(days: 1));
          print('Next date to load: $_lastLoadedDate');
        }
      }
      _isRecentsLoading = false;
    }

    notifyListeners();
  }

  // Favorites
  bool _loadedFavorites = false;
  bool get loadedFavorites => _loadedFavorites;

  void addFavorite(DateTime date, Apod cachedApod) async {
    _favoriteApodDates.add(date);
    _favoriteApods.add(cachedApod);

    notifyListeners();
    updateStorage();

    // DEBUG
    print('Added: $date');
    _showFavoritesCount();
  }

  void removeFavorite(DateTime date) {
    _favoriteApodDates.remove(date);
    Apod apodToRemove =
        _favoriteApods.firstWhere((element) => element.date == date);
    _favoriteApods.remove(apodToRemove);
    notifyListeners();
    updateStorage();

    // DEBUG
    print('Removed: $date');
    _showFavoritesCount();
  }

  void clearFavorites() {
    _favoriteApodDates.clear();
    _favoriteApods.clear();
    notifyListeners();
    updateStorage();

    // DEBUG
    print('Cleared Favorites');
    _showFavoritesCount();
  }

  Future<void> fetchAllFavoriteApods() async {
    if (!_loadedFavorites) {
      for (DateTime date in _favoriteApodDates) {
        try {
          _favoriteApods.add(await ApodApi.fetchApodByDate(date));
        } on SocketException catch (_) {
          rethrow;
        } catch (_) {
          rethrow;
        }
      }
      _loadedFavorites = true;
    }

    notifyListeners();
  }

  // DEBUG:
  void _showFavoritesCount() {
    print('Favorites Count: ${_favoriteApodDates.length}');
  }

  void updateStorage() {
    // Sort before updating to storage
    _favoriteApodDates.sort((a, b) => a.compareTo(b));
    List<String> faveApodDatesString =
        AppData.convertListDateTimeToString(_favoriteApodDates);
    appStorage.saveData(AppData(favoriteDates: faveApodDatesString));
  }
}
