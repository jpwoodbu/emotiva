import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

import 'emotiva.dart' as emotiva;
import 'device_changes.dart';
import 'util.dart';

double _iconSize(BoxConstraints boxConstraints) {
  // At 100, the controls table will be 348w x 424h. That will be our max
  // and default size.
  double iconSize = 100.0;
  if (boxConstraints.maxHeight < 424) {
    iconSize = boxConstraints.maxHeight / 6.0;
  }
  if (boxConstraints.maxWidth < 348) {
    final newSize = boxConstraints.maxWidth / 4.0;
    if (iconSize > newSize) iconSize = newSize;
  }
  return iconSize;
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

List<Widget> _row(emotiva.Device device, int rowIndex) {
  const inset = 2.0;
  const arrowSize = 25.0;
  final leftArrowPosition =
      emotiva.arrowPosition(device.menuContents, emotiva.Arrow.left);
  final rightArrowPosition =
      emotiva.arrowPosition(device.menuContents, emotiva.Arrow.right);
  // Leave space for a potential arrow.
  List<Widget> columns = [const SizedBox(width: arrowSize)];
  if (rowIndex == leftArrowPosition) {
    columns[0] = _arrowWidget(emotiva.Arrow.left, arrowSize);
  }
  for (final column in device.menuContents.rows[rowIndex].columns) {
    Color? color;
    Color? backgroundColor;
    if (column.highlight) {
      color = Colors.black;
      backgroundColor = Colors.white;
    }
    if (column.checkbox != null) {
      const iconSize = 17.0;
      if (column.checkbox!) {
        columns.add(
          Container(
            margin: const EdgeInsets.all(inset),
            padding: const EdgeInsets.all(inset),
            alignment: Alignment.centerLeft,
            color: backgroundColor,
            child: Icon(Icons.disabled_by_default_outlined,
                color: color, size: iconSize),
          ),
        );
      } else {
        columns.add(
          Container(
            margin: const EdgeInsets.all(inset),
            padding: const EdgeInsets.all(inset),
            alignment: Alignment.centerLeft,
            color: backgroundColor,
            child: Icon(Icons.check_box_outline_blank,
                color: color, size: iconSize),
          ),
        );
      }
    } else {
      final textStyle =
          TextStyle(fontWeight: FontWeight.w400, fontSize: 12.0, color: color);
      columns.add(
        Container(
          margin: const EdgeInsets.all(inset),
          padding: const EdgeInsets.all(inset),
          color: backgroundColor,
          child: Text(
            column.value,
            style: column.fixedWidth
                ? GoogleFonts.robotoMono(textStyle: textStyle)
                : textStyle,
          ),
        ),
      );
    }
  }
  if (rowIndex == rightArrowPosition) {
    columns.add(_arrowWidget(emotiva.Arrow.right, arrowSize));
  } else {
    columns.add(const SizedBox(width: arrowSize));
  }
  return columns;
}

TableRow _verticleArrow(emotiva.Menu menu, emotiva.Arrow arrowType) {
  const height = 25.0;
  final arrowPosition = emotiva.arrowPosition(menu, arrowType);
  final List<Widget> children = [const SizedBox(width: 25.0)];
  for (int i = 0; i < 4; i++) {
    if (arrowPosition == i) {
      children.add(_arrowWidget(arrowType, height));
    } else {
      // Setting this height makes sure the menu table doesn't move on the
      // screen if the up arrow is not visible.
      children.add(const SizedBox(height: height));
    }
  }
  return TableRow(children: children);
}

Widget _onScreenDisplay(emotiva.Device device) {
  const Color borderColor = Colors.white;
  const padding = 10.0;
  if (!device.menuDisplayed || device.menuContents.rows.length < 7) {
    const rowHeight = 25.0;
    return SizedBox(
      // 152 is the height of the OSD table, at least with the current font
      // settings.
      height: 152,
      child: Padding(
        padding: const EdgeInsets.all(padding),
        child: Table(
          children: const [
            TableRow(children: [SizedBox(height: rowHeight)]),
            TableRow(
              children: [SizedBox(height: rowHeight)],
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor))),
            ),
            TableRow(children: [SizedBox(height: rowHeight)]),
            TableRow(
              children: [SizedBox(height: rowHeight)],
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor))),
            ),
            TableRow(children: [SizedBox(height: rowHeight)]),
          ],
        ),
      ),
    );
  }
  return Padding(
    padding: const EdgeInsets.all(padding),
    child: Table(
      columnWidths: const {
        0: FixedColumnWidth(25.0),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
        4: FixedColumnWidth(25.0),
      },
      children: <TableRow>[
        _verticleArrow(device.menuContents, emotiva.Arrow.up),
        TableRow(
          children: _row(device, 4),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: borderColor),
            ),
          ),
        ),
        TableRow(children: _row(device, 5)),
        TableRow(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: borderColor),
            ),
          ),
          children: _row(device, 6),
        ),
        _verticleArrow(device.menuContents, emotiva.Arrow.down),
      ],
    ),
  );
}

Widget _controls(emotiva.Device device, BoxConstraints boxConstraints) {
  final iconSize = _iconSize(boxConstraints);
  return Table(
    defaultColumnWidth: const IntrinsicColumnWidth(),
    children: <TableRow>[
      TableRow(
        children: [
          const SizedBox(),
          IconButton(
            onPressed: () => addHaptic(device.menuUp),
            icon: Icon(
              Icons.keyboard_arrow_up,
              size: iconSize,
              semanticLabel: 'up',
            ),
          ),
          const SizedBox(),
        ],
      ),
      TableRow(
        children: [
          IconButton(
            onPressed: () => addHaptic(device.menuLeft),
            icon: Icon(
              Icons.keyboard_arrow_left,
              size: iconSize,
              semanticLabel: 'left',
            ),
          ),
          IconButton(
            onPressed: () => addHaptic(device.menuEnter),
            icon: Icon(
              Icons.circle_outlined,
              size: iconSize,
              semanticLabel: 'enter',
            ),
          ),
          IconButton(
            onPressed: () => addHaptic(device.menuRight),
            icon: Icon(
              Icons.keyboard_arrow_right,
              size: iconSize,
              semanticLabel: 'right',
            ),
          ),
        ],
      ),
      TableRow(
        children: [
          const SizedBox(),
          IconButton(
            onPressed: () => addHaptic(device.menuDown),
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: iconSize,
              semanticLabel: 'down',
            ),
          ),
          const SizedBox(),
        ],
      ),
      TableRow(
        children: [
          IconButton(
            onPressed: () => addHaptic(device.info),
            icon: Icon(
              Icons.info,
              size: iconSize * 0.50,
              semanticLabel: 'show on screen display info table',
            ),
          ),
          const SizedBox(),
          IconButton(
            onPressed: () => addHaptic(device.toggleMenu),
            icon: Icon(
              Icons.menu,
              size: iconSize * 0.50,
              semanticLabel: 'toggles entering and exiting the Emotiva menu',
            ),
          ),
        ],
      ),
      const TableRow(children: [
        SizedBox(height: 15.0),
        SizedBox(),
        SizedBox(),
      ]),
    ],
  );
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
        builder: (BuildContext context, DeviceChanges deviceChanges, _) {
      return _build(context, deviceChanges.device);
    });
  }

  Widget _build(BuildContext context, emotiva.Device device) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _onScreenDisplay(device),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(builder:
                  (BuildContext context, BoxConstraints boxConstraints) {
                return _controls(device, boxConstraints);
              }),
            ),
          ),
        ],
      ),
    );
  }
}
