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

  Widget _arrowWidget(emotiva.Arrow arrowType, double size) {
    IconData icon;
    var alignment = Alignment.centerLeft;
    switch (arrowType) {
      case emotiva.Arrow.up:
        icon = Icons.keyboard_arrow_up;
        break;
      case emotiva.Arrow.down:
        icon = Icons.keyboard_arrow_down;
        break;
      case emotiva.Arrow.left:
        icon = Icons.keyboard_arrow_left;
        break;
      case emotiva.Arrow.right:
        icon = Icons.keyboard_arrow_right;
        alignment = Alignment.centerRight;
        break;
      default:
        icon = Icons.error;
        break;
    }
    return Container(alignment: alignment, child: Icon(icon, size: size));
  }

  List<Widget> _row(BuildContext context, emotiva.Device device, int rowIndex) {
    const inset = 2.0;
    const arrowSize = 25.0;
    final leftArrowPosition =
        _arrowPosition(device.menuContents, emotiva.Arrow.left);
    final rightArrowPosition =
        _arrowPosition(device.menuContents, emotiva.Arrow.right);
    // Leave space for a potential arrow.
    List<Widget> columns = [SizedBox(width: arrowSize)];
    if (rowIndex == leftArrowPosition) {
      columns[0] = _arrowWidget(emotiva.Arrow.left, arrowSize);
    }
    for (final column in device.menuContents.rows[rowIndex].columns) {
      if (column.checkbox ?? false) {
        if (column.value == 'true') {
          columns.add(
            Container(
              margin: EdgeInsets.all(inset),
              padding: EdgeInsets.all(inset),
              alignment: Alignment.centerLeft,
              child: Icon(Icons.disabled_by_default_outlined),
            ),
          );
        } else {
          columns.add(
            Container(
              margin: EdgeInsets.all(inset),
              padding: EdgeInsets.all(inset),
              alignment: Alignment.centerLeft,
              child: Icon(Icons.check_box_outline_blank),
            ),
          );
        }
      } else {
        // TODO - fixed width and offset features. This might require including
        // fonts from Google Fonts in my assets.
        const fontSize = 16.0;
        const fontWeight = FontWeight.bold;
        Color? color;
        Color? backgroundColor;
        if (column.highlight) {
          color = Colors.black;
          backgroundColor = Colors.white;
        }
        columns.add(
          Container(
            margin: EdgeInsets.all(inset),
            padding: EdgeInsets.all(inset),
            color: backgroundColor,
            child: Text(
              column.value,
              style: TextStyle(
                fontWeight: fontWeight,
                fontSize: fontSize,
                color: color,
              ),
            ),
          ),
        );
      }
    }
    if (rowIndex == rightArrowPosition) {
      columns.add(_arrowWidget(emotiva.Arrow.right, arrowSize));
    } else {
      columns.add(SizedBox(width: arrowSize));
    }
    return columns;
  }

  // TODO - Should this function be in the emotiva module?
  int _arrowPosition(emotiva.Menu menu, emotiva.Arrow arrowType) {
    for (final row in menu.rows) {
      for (final column in row.columns) {
        switch (arrowType) {
          case emotiva.Arrow.up || emotiva.Arrow.down:
            if (column.arrow == arrowType) return column.number;
            break;
          case emotiva.Arrow.left || emotiva.Arrow.right:
            if (column.arrow == arrowType) return row.number;
            break;
          default:
            break;
        }
      }
    }
    return -1;
  }

  TableRow _verticleArrow(emotiva.Menu menu, emotiva.Arrow arrowType) {
    const height = 25.0;
    final arrowPosition = _arrowPosition(menu, arrowType);
    final List<Widget> children = [SizedBox(width: 25.0)];
    for (int i = 0; i < 4; i++) {
      if (arrowPosition == i) {
        children.add(_arrowWidget(arrowType, height));
      } else {
        // Setting this height makes sure the menu table doesn't move on the
        // screen if the up arrow is not visible.
        children.add(SizedBox(height: height));
      }
    }
    return TableRow(children: children);
  }

  Widget _onScreenDisplay(BuildContext context, emotiva.Device device) {
    Color borderColor = Colors.white;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Table(
        columnWidths: {
          0: FixedColumnWidth(25.0),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(),
          4: FixedColumnWidth(25.0),
        },
        children: <TableRow>[
          _verticleArrow(device.menuContents, emotiva.Arrow.up),
          // TODO - For now let's display just rows 4, 5, and 6.
          TableRow(
            children: _row(context, device, 4),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor),
              ),
            ),
          ),
          TableRow(children: _row(context, device, 5)),
          TableRow(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            children: _row(context, device, 6),
          ),
          _verticleArrow(device.menuContents, emotiva.Arrow.down),
        ],
      ),
    );
  }

  Widget _build(BuildContext context, emotiva.Device device) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints boxConstraints) {
      const double scalingFactor = 5.5;
      final double iconSize = min<double>(
          boxConstraints.maxHeight / scalingFactor,
          boxConstraints.maxWidth / scalingFactor);
      return Center(
        child: Column(
          children: [
            _onScreenDisplay(context, device),
            Table(
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
                        tooltip:
                            'Toggles entering and exiting the Emotiva menu',
                        icon: Icon(Icons.menu, size: iconSize * 0.50)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
