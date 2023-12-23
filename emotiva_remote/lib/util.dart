import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

dynamic addHaptic(Function function) {
  HapticFeedback.lightImpact();
  return function();
}

Widget menuWarning(BuildContext context) {
  final errorColor = Theme.of(context).colorScheme.error;
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.warning, color: errorColor),
      const SizedBox(width: 15.0),
      Flexible(
        child: Text(
          'Many settings cannot be changed while the OSD menu is active.',
          style: TextStyle(fontWeight: FontWeight.bold, color: errorColor),
        ),
      ),
    ],
  );
}
