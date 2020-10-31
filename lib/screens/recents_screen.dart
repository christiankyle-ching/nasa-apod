import 'package:flutter/material.dart';

import 'common.dart';

class RecentsScreen extends StatelessWidget {
  static const String routeName = '/home';

  RecentsScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ApodListView(
      key: ValueKey('recentsList'),
      willLoadFavorites: false,
    );
  }
}
