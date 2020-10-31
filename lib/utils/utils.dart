import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nasa_apod/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';

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
  showDialog(context: context, child: _dialogNoInternet);
}

// Snackbars
showSnackbar(BuildContext context, String message, {int duration = 4}) async {
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

// Widgets
Widget buildMediaPreview(BuildContext context, String mediaType, String url) {
  return mediaType == 'image'
      ? _ImagePreview(url: url)
      : _VideoPreview(url: url);
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    Key key,
    @required this.url,
  }) : super(key: key);

  final String url;

  @override
  Widget build(BuildContext context) {
    print('Loading image from: $url');
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

  void _launchUrl(BuildContext context) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      showSnackbar(context, 'Cannot open link: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: () => _launchUrl(context),
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
