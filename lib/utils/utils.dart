import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nasa_apod/models/apod_model.dart';
import 'package:nasa_apod/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

// Alert Dialogs
final AlertDialog _dialogNoInternet = AlertDialog(
  title: Text('Failed to connect to NASA'),
  content: Text('Please check your internet connection then try again.'),
  actions: [
    FlatButton(
      child: Text('EXIT'),
      onPressed: () => SystemNavigator.pop(),
    )
  ],
);

void showNoInternetError(BuildContext context) async {
  await Future.delayed(Duration(microseconds: 1));
  showDialog(
      context: context, child: _dialogNoInternet, barrierDismissible: false);
}

// Snackbars
showSnackbar(BuildContext context, String message, {int duration = 4}) async {
  removeAllSnackbars(context);
  // FIX: setState called during build
  await Future.delayed(Duration(microseconds: 1));
  return Scaffold.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
      ),
      duration: Duration(seconds: duration),
    ),
  );
}

void removeAllSnackbars(BuildContext context) async {
  // FIX: setState called during build
  await Future.delayed(Duration(microseconds: 1));
  try {
    Scaffold.of(context).removeCurrentSnackBar();
  } on AssertionError catch (_) {
    print('No Scaffold available');
  } catch (err) {
    print('Uncatched Error: $err');
  }
}

// Utils
bool isDateWithinRange(DateTimeRange range, DateTime date) {
  return ((date.isBefore(range.end) && date.isAfter(range.start)) ||
      (date.isAtSameMomentAs(range.start) || date.isAtSameMomentAs(range.end)));
}

double getScreenRatio(BuildContext context) {
  return MediaQuery.of(context).size.width.floor() /
      MediaQuery.of(context).size.height.floor();
}

// Widgets
Widget buildMediaPreview(
    BuildContext context, MediaType mediaType, String url) {
  switch (mediaType) {
    case MediaType.image:
      return _ImagePreview(url: url);
      break;
    case MediaType.video:
      return _VideoPreview(url: url);
      break;
    default:
      return Container();
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    Key key,
    @required this.url,
  }) : super(key: key);

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      loadingBuilder: (_, Widget child, ImageChunkEvent isLoading) {
        if (isLoading == null) return child;
        return Center(child: CircularProgressIndicator());
      },
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) {
        showSnackbar(context, 'An error occured while loading image');
        return Container();
      },
    );
  }
}

class _VideoPreview extends StatelessWidget {
  final String url;

  const _VideoPreview({this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48, bottom: 32),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 60,
            child: _VideoPlayButton(url: this.url),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayButton extends StatelessWidget {
  final String url;

  _VideoPlayButton({@required this.url});

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: () => launchUrl(context, url),
      child: Icon(
        Icons.play_arrow,
        color: Colors.white,
        size: 36,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: appTheme.colorScheme.error,
      elevation: 6.0,
    );
  }
}

void launchUrl(BuildContext context, String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    showSnackbar(context, 'Cannot open link: $url');
  }
}

Future<String> cacheImage(String mediaUrl, String filename) async {
  // Fetch Image
  http.Response response = await http.get(mediaUrl);

  // Get Application path
  final String directory = (await getApplicationDocumentsDirectory()).path;
  final String fileDir = '$directory/$filename';

  // Save image, uncropped
  File imageFile = new File(fileDir);
  imageFile.writeAsBytesSync(response.bodyBytes);

  return fileDir;
}

List<String> convertListDateTimeToString(List<DateTime> listDateTime) {
  return listDateTime.map((datetime) => datetime.toIso8601String()).toList();
}

List<DateTime> convertListStringToDateTime(List<String> listString) {
  return listString.map((dateStr) => DateTime.parse(dateStr)).toList();
}
