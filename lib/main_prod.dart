import 'package:flutter/material.dart';
import 'package:pushup_bro/core/flavor.dart';
import 'package:pushup_bro/core/model/environment.dart';
import 'package:pushup_bro/features/social/social_setup.dart';
import 'package:pushup_bro/main.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Flavor.setEnvironment(Environment.prod);
  final social = await createSocialBackend(dev: false);
  runApp(Main(social: social));
}
