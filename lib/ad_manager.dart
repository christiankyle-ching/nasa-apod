import 'dart:io';

String testID = "ca-app-pub-3940256099942544~4354546703";
String testInterID = "ca-app-pub-3940256099942544/7049598008";

String appID = "ca-app-pub-1880918445827744~7516812574";
String appInterID = "ca-app-pub-1880918445827744/1357215445";
String appBannerID = "ca-app-pub-1880918445827744/5753973067";

class AdManager {
  static String get appId {
    if (Platform.isAndroid) {
      return appID;
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return appInterID;
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return appBannerID;
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }
}
