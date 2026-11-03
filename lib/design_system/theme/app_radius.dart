import 'package:flutter/widgets.dart';

abstract final class AppRadius {
  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
  static const double extraLarge = 32;
  static const double pill = 999;
  static const control = BorderRadius.all(Radius.circular(medium));
  static const card = BorderRadius.all(Radius.circular(large));
  static const hero = BorderRadius.all(Radius.circular(extraLarge));
}
