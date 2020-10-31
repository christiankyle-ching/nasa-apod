import 'package:flutter/material.dart';
import 'common.dart';

class FavoritesScreen extends StatelessWidget {
  static const String routeName = '/favorites';

  FavoritesScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ApodListView(
      key: ValueKey('favoritesList'),
      willLoadFavorites: true,
    );
  }
}
