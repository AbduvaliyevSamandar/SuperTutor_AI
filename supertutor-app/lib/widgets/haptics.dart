import 'package:flutter/services.dart';

class Haptics {
  Haptics._();
  static void tap() => HapticFeedback.selectionClick();
  static void success() => HapticFeedback.lightImpact();
  static void error() => HapticFeedback.heavyImpact();
}
