import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nasa_apod/models/apod_model.dart';
import 'package:nasa_apod/theme/theme.dart';
import 'package:nasa_apod/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:share/share.dart';

class DetailScreen extends StatelessWidget {
  static const String routeName = '/detail';

  final Future<Apod> futureApod;

  DetailScreen({Key key, this.futureApod}) : super(key: key);

  Widget _buildFromInstance(Apod apod) {
    print('Detail Screen using instance of Apod');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          apod.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          FavoriteToggle(
            apod: apod,
          ),
          ShareButton(
            date: apod.date,
            mediaType: apod.mediaType,
            mediaUrl: apod.url,
            title: apod.title,
          ),
        ],
      ),
      body: ApodDetail(apod: apod),
    );
  }

  Widget _buildFromFuture(Future<Apod> apod) {
    print('Detail Screen using a FutureBuilder of Apod');

    return FutureBuilder(
      future: apod,
      builder: (context, snapshot) {
        try {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return ApodDetail(apod: snapshot.data, noScaffold: true);
          }

          if (snapshot.hasError) {
            if (snapshot.error.runtimeType == SocketException)
              throw (snapshot.error);
            if (snapshot.error == 404) {
              return Center(
                child: Text(
                    'No Available APoD for ${DateFormat.yMMMMd().format(DateTime.now())} (today)'),
              );
            }
            return Center(
              child: Text('An error has occured with code: ${snapshot.error}'),
            );
          }
        } on SocketException catch (_) {
          showNoInternetError(context);
        } catch (err) {
          print(err);
        }

        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // If apod not from ListView, check if parameter is supplied
    final Apod apod = ModalRoute.of(context).settings.arguments;
    bool fromRecentsList = (apod != null);

    return (fromRecentsList)
        ? _buildFromInstance(apod)
        : _buildFromFuture(futureApod);
  }
}

class FavoriteToggle extends StatelessWidget {
  final Apod apod;

  FavoriteToggle({@required this.apod});

  @override
  Widget build(BuildContext context) {
    return Consumer<ApodModel>(builder: (_, apodModel, __) {
      bool inFavorites = apodModel.favoriteApodDates.contains(apod.date);

      return IconButton(
          icon: Icon((inFavorites) ? Icons.star : Icons.star_border),
          onPressed: () {
            removeAllSnackbars(context);
            if (inFavorites) {
              apodModel.removeFavorite(apod.date);
              showSnackbar(context, 'Removed ${apod.title} to favorites');
            } else {
              apodModel.addFavorite(apod.date, apod);
              showSnackbar(context, 'Added ${apod.title} to favorites');
            }
          },
          color: (inFavorites) ? Colors.yellow : null);
    });
  }
}

class ApodDetail extends StatelessWidget {
  final Apod apod;
  final bool noScaffold;

  ApodDetail({@required this.apod, this.noScaffold = false});

  @override
  Widget build(BuildContext context) {
    Widget _date = Row(
      children: [
        Text(
          DateFormat.yMMMMd().format(apod.date),
          style: appTheme.textTheme.headline6,
        ),
      ],
    );

    TextStyle _copyrightTextStyle = appTheme.textTheme.bodyText1;
    Widget _copyrightRow = Row(
      children: [
        Text(
          '${apod.copyright} ',
          style: _copyrightTextStyle,
        ),
        Icon(
          Icons.copyright,
          size: _copyrightTextStyle.fontSize,
          color: _copyrightTextStyle.color,
        ),
      ],
    );

    Widget _description = Text(
      '${apod.explanation}',
      textAlign: TextAlign.justify,
      style: appTheme.textTheme.bodyText1.copyWith(height: 1.5),
    );

    Widget _mediaPreview = Hero(
      tag: 'apodMedia${apod.title}',
      child: Container(
        constraints: BoxConstraints(
          maxHeight: imageMaxHeight,
          minHeight: imageMaxHeight,
        ),
        width: double.infinity,
        child: buildMediaPreview(context, apod.mediaType, apod.url),
      ),
    );

    Widget _apodInformationCard = Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: 15,
              color: Colors.black.withOpacity(0.5),
              offset: Offset(0, -10),
            )
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 8.0,
          shape: RoundedRectangleBorder(
            side: BorderSide.none,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: // Title
                          Hero(
                        tag: apod.title,
                        child: Text(
                          apod.title,
                          style: titleStyle,
                        ),
                      ),
                    ),
                    if (noScaffold) FavoriteToggle(apod: apod),
                    if (noScaffold)
                      ShareButton(
                        date: apod.date,
                        mediaType: apod.mediaType,
                        mediaUrl: apod.url,
                        title: apod.title,
                      ),
                  ],
                ),

                // Date
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _date,
                ),

                // Copyright
                if (apod.copyright.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _copyrightRow,
                  ),

                // Explanation
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Description',
                    style: appTheme.textTheme.subtitle1,
                  ),
                ),

                Divider(
                  height: 30,
                  thickness: 3.0,
                ),

                Expanded(
                  child: ListView(
                    children: [_description],
                  ),
                ),
              ],
            ),
          ),
        ));

    return Column(
      children: [
        // Image / Video
        Align(
          heightFactor: 0.85,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/detail/media', arguments: apod);
            },
            // Image
            child: _mediaPreview,
          ),
        ),
        // Information Card

        Expanded(child: _apodInformationCard),
      ],
    );
  }
}

class MediaScreen extends StatelessWidget {
  static const String routeName = '/detail/media';

  @override
  Widget build(BuildContext context) {
    final Apod apod = ModalRoute.of(context).settings.arguments;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Scaffold(
          body: Container(
        child: Center(
          child: GestureDetector(
            child: Hero(
                tag: 'apodMedia${apod.title}',
                child: buildMediaPreview(context, apod.mediaType, apod.url)),
          ),
        ),
      )),
    );
  }
}

class ShareButton extends StatefulWidget {
  final MediaType mediaType;
  final String mediaUrl;
  final String title;
  final DateTime date;

  ShareButton({
    @required this.mediaType,
    @required this.mediaUrl,
    @required this.title,
    @required this.date,
  });

  @override
  _ShareButtonState createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton> {
  bool _isLoading;

  @override
  void initState() {
    super.initState();
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: (_isLoading)
          ? SizedBox(
              child: CircularProgressIndicator(),
              height: 20,
              width: 20,
            )
          : Icon(Icons.share),
      onPressed: () =>
          (widget.mediaType == MediaType.image) ? _shareImage() : _shareVideo(),
    );
  }

  void _shareImage() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
      // Fetch Image
      http.Response response = await http.get(widget.mediaUrl);

      // Get Application path
      final String directory = (await getApplicationDocumentsDirectory()).path;
      final String fileDir = '$directory/apod_share.png';

      // Create new file, then write as bytes
      File imageFile = new File(fileDir);
      imageFile.writeAsBytesSync(response.bodyBytes);

      Share.shareFiles(
        [fileDir],
        subject: "NASA's Photo of the Day",
        text: "Check out this photo of ${widget.title} taken on ${widget.date}",
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _shareVideo() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
      Share.share(this.widget.mediaUrl, subject: "NASA's Photo of the Day");
      setState(() {
        _isLoading = false;
      });
    }
  }
}
