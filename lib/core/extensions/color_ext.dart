import 'package:flutter/cupertino.dart';

extension ColorExtensions on Color {
  Color darken(int amount) {
    int channel(double value) =>
        ((value * 255.0).round() - amount).clamp(0, 255);

    return Color.fromRGBO(channel(r), channel(g), channel(b), a);
  }
}
