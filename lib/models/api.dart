import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nasa_apod/secrets.dart';

import 'package:nasa_apod/models/apod_model.dart';

class ApodApi {
  static DateTime initDate = DateTime.now();
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

  static String getYoutubeId(String url) {
    // Match Youtube ID from Youtube Embed Url
    RegExp regex = new RegExp(r"embed\/(.*)\?rel");
    return regex.firstMatch(url).group(1);
  }
}
