import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

class MenuPage extends StatelessWidget {
  final emotiva.Device device;
  const MenuPage(this.device, {super.key});

  void addHaptic(Function function) {
    HapticFeedback.lightImpact();
    function();
  }

  @override
  Widget build(BuildContext context) {
    const double iconSize = 130;
    return Center(
      child: Table(
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
    );
  }
}
