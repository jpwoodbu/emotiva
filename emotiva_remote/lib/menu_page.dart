import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

import 'emotiva.dart' as emotiva;
import 'device_changes.dart';
import 'util.dart';

double _iconSize(BoxConstraints constraints) {
  // There are 4 rows in the controls table. Divide the height evenly by the
  // number of rows. I don't yet understand why diving by 3.0 (there are 3
  // columns) looks bad when the screen is in landscape mode.
  const rows = 4.0;
  if (constraints.maxHeight > constraints.maxWidth) {
    return constraints.maxWidth / rows;
  } else {
    return constraints.maxHeight / rows;
  }
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

class OnScreenDisplay extends StatelessWidget {
  const OnScreenDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
    const Color borderColor = Colors.white;
    const padding = 10.0;
    if (!device.menuDisplayed || device.menuContents.rows.length < 7) {
      const rowHeight = 25.0;
      return Padding(
        padding: const EdgeInsets.fromLTRB(padding, padding, padding, 0.0),
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
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(padding, padding, padding, 0.0),
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
}

class Controls extends StatelessWidget {
  const Controls({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.read<DeviceChanges>().device;
    return LayoutBuilder(
      builder: (_, constraints) => Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: <TableRow>[
          TableRow(
            children: [
              const SizedBox(),
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => addHaptic(device.menuUp),
                icon: Icon(
                  Icons.keyboard_arrow_up,
                  size: _iconSize(constraints),
                  semanticLabel: 'up',
                ),
              ),
              const SizedBox(),
            ],
          ),
          TableRow(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => addHaptic(device.menuLeft),
                icon: Icon(
                  Icons.keyboard_arrow_left,
                  size: _iconSize(constraints),
                  semanticLabel: 'left',
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => addHaptic(device.menuEnter),
                icon: Icon(
                  Icons.circle_outlined,
                  size: _iconSize(constraints),
                  semanticLabel: 'enter',
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => addHaptic(device.menuRight),
                icon: Icon(
                  Icons.keyboard_arrow_right,
                  size: _iconSize(constraints),
                  semanticLabel: 'right',
                ),
              ),
            ],
          ),
          TableRow(
            children: [
              const SizedBox(),
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => addHaptic(device.menuDown),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: _iconSize(constraints),
                  semanticLabel: 'down',
                ),
              ),
              const SizedBox(),
            ],
          ),
          TableRow(
            children: [
              IconButton(
                // There's some special padding math here because these icons
                // are just too big without scaling them down. But making their
                // size different reduces the row height, which causes the whole
                // table to appear to scale before it must. The padding makes
                // the row approximiately the size it would have been had the
                // icon size not been reduced (see below).
                padding: EdgeInsets.all(_iconSize(constraints) * 0.2),
                onPressed: () => addHaptic(device.info),
                icon: Icon(
                  Icons.info,
                  size: _iconSize(constraints) * 0.6,
                  semanticLabel: 'show on screen display info table',
                ),
              ),
              const SizedBox(),
              IconButton(
                padding: EdgeInsets.all(_iconSize(constraints) * 0.2),
                onPressed: () => addHaptic(device.toggleMenu),
                icon: Icon(
                  Icons.menu,
                  size: _iconSize(constraints) * 0.6,
                  semanticLabel:
                      'toggles entering and exiting the Emotiva menu',
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
      ),
    );
  }
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OnScreenDisplay(),
        Flexible(
          fit: FlexFit.loose,
          child: Controls(),
        ),
      ],
    );
  }
}
