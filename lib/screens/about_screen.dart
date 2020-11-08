import 'package:flutter/material.dart';
import 'package:nasa_apod/theme/theme.dart';
import 'package:nasa_apod/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  static const String routeName = '/about';

  final String githubUrl = 'https://github.com/christiankyle-ching/';
  final String webUrl = 'https://christiankyleching.now.sh';
  final String githubRepoUrl =
      'https://github.com/christiankyle-ching/nasa-apod';

  Widget appDeveloperLinks(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Image.asset(
            'images/icons/github.png',
            height: 22,
            width: 22,
          ),
          onPressed: () => launchUrl(context, githubUrl),
        ),
        IconButton(
          icon: Icon(Icons.language),
          onPressed: () => launchUrl(context, webUrl),
        ),
      ],
    );
  }

  Widget githubFooter(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Liked it? Consider giving a', style: footerStyle),
        FlatButton(
          padding: EdgeInsets.symmetric(horizontal: 8),
          onPressed: () => launchUrl(context, githubRepoUrl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.star), Text(' on Github')],
          ),
        ),
      ],
    );
  }

  final TextStyle footerStyle = appTheme.textTheme.subtitle2;

  @override
  Widget build(BuildContext context) {
    // App-related Information
    final Widget appLogo = SizedBox(
      height: appTheme.textTheme.headline1.fontSize,
      child: Image.asset('images/icons/logo.png'),
    );
    final Widget appTitle = Text(
      "NASA's Astronomy Picture of the Day",
      style: appTheme.textTheme.headline6,
      textAlign: TextAlign.center,
    );
    final Widget appDescription = Text(
      "A simple application showcasing NASA's everyday imagery of space and beyond",
      style: appTheme.textTheme.subtitle1,
      textAlign: TextAlign.center,
    );
    final Widget appDeveloper = Column(
      children: [
        Text(
          "Developed by",
          style: appTheme.textTheme.subtitle2.copyWith(
            fontWeight: FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4),
        Text(
          "Christian Kyle Ching",
          style: appTheme.textTheme.subtitle1.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    // Footer Widgets
    final Widget flutterFooter = GestureDetector(
      onTap: () => launchUrl(context, 'https://flutter.dev/'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Built with Flutter\u2122 ', style: footerStyle),
          Image.asset(
            'images/icons/flutter.png',
            height: footerStyle.fontSize,
          )
        ],
      ),
    );
    Widget flutterDisclaimer = Text(
      'Flutter and the related logo are trademarks of Google LLC. We are not endorsed by or affiliated with Google LLC.',
      textAlign: TextAlign.center,
      style: footerStyle.copyWith(
        fontSize: 8,
        fontWeight: FontWeight.normal,
        color: Colors.white70,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    appLogo,
                    SizedBox(height: 32),
                    appTitle,
                    SizedBox(height: 8),
                    appDescription,
                    SizedBox(height: 32),
                    appDeveloper,
                    appDeveloperLinks(context),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 0),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                flutterFooter,
                SizedBox(height: 8),
                // githubFooter(context),
                flutterDisclaimer,
              ],
            ),
          )
        ],
      ),
    );
  }
}
