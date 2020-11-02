import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nasa_apod/models/api.dart';
import 'package:nasa_apod/models/apod_model.dart';
import 'package:nasa_apod/models/app_storage.dart';
import 'package:nasa_apod/screens/recents_screen.dart';
import 'package:nasa_apod/utils/utils.dart';
import 'package:provider/provider.dart';

import 'detail_screen.dart';
import 'favorites_screen.dart';

// Global Widgets
class AppScaffold extends StatefulWidget {
  static const String routeName = '/';

  @override
  _AppScaffoldState createState() => _AppScaffoldState();
}

class DailyWallpaperSetting extends StatefulWidget {
  DailyWallpaperSetting({Key key});

  @override
  _DailyWallpaperSettingState createState() => _DailyWallpaperSettingState();
}

class _DailyWallpaperSettingState extends State<DailyWallpaperSetting> {
  bool value = false;
  bool enabled = false;

  @override
  void initState() {
    super.initState();
    initValue();
  }

  void initValue() async {
    bool setting = await AppStorage.getDynamicWallpaper();
    setState(() {
      value = setting;
      enabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text('Daily Wallpaper?'),
      value: value,
      onChanged: (enabled)
          ? (bool newValue) async {
              if (newValue) {
                bool chosenValue = await showDialog(
                    context: context,
                    barrierDismissible: false,
                    child: AlertDialog(
                      actions: [
                        FlatButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: Text('Cancel'),
                        ),
                        RaisedButton(
                          onPressed: () {
                            AppStorage.setDynamicWallpaper(newValue);
                            Navigator.pop(context, true);
                          },
                          child: Text('OK'),
                        ),
                      ],
                      content: Text(
                        'This setting will update your wallpaper everyday (starting this day) if it is a photo from NASA.\n\nDo you want to continue?',
                      ),
                    ));

                setState(() {
                  value = chosenValue;
                });
              } else {
                AppStorage.setDynamicWallpaper(newValue);
                setState(() {
                  value = newValue;
                });
              }
            }
          : null,
    );
  }
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentTab;
  DateTime _lastSelectedDate;

  final PageStorageBucket _bucket = PageStorageBucket();
  List<Widget> _bodyWidgets;
  Widget firstPage, secondPage, thirdPage;

  Future<Apod> _futureHighlightApod;

  @override
  void initState() {
    super.initState();

    _futureHighlightApod = ApodApi.fetchApodByDate(DateTime.now());

    // Init Pages
    try {
      firstPage = DetailScreen(
        key: PageStorageKey('firstPage'),
        futureApod: _futureHighlightApod,
      );
      secondPage = RecentsScreen(key: PageStorageKey('secondPage'));
      thirdPage = FavoritesScreen(key: PageStorageKey('thirdPage'));
    } on SocketException catch (_) {
      showNoInternetError(context);
    } catch (error) {
      showSnackbar(context, 'Unknown error occured: $error');
    }

    // Init Body Widgets
    _bodyWidgets = <Widget>[firstPage, secondPage, thirdPage];

    _lastSelectedDate = DateTime.now();
    _currentTab = 0;
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentTab = index;
    });
  }

  void _showJumpToDateDialog(BuildContext context) async {
    DateTime _dateToLoad = await showDatePicker(
      context: context,
      initialDate: _lastSelectedDate,
      firstDate: ApodApi.dateRange.start,
      lastDate: ApodApi.dateRange.end,
      helpText: 'Jump to date',
    );

    if (_dateToLoad != null) {
      try {
        setState(() {
          _futureHighlightApod = ApodApi.fetchApodByDate(_dateToLoad);
          _bodyWidgets[0] = DetailScreen(futureApod: _futureHighlightApod);

          _lastSelectedDate = _dateToLoad;
        });
      } on SocketException catch (_) {
        showNoInternetError(context);
      } catch (error) {
        showSnackbar(context, 'Unknown error occured: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Side-bar Navigation
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text("NASA's Astronomy Picture of the Day"),
            ),
            DailyWallpaperSetting(key: ValueKey('dailyWallpaperSetting')),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/about');
              },
            ),
          ],
        ),
      ),

      // App Bar
      appBar: AppBar(
        title: Text("NASA's APoD"),
        centerTitle: true,
        actions: [
          // If in favorites screen, show option to clear favorites
          if (_currentTab == 0)
            IconButton(
              icon: Icon(Icons.today),
              onPressed: () => _showJumpToDateDialog(context),
            ),
          if (_currentTab == 2) ClearFavoritesAction(),
        ],
      ),

      // Dynamic Body Element
      body: PageStorage(
        child: _bodyWidgets[_currentTab],
        bucket: _bucket,
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Today",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list),
            label: 'Recent',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
        currentIndex: _currentTab,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ClearFavoritesAction extends StatelessWidget {
  const ClearFavoritesAction({
    Key key,
  }) : super(key: key);

  void _showAlertDialog(BuildContext context) async {
    dynamic result = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('Are you sure you want to delete all favorites?'),
            actions: [
              TextButton(
                child: Text('No'),
                onPressed: () => Navigator.pop(context, {'action': null}),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: RaisedButton(
                  child: Text('Delete All'),
                  onPressed: () {
                    Provider.of<ApodModel>(context, listen: false)
                        .clearFavorites();
                    Navigator.pop(context, {'action': 'deleted'});
                  },
                ),
              )
            ],
          );
        });

    // Show snackbar only when deleted
    if (result['action'] == 'deleted')
      showSnackbar(context, 'Cleared favorites');
  }

  @override
  Widget build(BuildContext context) {
    int _favoritesLength = context.watch<ApodModel>().favoriteApodDates.length;

    return IconButton(
      icon: Icon(Icons.delete_sweep),
      onPressed:
          (_favoritesLength > 0) ? () => _showAlertDialog(context) : null,
    );
  }
}
