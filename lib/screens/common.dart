import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nasa_apod/models/api.dart';
import 'package:nasa_apod/models/apod_model.dart';
import 'package:nasa_apod/theme/theme.dart';
import 'package:nasa_apod/utils/utils.dart';
import 'package:provider/provider.dart';

import 'detail_screen.dart';

// Apod Items Related Widgets
class ApodListView extends StatefulWidget {
  final bool willLoadFavorites;

  ApodListView({Key key, @required this.willLoadFavorites}) : super(key: key);

  @override
  _ApodListViewState createState() => _ApodListViewState();
}

class _ApodListViewState extends State<ApodListView> {
  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  void _startLoading() {
    String message = (widget.willLoadFavorites)
        ? 'Loading your favorites. Please wait...'
        : 'Loading next ${ApodApi.itemPerPage} photos. Please wait...';
    showSnackbar(context, message, duration: 1000);
  }

  void _endLoading() {
    removeAllSnackbars(context);
  }

  void _scrollListener() async {
    // If reached the bottom, then fetch more items
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      print('Reached the end of the list');

      _startLoading();
      try {
        await Provider.of<ApodModel>(context, listen: false).fetchNextApods();
      } on SocketException catch (_) {
        return showNoInternetError(context);
      } catch (error) {
        showSnackbar(context, 'Unknown error occured: $error');
      }
      _endLoading();
    }
  }

  Widget _buildFavoritesList(BuildContext context) {
    return Consumer<ApodModel>(
      builder: (_, apodModel, __) {
        if (!apodModel.loadedFavorites) {
          _startLoading();
          return Container(); // return nothing, but show snackbar
        } else {
          _endLoading();
        }

        if (apodModel.favoriteApodDates.length <= 0) {
          return Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                      text: "You haven't seem to have any favorites yet.\n"),
                  TextSpan(text: "Tap on the "),
                  WidgetSpan(child: Icon(Icons.star, color: Colors.yellow)),
                  TextSpan(text: " to add one!"),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
            itemCount: apodModel.favoriteApods.length,
            itemBuilder: (context, index) =>
                ApodTile(apod: apodModel.favoriteApods[index]));
      },
    );
  }

  Widget _buildInfiniteList(BuildContext context) {
    return Consumer<ApodModel>(
      builder: (_, apodModel, __) {
        if (apodModel.listOfApods.length <= 0) {
          _startLoading();
          try {
            apodModel.fetchNextApods().catchError((Object error) {
              showNoInternetError(context);
            }).whenComplete(() => _endLoading());
            // return Container();
          } catch (error) {
            showSnackbar(context, 'Unknown error occured: $error');
          }
        }

        return ListView.builder(
            controller: _scrollController,
            itemCount: apodModel.listOfApods.length,
            itemBuilder: (context, index) =>
                ApodTile(apod: apodModel.listOfApods[index]));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.willLoadFavorites) {
      return _buildFavoritesList(context);
    } else {
      return _buildInfiniteList(context);
    }
  }
}

class ApodTile extends StatelessWidget {
  final Apod apod;

  ApodTile({Key key, @required this.apod}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      String strDate = DateFormat.yMMMMd().format(apod.date);

      return GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, DetailScreen.routeName, arguments: apod);
        },
        child: Container(
          constraints: BoxConstraints(
            minHeight: imageMaxHeight,
            maxHeight: imageMaxHeight,
          ),
          child: Stack(
            children: [
              // Background Image / Video
              Hero(
                tag: 'apodMedia${apod.title}',
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  foregroundDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black, Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: buildMediaPreview(context, apod.mediaType, apod.url),
                ),
              ),
              // Title & Date (Header)
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Text(strDate, style: appTheme.textTheme.subtitle1),
                    SizedBox(
                      height: 8,
                    ),
                    // Title
                    Hero(
                      tag: apod.title,
                      child: Text(
                        apod.title,
                        style: titleStyle,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    } catch (err) {
      return Container();
    }
  }
}
