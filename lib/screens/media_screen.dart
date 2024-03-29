import 'package:flutter/material.dart';
import 'package:nasa_apod/models/apod_model.dart';
import 'package:nasa_apod/models/app_storage.dart';
import 'package:nasa_apod/tasks/notifications.dart';
import 'package:nasa_apod/tasks/wallpaper_task.dart';
import 'package:nasa_apod/utils/utils.dart';
import 'package:wallpaper_manager/wallpaper_manager.dart';

class MediaScreen extends StatelessWidget {
  static const String routeName = '/detail/media';

  @override
  Widget build(BuildContext context) {
    final Apod apod = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(
        actions: [SetWallpaperButton(apod: apod)],
      ),
      body: SafeArea(
        child: InteractiveViewer(
          child: Container(
            child: Center(
              child: Container(
                width: double.infinity,
                child: Hero(
                    tag: 'apodMediaTag-${apod.date}',
                    child:
                        buildMediaPreview(context, apod.mediaType, apod.url)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SetWallpaperButton extends StatelessWidget {
  final Apod apod;

  SetWallpaperButton({@required this.apod});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.wallpaper),
      onPressed: () {
        showDialog(
          context: context,
          child: AlertDialog(
            title: Text('Set image as wallpaper?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
              SetWallpaperConfirmButton(apod: apod),
            ],
            content: Text(
              'Do you want to replace your current wallpaper with this photo?\n\nNOTE: This will also disable daily wallpaper (if enabled).',
            ),
          ),
        );
      },
    );
  }
}

class SetWallpaperConfirmButton extends StatefulWidget {
  final Apod apod;

  SetWallpaperConfirmButton({@required this.apod});

  @override
  _SetWallpaperConfirmButtonState createState() =>
      _SetWallpaperConfirmButtonState();
}

class _SetWallpaperConfirmButtonState extends State<SetWallpaperConfirmButton> {
  bool done, doneWithError;
  final Widget loadingDialog = SimpleDialog(
    children: [
      ListTile(
        leading: CircularProgressIndicator(),
        title: Text('Setting wallpaper...'),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    done = false;
    doneWithError = false;
  }

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: (!done)
          ? () async {
              int wallpaperLocation = await showDialog(
                context: context,
                child: SimpleDialog(
                  title: Text('Set Wallpaper'),
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, WallpaperManager.HOME_SCREEN),
                      icon: Icon(Icons.home),
                      label: Text('Home Screen'),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, WallpaperManager.LOCK_SCREEN),
                      icon: Icon(Icons.lock),
                      label: Text('Lock Screen'),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, WallpaperManager.BOTH_SCREENS),
                      icon: Icon(Icons.phone_android),
                      label: Text('Home Screen and lock screen'),
                    ),
                  ],
                ),
              );

              if (wallpaperLocation != null) {
                _changeWallpaper(wallpaperLocation);
              }
            }
          : null,
      child: _buildButtonState(context),
    );
  }

  void _changeWallpaper(int wallpaperLocation) {
    double screenRatio = getScreenRatio(context);

    showDialog(
        context: context, child: loadingDialog, barrierDismissible: false);

    changeWallpaper(widget.apod, screenRatio, wallpaperLocation).then((_) {
      AppStorage.setDynamicWallpaper(false, screenRatio);
      sendNotification(
          NotificationChannel.wallpaperUpdates,
          'Wallpaper Changed',
          'Wallpaper has been set to ${widget.apod.title}');
    }).catchError((_) {
      sendNotification(
          NotificationChannel.wallpaperUpdates,
          'Cannot Set Wallpaper',
          'There has been an error while setting your wallpaper. Please try again later.');
      setState(() {
        doneWithError = true;
      });
    }).whenComplete(() {
      setState(() {
        done = true;
      });

      Navigator.pop(context);
    });
  }

  Widget _buildButtonState(BuildContext context) {
    if (!done) {
      return Text('OK');
    }

    Future.delayed(Duration(milliseconds: 1500)).then((_) {
      Navigator.pop(context);
    });

    if (doneWithError) {
      return Icon(Icons.clear);
    }

    return Icon(Icons.check);
  }
}
