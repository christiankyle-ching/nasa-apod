import 'package:flutter/material.dart';
import 'package:nasa_apod/theme/theme.dart';
import 'package:nasa_apod/utils/utils.dart';

class AboutScreen extends StatelessWidget {
  static const String routeName = '/about';

  final String githubUrl = 'https://github.com/christiankyle-ching/';
  final String webUrl = 'https://christiankyleching.now.sh';
  final String githubRepoUrl =
      'https://github.com/christiankyle-ching/nasa-apod';

  Widget appDeveloperLinks(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.ac_unit),
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
    final Widget flutterFooter = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Powered with Flutter ', style: footerStyle),
        Icon(Icons.ac_unit),
      ],
    );

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
    final Widget appDeveloper = Text(
      "Developed by Christian Kyle Ching",
      style: appTheme.textTheme.subtitle2,
      textAlign: TextAlign.center,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    appLogo,
                    SizedBox(height: 32),
                    appTitle,
                    SizedBox(height: 8),
                    appDescription,
                    SizedBox(height: 32),
                    appDeveloper,
                    SizedBox(height: 8),
                    appDeveloperLinks(context),
                  ],
                ),
              ),
            ),
            flutterFooter,
            githubFooter(context),
          ],
        ),
      ),
    );
  }
}
