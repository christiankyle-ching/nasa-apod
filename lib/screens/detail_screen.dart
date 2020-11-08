import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nasa_apod/models/apod_model.dart';
import 'package:nasa_apod/screens/media_screen.dart';
import 'package:nasa_apod/theme/theme.dart';
import 'package:nasa_apod/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

class DetailScreen extends StatelessWidget {
  static const String routeName = '/detail';

  final Future<Apod> futureApod;

  DetailScreen({Key key, this.futureApod}) : super(key: key);

  Widget _buildFromInstance(Apod apod) {
    // print('Detail Screen using instance of Apod');
    return Scaffold(
      body: ApodDetail(apod: apod),
    );
  }

  Widget _buildFromFuture(Future<Apod> apod) {
    // print('Detail Screen using a FutureBuilder of Apod');

    return FutureBuilder(
      future: apod,
      builder: (context, snapshot) {
        try {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return ApodDetail(apod: snapshot.data, noScaffold: true);
          }

          if (snapshot.hasError) {
            throw (snapshot.error);
          }
        } on SocketException catch (_) {
          showNoInternetError(context);
        } on Exception catch (_) {
          return Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                  'No Available APoD for ${DateFormat.yMMMMd().format(DateTime.now())} (today)'),
            ),
          );
        } catch (error) {
          return Center(
            child: Text('An unknown error has occured: $error'),
          );
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

class ApodDetail extends StatefulWidget {
  final Apod apod;
  final bool noScaffold;

  ApodDetail({@required this.apod, this.noScaffold = false});

  @override
  _ApodDetailState createState() => _ApodDetailState();
}

class _ApodDetailState extends State<ApodDetail> {
  ScrollController _scrollController;

  final double sidePadding = 24;
  bool isTitleExpanded = true;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  _scrollListener() {
    setState(() {
      isTitleExpanded = !(_scrollController.offset >= 120);
    });
  }

  @override
  Widget build(BuildContext context) {
    final FavoriteToggle _favoriteToggle = FavoriteToggle(apod: widget.apod);

    final ShareButton _shareButton = ShareButton(
      date: widget.apod.date,
      mediaType: widget.apod.mediaType,
      mediaUrl: widget.apod.url,
      title: widget.apod.title,
    );

    Widget _date = Row(
      children: [
        Expanded(
          child: Text(
            DateFormat.yMMMMd().format(widget.apod.date),
            style: appTheme.textTheme.headline6,
          ),
        ),
        if (widget.noScaffold) _favoriteToggle,
        if (widget.noScaffold) _shareButton,
      ],
    );

    Widget _title = Text(
      widget.apod.title,
      style: appTheme.textTheme.headline6.copyWith(
        shadows: textShadow,
      ),
      maxLines: (isTitleExpanded) ? null : 1,
      overflow: (isTitleExpanded) ? null : TextOverflow.ellipsis,
    );

    Widget _mediaPreview = GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, MediaScreen.routeName,
            arguments: widget.apod);
      },
      child: Hero(
        tag: 'apodMedia${widget.apod.title}',
        child: Container(
          constraints: BoxConstraints(
            maxHeight: imageMaxHeight,
            minHeight: imageMaxHeight,
          ),
          width: double.infinity,
          child: buildMediaPreview(
              context, widget.apod.mediaType, widget.apod.url),
        ),
      ),
    );

    TextStyle _copyrightTextStyle = appTheme.textTheme.subtitle1.copyWith(
      fontWeight: FontWeight.bold,
    );
    Widget _copyrightRow = Row(
      children: [
        Text(
          '${widget.apod.copyright} ',
          style: _copyrightTextStyle,
        ),
        Icon(
          Icons.copyright,
          size: _copyrightTextStyle.fontSize,
          color: _copyrightTextStyle.color,
        ),
      ],
    );

    Widget _explanation = Text(
      '${widget.apod.explanation}',
      style: appTheme.textTheme.bodyText1.copyWith(height: 1.5),
    );

    Widget _apodInformation = SliverList(
        delegate: SliverChildListDelegate(
      [
        Container(
          constraints: BoxConstraints(
              // FIX: SliverAppBar not stretching if content is short
              minHeight: MediaQuery.of(context).size.height - 225),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _date,
                SizedBox(height: 16),
                if (widget.apod.copyright.isNotEmpty) _copyrightRow,
                if (widget.apod.copyright.isNotEmpty) SizedBox(height: 16),
                Text('Explanation', style: appTheme.textTheme.subtitle2),
                Divider(),
                _explanation,
              ],
            ),
          ),
        )
      ],
    ));

    Widget mediaAppBar = SliverAppBar(
      leading: (widget.noScaffold) ? Container() : null,
      actions: (!widget.noScaffold) ? [_favoriteToggle, _shareButton] : [],
      elevation: 8.0,
      forceElevated: true,
      flexibleSpace: FlexibleSpaceBar(
        background: _mediaPreview,
        title: IgnorePointer(
          ignoring: true,
          child: _title,
        ),
        titlePadding: (widget.noScaffold)
            ? EdgeInsetsDirectional.only(start: 20, bottom: 16, end: 20)
            : EdgeInsetsDirectional.only(start: 54, bottom: 16, end: 82),
        stretchModes: [StretchMode.zoomBackground, StretchMode.fadeTitle],
        centerTitle: widget.noScaffold,
      ),
      expandedHeight: 225,
      floating: false,
      pinned: true,
      stretch: true,
      stretchTriggerOffset: 125,
      onStretchTrigger: () => _handleOnStretch(context, widget.apod),
    );

    return CustomScrollView(
      controller: _scrollController,
      physics: BouncingScrollPhysics(),
      slivers: <Widget>[
        mediaAppBar,
        _apodInformation,
      ],
    );
  }

  Future<void> _handleOnStretch(BuildContext context, Apod apod) async {
    await Future.delayed(Duration(microseconds: 1));

    try {
      if (apod.mediaType == MediaType.image)
        Navigator.pushNamed(context, MediaScreen.routeName, arguments: apod);
    } catch (_) {
      print('FAILED_PULL_MEDIA');
    }
  }
}

class FavoriteToggle extends StatelessWidget {
  final Apod apod;

  FavoriteToggle({@required this.apod});

  @override
  Widget build(BuildContext context) {
    return Consumer<ApodModel>(builder: (_, apodModel, __) {
      bool inFavorites = apodModel.favoriteApodDates.contains(apod.date);
      bool enabled = apodModel.loadedFavorites;

      return IconButton(
          icon: Icon((inFavorites) ? Icons.star : Icons.star_border),
          onPressed: (enabled)
              ? () {
                  removeAllSnackbars(context);
                  if (inFavorites) {
                    apodModel.removeFavorite(apod.date);
                    showSnackbar(context, 'Removed ${apod.title} to favorites');
                  } else {
                    apodModel.addFavorite(apod.date, apod);
                    showSnackbar(context, 'Added ${apod.title} to favorites');
                  }
                }
              : null,
          color: (inFavorites) ? Colors.yellow : null);
    });
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
