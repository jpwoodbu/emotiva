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
      }
    );
  }

  Widget _build(BuildContext context, emotiva.Device device) {
    // TODO - use something to automatically size the icons and position them
    // centrally. See
    // https://docs.flutter.dev/ui/layout/responsive/adaptive-responsive.
    const double iconSize = 100;
    return ListView(
      children: [
        SizedBox(height: 30),
        Table(
            children: <TableRow>[
              TableRow(
                children: [
                  Text(''),
                  IconButton(
                      onPressed: () => addHaptic(device.menuUp),
                      icon: Icon(Icons.keyboard_arrow_up, size: iconSize)),
                  Text(''),
                ],
              ),
              TableRow(
                children: [
                  IconButton(
                      onPressed: () => addHaptic(device.menuLeft),
                      icon: Icon(Icons.keyboard_arrow_left, size: iconSize)),
                  IconButton(
                      onPressed: () => addHaptic(device.menuEnter),
                      icon: Icon(Icons.circle_outlined, size: iconSize)),
                  IconButton(
                      onPressed: () => addHaptic(device.menuRight),
                      icon: Icon(Icons.keyboard_arrow_right, size: iconSize)),
                ],
              ),
              TableRow(
                children: [
                  Text(''),
                  IconButton(
                      onPressed: () => addHaptic(device.menuDown),
                      icon: Icon(Icons.keyboard_arrow_down, size: iconSize)),
                  Text(''),
                ],
              ),
              TableRow(
                children: [
                  IconButton(
                      onPressed: () => addHaptic(device.info),
                      icon: Icon(Icons.info, size: iconSize * 0.50)),
                  Text(''),
                  IconButton(
                      onPressed: () => addHaptic(device.toggleMenu),
                      icon: Icon(Icons.menu, size: iconSize * 0.50)),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
