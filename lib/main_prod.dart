import 'package:flutter/material.dart';
import 'package:pushup_bro/core/flavor.dart';
import 'package:pushup_bro/core/model/environment.dart';
import 'package:pushup_bro/main.dart';

void main() async {
  Flavor.setEnvironment(Environment.prod);
  runApp(const Main());
}
