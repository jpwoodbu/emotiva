import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

dynamic addHaptic(Function function) {
  HapticFeedback.lightImpact();
  return function();
}

Widget menuWarning(BuildContext context) {
  final errorColor = Theme.of(context).colorScheme.error;
  return Column(children: [
    Icon(Icons.warning, color: errorColor),
    Text(
      'Many settings cannot be changed while the OSD menu is active.',
      style: TextStyle(fontWeight: FontWeight.bold, color: errorColor),
    ),
    SizedBox(height: 10),
  ]);
}
