import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nasa_apod/models/apod_model.dart';
import 'package:nasa_apod/theme/theme.dart';
import 'package:nasa_apod/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

class DetailScreen extends StatelessWidget {
  static const String routeName = '/detail';

  final Future<Apod> futureApod;

  DetailScreen({Key key, this.futureApod}) : super(key: key);

  Widget _buildFromInstance(Apod apod) {
    print('Detail Screen using instance of Apod');
    return Scaffold(
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

class ApodDetail extends StatelessWidget {
  final Apod apod;
  final bool noScaffold;
  final double sidePadding = 24;

  ApodDetail({@required this.apod, this.noScaffold = false});

  Widget _mediaAppBar(Widget title, Widget mediaPreview, Widget favoriteToggle,
      Widget shareButton) {
    return SliverAppBar(
      leading: (noScaffold) ? Container() : null,
      actions: (!noScaffold) ? [favoriteToggle, shareButton] : [],
      flexibleSpace: FlexibleSpaceBar(
        background: mediaPreview,
        title: IgnorePointer(ignoring: true, child: SafeArea(child: title)),
        titlePadding:
            EdgeInsetsDirectional.only(start: 54, bottom: 16, end: 82),
        stretchModes: [StretchMode.zoomBackground, StretchMode.fadeTitle],
      ),
      expandedHeight: 225,
      floating: false,
      pinned: true,
      stretch: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final FavoriteToggle _favoriteToggle = FavoriteToggle(apod: apod);

    final ShareButton _shareButton = ShareButton(
      date: apod.date,
      mediaType: apod.mediaType,
      mediaUrl: apod.url,
      title: apod.title,
    );

    Widget _title = Text(apod.title, style: appTheme.textTheme.headline6);

    Widget _date = Padding(
        padding: EdgeInsets.symmetric(horizontal: sidePadding),
        child: Row(
          children: [
            Expanded(
              child: Text(
                DateFormat.yMMMMd().format(apod.date),
                style: appTheme.textTheme.headline6,
              ),
            ),
            if (noScaffold) _favoriteToggle,
            if (noScaffold) _shareButton,
          ],
        ));

    TextStyle _copyrightTextStyle =
        appTheme.textTheme.subtitle1.copyWith(fontWeight: FontWeight.bold);
    Widget _copyrightRow = Padding(
      padding: EdgeInsets.symmetric(horizontal: sidePadding),
      child: Row(
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
      ),
    );

    Widget _description = Padding(
      padding: EdgeInsets.symmetric(horizontal: sidePadding),
      child: Text(
        '${apod.explanation}',
        style: appTheme.textTheme.bodyText1.copyWith(height: 1.5),
      ),
    );

    Widget _mediaPreview = GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, MediaScreen.routeName, arguments: apod);
      },
      child: Hero(
        tag: 'apodMedia${apod.title}',
        child: Container(
          constraints: BoxConstraints(
            maxHeight: imageMaxHeight,
            minHeight: imageMaxHeight,
          ),
          width: double.infinity,
          child: buildMediaPreview(context, apod.mediaType, apod.url),
        ),
      ),
    );

    Widget _apodInformation = SliverList(
      delegate: SliverChildListDelegate([
        SizedBox(height: 24),
        _date,
        SizedBox(height: 16),
        if (apod.copyright.isNotEmpty) _copyrightRow,
        if (apod.copyright.isNotEmpty) SizedBox(height: 16),
        _description,
        SizedBox(height: 24),
      ]),
    );

    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: <Widget>[
        _mediaAppBar(_title, _mediaPreview, _favoriteToggle, _shareButton),
        _apodInformation,
      ],
    );
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

class MediaScreen extends StatelessWidget {
  static const String routeName = '/detail/media';

  @override
  Widget build(BuildContext context) {
    final Apod apod = ModalRoute.of(context).settings.arguments;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Scaffold(
          body: Container(
        child: Center(
          child: Hero(
              tag: 'apodMedia${apod.title}',
              child: buildMediaPreview(context, apod.mediaType, apod.url)),
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

      try {
        String fileDir = await cacheImage(widget.mediaUrl, 'share.png');

        Share.shareFiles(
          [fileDir],
          subject: "NASA's Photo of the Day",
          text:
              "Check out this photo of ${widget.title} taken on ${widget.date}",
        );
      } catch (_) {}

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
