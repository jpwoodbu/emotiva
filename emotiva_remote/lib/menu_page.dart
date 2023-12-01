import 'dart:math';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

import 'device_changes.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  void addHaptic(Function function) {
    HapticFeedback.lightImpact();
    function();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
        builder: (BuildContext context, DeviceChanges deviceChanges, child) {
      return _build(context, deviceChanges.device);
    });
  }

  Widget _build(BuildContext context, emotiva.Device device) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints boxConstraints) {
      const double scalingFactor = 4.5;
      final double iconSize = min<double>(
          boxConstraints.maxHeight / scalingFactor,
          boxConstraints.maxWidth / scalingFactor);
      return Center(
        child: Table(
          defaultColumnWidth: IntrinsicColumnWidth(),
          children: <TableRow>[
            TableRow(
              children: [
                Text(''),
                IconButton(
                    onPressed: () => addHaptic(device.menuUp),
                    tooltip: 'Up',
                    icon: Icon(Icons.keyboard_arrow_up, size: iconSize)),
                Text(''),
              ],
            ),
            TableRow(
              children: [
                IconButton(
                    onPressed: () => addHaptic(device.menuLeft),
                    tooltip: 'Left',
                    icon: Icon(Icons.keyboard_arrow_left, size: iconSize)),
                IconButton(
                    onPressed: () => addHaptic(device.menuEnter),
                    tooltip: 'Enter',
                    icon: Icon(Icons.circle_outlined, size: iconSize)),
                IconButton(
                    tooltip: 'Right',
                    onPressed: () => addHaptic(device.menuRight),
                    icon: Icon(Icons.keyboard_arrow_right, size: iconSize)),
              ],
            ),
            TableRow(
              children: [
                Text(''),
                IconButton(
                    onPressed: () => addHaptic(device.menuDown),
                    tooltip: 'Down',
                    icon: Icon(Icons.keyboard_arrow_down, size: iconSize)),
                Text(''),
              ],
            ),
            TableRow(
              children: [
                IconButton(
                    onPressed: () => addHaptic(device.info),
                    tooltip: 'Show on screen display info table',
                    icon: Icon(Icons.info, size: iconSize * 0.50)),
                Text(''),
                IconButton(
                    onPressed: () => addHaptic(device.toggleMenu),
                    tooltip: 'Toggles entering and exiting the Emotiva menu',
                    icon: Icon(Icons.menu, size: iconSize * 0.50)),
              ],
            ),
          ],
        ),
      );
    });
  }
}
