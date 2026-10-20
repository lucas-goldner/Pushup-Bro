import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherProvider {
  UrlLauncherProvider(this.urlLauncherService);
  final UrlLauncherService urlLauncherService;

  Future<void> launchUri(Uri url) async {
    final urlLaunched = await urlLauncherService.launch(url);
    if (!urlLaunched) throw Exception('Could not launch $url');
  }
}

@visibleForTesting
class UrlLauncherService {
  const UrlLauncherService();

  Future<bool> launch(Uri uri) => launchUrl(uri);

  Future<bool> canLaunch(Uri uri) => canLaunchUrl(uri);
}
