import 'dart:io';

import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:nasa_apod/models/api.dart';
import 'package:nasa_apod/models/apod_model.dart';
import 'package:nasa_apod/models/app_storage.dart';
import 'package:nasa_apod/screens/recents_screen.dart';
import 'package:nasa_apod/theme/theme.dart';
import 'package:nasa_apod/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:wallpaper_manager/wallpaper_manager.dart';

import '../ad_manager.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';

// Settings
class DailyWallpaperSetting extends StatefulWidget {
  DailyWallpaperSetting({Key key}) : super(key: key);

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
    value = await AppStorage.getDynamicWallpaper();
    setState(() {
      enabled = true;
    });
  }

  void _onValueChanged(bool newValue) async {
    double screenRatio = getScreenRatio(context);

    if (newValue) {
      bool chosenValue = await showDialog(
          context: context,
          barrierDismissible: false,
          child: AlertDialog(
            title: Text('Enable Daily Wallpaper?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: Text('Cancel'),
              ),
              RaisedButton(
                onPressed: () {
                  AppStorage.setDynamicWallpaper(newValue, screenRatio);
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
      AppStorage.setDynamicWallpaper(newValue, screenRatio);
      setState(() {
        value = newValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text('Daily Wallpaper'),
      subtitle: Text(
        ApodApi.getNextUpdateTimeString(),
      ),
      value: value,
      onChanged: (enabled) ? _onValueChanged : null,
    );
  }
}

class UseHDForDownloadsSetting extends StatefulWidget {
  @override
  _UseHDForDownloadsSettingState createState() =>
      _UseHDForDownloadsSettingState();
}

class _UseHDForDownloadsSettingState extends State<UseHDForDownloadsSetting> {
  bool value = false;
  bool enabled = false;

  @override
  void initState() {
    super.initState();
    initValue();
  }

  void initValue() async {
    value = await AppStorage.getHdSetting();
    setState(() {
      enabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: (enabled)
          ? (newValue) {
              AppStorage.setHdSetting(newValue);
              setState(() {
                value = newValue;
              });
            }
          : null,
      title: Text('HD Wallpapers'),
      subtitle: Text('Uses more data'),
    );
  }
}

class DailyWallpaperLocationSetting extends StatefulWidget {
  @override
  _DailyWallpaperLocationSettingState createState() =>
      _DailyWallpaperLocationSettingState();
}

class _DailyWallpaperLocationSettingState
    extends State<DailyWallpaperLocationSetting> {
  int _value = WallpaperManager.HOME_SCREEN;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    initValue();
  }

  void initValue() async {
    _value = await AppStorage.getDailyWallpaperLocation();
    setState(() {
      _enabled = true;
    });
  }

  void _onChanged(int newValue) {
    try {
      AppStorage.setDailyWallpaperLocation(newValue);
      String location = 'to ';
      switch (newValue) {
        case WallpaperManager.HOME_SCREEN:
          location += 'home screen';
          break;
        case WallpaperManager.LOCK_SCREEN:
          location += 'lock screen';
          break;
        case WallpaperManager.BOTH_SCREENS:
          location += 'both home and lock screens';
          break;
        default:
          location = '';
      }
      showSnackbar(context, 'Daily wallpapers location is updated $location.');
      setState(() {
        _value = newValue;
      });
    } catch (err) {
      showSnackbar(context, 'Error in changing daily wallpaper location.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          onChanged: (_enabled) ? _onChanged : null,
          value: _value,
          items: [
            DropdownMenuItem(
              child: Text('Home Screen'),
              value: WallpaperManager.HOME_SCREEN,
            ),
            DropdownMenuItem(
              child: Text('Lock Screen'),
              value: WallpaperManager.LOCK_SCREEN,
            ),
            DropdownMenuItem(
              child: Text('Both Screen'),
              value: WallpaperManager.BOTH_SCREENS,
            ),
          ],
        ),
      ),
    );
  }
}

// Global Widgets
class AppScaffold extends StatefulWidget {
  static const String routeName = '/';

  @override
  _AppScaffoldState createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentTab;
  DateTime _lastSelectedDate;

  final PageStorageBucket _bucket = PageStorageBucket();
  List<Widget> _bodyWidgets;
  Widget firstPage, secondPage, thirdPage;

  Future<Apod> _futureHighlightApod;

  // InterstitialAd
  InterstitialAd _interstitialAd;
  bool _isInterstitialAdReady;

  void _initInterstitialAd() {
    _isInterstitialAdReady = false;

    _interstitialAd = InterstitialAd(
      adUnitId: AdManager.interstitialAdUnitId,
      listener: _onInterstitialAdEvent,
    );
  }

  void _loadInterstitialAd() {
    _interstitialAd.load();
  }

  void _onInterstitialAdEvent(MobileAdEvent event) {
    switch (event) {
      case MobileAdEvent.loaded:
        _isInterstitialAdReady = true;
        break;
      case MobileAdEvent.failedToLoad:
        _isInterstitialAdReady = false;
        print('Failed to load an interstitial ad');
        break;
      case MobileAdEvent.closed:
        // _loadInterstitialAd();
        // _isInterstitialAdReady = false;
        break;
      default:
      // do nothing
    }
  }

  // BannerAd
  BannerAd _bannerAd;

  void _initBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: AdSize.banner,
    );

    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd
      ..load()
      ..show(anchorType: AnchorType.bottom);
  }

  @override
  void initState() {
    super.initState();

    // TODO: Interstitial Ads - can be activated in the future
    _initInterstitialAd();
    // _loadInterstitialAd();

    _initBannerAd();

    // Init Pages
    try {
      _futureHighlightApod = ApodApi.fetchApodByDate(DateTime.now());

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
    if (_isInterstitialAdReady) _interstitialAd.show();

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
            AppDrawerHeader(),
            DrawerSectionTitle('Settings'),
            DailyWallpaperSetting(
              key: ValueKey('dailyWallpaperSetting'),
            ),
            UseHDForDownloadsSetting(),
            DrawerSectionTitle(
              'Daily Wallpaper Location',
              noDivider: true,
            ),
            DailyWallpaperLocationSetting(),
            DrawerSectionTitle('Other'),
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

  @override
  void dispose() {
    _interstitialAd.dispose();
    _bannerAd.dispose();

    super.dispose();
  }
}

class DrawerSectionTitle extends StatelessWidget {
  final String title;
  final bool noDivider;

  DrawerSectionTitle(this.title, {this.noDivider = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8),
          child: Text(
            title,
            style: appTheme.textTheme.subtitle2.copyWith(
              color: Colors.white70,
            ),
          ),
        ),
        if (!noDivider) Divider(),
      ],
    );
  }
}

class AppDrawerHeader extends StatelessWidget {
  const AppDrawerHeader({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        image: DecorationImage(
          colorFilter: new ColorFilter.mode(
              Colors.black.withOpacity(0.35), BlendMode.dstATop),
          fit: BoxFit.cover,
          image: AssetImage('images/icons/logo.png'),
        ),
      ),
      child: Center(
        child: Text(
          "NASA's Astronomy Picture of the Day",
          style: appTheme.textTheme.headline5
              .copyWith(fontWeight: FontWeight.bold),
        ),
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
