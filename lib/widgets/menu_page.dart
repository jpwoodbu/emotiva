import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;
import 'package:emotiva_remote/device_changes.dart';
import 'package:emotiva_remote/util.dart';

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

class _ArrowIcon extends StatelessWidget {
  const _ArrowIcon({required emotiva.Arrow arrow, required double size})
      : _arrow = arrow,
        _size = size;

  final emotiva.Arrow _arrow;
  final double _size;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    var alignment = Alignment.centerLeft;
    switch (_arrow) {
      case emotiva.Arrow.up:
        icon = Icons.keyboard_arrow_up;
      case emotiva.Arrow.down:
        icon = Icons.keyboard_arrow_down;
      case emotiva.Arrow.left:
        icon = Icons.keyboard_arrow_left;
      case emotiva.Arrow.right:
        icon = Icons.keyboard_arrow_right;
        alignment = Alignment.centerRight;
      default:
        icon = Icons.error;
    }
    return Container(alignment: alignment, child: Icon(icon, size: _size));
  }
}

/// This widget is used when the verticle arrows are over fixed width text.
/// Typically, the text is an input which can be changed by pressing the up/down
/// controls to cycle through different characters. The vertical arrows indicate
/// which character is currently editable and therefore needs to be able to
/// offset horizontally to align with the editable character. The icon version
/// of this widget is both wider than a single character and, with the font
/// config being used, would be very tricky to position in line with the
/// editable character. This is why a character from the same font is used to
/// render the arrows in this widget.
class _ArrowText extends StatelessWidget {
  const _ArrowText({required emotiva.Arrow arrow, required int offset})
      : _arrow = arrow,
        _offset = offset;

  final emotiva.Arrow _arrow;
  final int _offset;

  @override
  Widget build(BuildContext context) {
    final character = switch (_arrow) {
      emotiva.Arrow.up => '▲',
      emotiva.Arrow.down => '▼',
      // We should only see up or down arrows passed to this widget.
      _ => '❌',
    };
    // TODO(jpwoodbu) Make this DRY with the config the _row() function.
    final style = GoogleFonts.robotoMono(
        textStyle:
            const TextStyle(fontWeight: FontWeight.w400, fontSize: 12.0));
    return Container(
      // TODO(jpwoodbu) The margin and padding in the _row() function is
      // different from what I'm using here and I am not certain why this config
      // was needed to get the proper alignment. Using a different character,
      // like ⇑, seemed to align better while using the same margin and padding
      // from _row(). Layout is too hard.
      margin: const EdgeInsets.fromLTRB(1.0, 0.0, 0.0, 0.0),
      padding: const EdgeInsets.fromLTRB(1.0, 0.0, 0.0, 0.0),
      alignment: Alignment.centerLeft,
      // Left pad with a space for each column offset indicated.
      child: Text(' ' * _offset + character, style: style),
    );
  }
}

List<Widget> _row(emotiva.Menu menu, int rowIndex) {
  const inset = 2.0;
  const size = 25.0;
  final leftArrowPosition = menu.leftArrow();
  final rightArrowPosition = menu.rightArrow();
  // Leave space for a potential arrow.
  List<Widget> columns = [const SizedBox(width: size)];
  if (rowIndex == leftArrowPosition.track) {
    columns[0] = const _ArrowIcon(arrow: emotiva.Arrow.left, size: size);
  }
  for (final column in menu.rows[rowIndex].columns) {
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
  if (rowIndex == rightArrowPosition.track) {
    columns.add(const _ArrowIcon(arrow: emotiva.Arrow.right, size: size));
  } else {
    columns.add(const SizedBox(width: size));
  }
  return columns;
}

/// Puts an empty box or a vertical arrow in each cell of the row.
TableRow _verticalArrow(emotiva.ArrowPosition arrowPosition) {
  const height = 25.0;
  final List<Widget> children = [const SizedBox(width: 25.0)];
  for (int i = 0; i < 4; i++) {
    if (arrowPosition.track == i) {
      if (arrowPosition.fixedWidth) {
        children.add(_ArrowText(
            arrow: arrowPosition.arrow, offset: arrowPosition.offset));
      } else {
        // TODO(jpwoodbu) Should I pass the icon data instead of the arrow?
        children.add(_ArrowIcon(arrow: arrowPosition.arrow, size: height));
      }
    } else {
      // Setting this height makes sure the menu table doesn't move on the
      // screen if the up arrow is not visible.
      children.add(const SizedBox(height: height));
    }
  }
  return TableRow(children: children);
}

TableRow _upArrow(emotiva.Menu menu) => _verticalArrow(menu.upArrow());
TableRow _downArrow(emotiva.Menu menu) => _verticalArrow(menu.downArrow());

class _OnScreenDisplay extends StatelessWidget {
  const _OnScreenDisplay();

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
          _upArrow(device.menuContents),
          TableRow(
            children: _row(device.menuContents, 4),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor),
              ),
            ),
          ),
          TableRow(children: _row(device.menuContents, 5)),
          TableRow(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            children: _row(device.menuContents, 6),
          ),
          _downArrow(device.menuContents),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls();

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
        _OnScreenDisplay(),
        Flexible(
          fit: FlexFit.loose,
          child: _Controls(),
        ),
      ],
    );
  }
}
