import 'package:flutter/material.dart';

// References
final Map<String, Color> _colors = {
  'primaryLight': _hexColor('7dadff'),
  'primary': _hexColor('0b3d91'),
  'primaryVariant': _hexColor('001862'),
  'secondary': _hexColor('fc3d21'),
  'secondaryVariant': _hexColor('c00000'),
  'error': _hexColor('c00000'),
  'textLight': _hexColor('ffffff'),
};

Color _hexColor(String hexCode) {
  int colorCode = int.parse('0xFF${hexCode.toUpperCase()}');
  return Color(colorCode);
}

final List<BoxShadow> textShadow = [
  BoxShadow(
    blurRadius: 3,
    color: Colors.black.withOpacity(0.8),
    offset: Offset(2, 2),
  ),
  BoxShadow(
    blurRadius: 5,
    color: Colors.black.withOpacity(0.5),
    offset: Offset(4, 4),
  )
];

// Shared Theme Options
final TextStyle titleStyle = appTheme.textTheme.headline5;
final double imageMaxHeight = 200.0;

// App-Wide Font Family
final TextTheme _baseTypography = Typography.whiteCupertino;

final ThemeData appTheme = ThemeData.dark().copyWith(
  // Colors
  primaryColor: _colors['primary'],
  accentColor: _colors['secondary'],
  scaffoldBackgroundColor: Colors.grey[900],
  dialogBackgroundColor: Colors.grey[900],

  // Themes
  cardTheme: CardTheme(
    color: _colors['primary'],
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: _colors['secondary'],
    textTheme: ButtonTextTheme.normal,
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: MaterialStateProperty.all(_colors['primaryLight']),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    contentTextStyle: Typography.englishLike2018.bodyText2.apply(
      color: Colors.white,
    ),
    backgroundColor: Colors.grey[850],
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.black,
    elevation: 0.0,
  ),
  appBarTheme: AppBarTheme(
    color: Colors.black,
    elevation: 0.0,
  ),

  // Font Geometry
  textTheme: _baseTypography.copyWith(
    headline1: _baseTypography.headline1.copyWith(
      fontSize: 96,
      fontWeight: FontWeight.w300,
      letterSpacing: -1.5,
    ),
    headline2: _baseTypography.headline2.copyWith(
      fontSize: 60,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.5,
    ),
    headline3: _baseTypography.headline3.copyWith(
      fontSize: 48,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.0,
    ),
    headline4: _baseTypography.headline4.copyWith(
      fontSize: 34,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.25,
    ),
    headline5: _baseTypography.headline5.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.0,
    ),
    headline6: _baseTypography.headline6.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    subtitle1: _baseTypography.subtitle1.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.15,
    ),
    subtitle2: _baseTypography.subtitle2.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    bodyText1: _baseTypography.bodyText1.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.5,
    ),
    bodyText2: _baseTypography.bodyText2.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.25,
    ),
    button: _baseTypography.button.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.25,
    ),
    caption: _baseTypography.caption.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.4,
    ),
    overline: _baseTypography.overline.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.normal,
      letterSpacing: 1.5,
    ),
  ),
);
