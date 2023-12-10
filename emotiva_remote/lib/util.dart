import 'package:flutter/services.dart';

dynamic addHaptic(Function function) {
  HapticFeedback.lightImpact();
  return function();
}
