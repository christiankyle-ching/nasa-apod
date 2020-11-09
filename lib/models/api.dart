import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nasa_apod/secrets.dart';

import 'package:nasa_apod/models/apod_model.dart';

class ApodApi {
  static DateTime _now = DateTime.now();
  static DateTime _localNow = DateTime(_now.year, _now.month, _now.day);
  static DateTime _localTomorrow = _localNow.add(Duration(days: 1));

  static DateTime getInitDate() {
    DateTime _tmpDate = DateTime.now();
    return DateTime(_tmpDate.year, _tmpDate.month, _tmpDate.day);
  }

  static DateTime _getNextUpdateTime() {
    // Calculate offset between EST and Local
    Duration estOffset = _now.timeZoneOffset - Duration(hours: -5);

    // Subtract Local time to offset to get EST
    DateTime est = _now.subtract(estOffset);

    // Get EST tomorrow, then set midnight
    DateTime estTomorrow = est.add(Duration(days: 1));
    DateTime estMidnight =
        DateTime(estTomorrow.year, estTomorrow.month, estTomorrow.day);

    // Add offset back to get update time in local timezone
    return estMidnight.add(estOffset);
  }

  static String getNextUpdateTimeString() {
    DateTime _updateDateTime = _getNextUpdateTime();

    String day = '';
    day += (_updateDateTime.isAfter(_localTomorrow)) ? 'Tomorrow' : 'Today';
    day += ' (${DateFormat('EEEE').format(_updateDateTime)})';

    return '$day, some time after ${DateFormat('jm').format(_updateDateTime)}';
  }

  static DateTimeRange dateRange =
      DateTimeRange(start: DateTime(1995, 6, 16), end: DateTime.now());

  static String _apiUrl = 'https://api.nasa.gov/planetary/apod';
  static String _apiKey = Secrets().apiKey;

  static final int itemPerPage = 5;

  static Future<Apod> fetchApodByDate(DateTime date) async {
    final String fetchUrl = _buildUrl(date);

    try {
      print('Fetching: $fetchUrl');
      http.Response response = await http.get(fetchUrl);

      if (response.statusCode == 200) {
        return Apod.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(response.statusCode);
      }
    } on SocketException catch (err) {
      print('NO_INTERNET: $err');
      rethrow;
    } catch (err) {
      print('OTHER_EXCEPTION: $err');
      rethrow;
    }
  }

  static String _formatDate(DateTime date) {
    final String yyyy = date.year.toString();
    final String mm = date.month.toString().padLeft(2, '0');
    final String dd = date.day.toString().padLeft(2, '0');

    return '$yyyy-$mm-$dd';
  }

  static String _buildUrl(DateTime date) {
    final String dateStr = _formatDate(date);
    return '$_apiUrl?api_key=$_apiKey&date=$dateStr';
  }

  static String convertUrlToHttp(String url) {
    return url.replaceFirst('https', 'http');
  }
}
