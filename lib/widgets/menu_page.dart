import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;
import 'package:emotiva_remote/device_changes.dart';
import 'package:emotiva_remote/util.dart';

const double _arrowSize = 25.0;

double _buttonSize(BoxConstraints constraints) {
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
  const _ArrowIcon({required this._arrow, required this._size});

  final emotiva.Arrow _arrow;
  final double _size;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Alignment alignment = .centerLeft;
    switch (_arrow) {
      case .up:
        icon = Icons.keyboard_arrow_up;
      case .down:
        icon = Icons.keyboard_arrow_down;
      case .left:
        icon = Icons.keyboard_arrow_left;
      case .right:
        icon = Icons.keyboard_arrow_right;
        alignment = .centerRight;
      default:
        icon = Icons.error;
    }
    return Container(
      alignment: alignment,
      child: Icon(icon, size: _size),
    );
  }
}

/// This widget is used when the vertical arrows are over fixed width text.
/// Typically, the text is an input on the Emotiva device which can be changed
/// by pressing the up/down controls to cycle through different characters. The
/// vertical arrows indicate which character is currently editable and therefore
/// needs to be able to offset horizontally to align with the editable
/// character. The icon version of this widget is both wider than a single
/// character and, with the font config being used, would be very tricky to
/// position in line with the editable character. This is why a character from
/// the same font is used to render the arrows in this widget.
class _ArrowText extends StatelessWidget {
  const _ArrowText({required this._arrow, required this._offset});

  final emotiva.Arrow _arrow;
  final int _offset;

  @override
  Widget build(BuildContext context) {
    final character = switch (_arrow) {
      .up => '▲',
      .down => '▼',
      // We should only see up or down arrows passed to this widget.
      _ => '❌',
    };
    // TODO(jpwoodbu) Make this DRY with the config the _row() function.
    final style = GoogleFonts.firaCode(
      textStyle: const TextStyle(fontWeight: .w400, fontSize: 12.0),
    );
    const inset = EdgeInsets.all(2.0);
    return Container(
      // This container should be the same height as the arrow icon which is
      // normally displayed for the arrow graphic. This makes for better visual
      // spacing.
      height: _arrowSize,
      margin: inset,
      padding: inset,
      // Left pad with a space for each column offset indicated.
      child: Text(' ' * _offset + character, style: style),
    );
  }
}

List<Widget> _row(emotiva.Menu menu, int rowIndex) {
  const inset = EdgeInsets.all(2.0);
  final leftArrowPosition = menu.leftArrow();
  final rightArrowPosition = menu.rightArrow();
  // Leave space for a potential arrow.
  List<Widget> columns = [const SizedBox(width: _arrowSize)];
  if (rowIndex == leftArrowPosition.track) {
    columns[0] = const _ArrowIcon(arrow: .left, size: _arrowSize);
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
      // Checkbox filled
      if (column.checkbox!) {
        columns.add(
          Container(
            margin: inset,
            padding: inset,
            alignment: .centerLeft,
            color: backgroundColor,
            child: Icon(
              Icons.disabled_by_default_outlined,
              color: color,
              size: iconSize,
            ),
          ),
        );
      } else {
        // Checkbox empty
        columns.add(
          Container(
            margin: inset,
            padding: inset,
            alignment: .centerLeft,
            color: backgroundColor,
            child: Icon(
              Icons.check_box_outline_blank,
              color: color,
              size: iconSize,
            ),
          ),
        );
      }
    } else {
      // Standard text content
      final textStyle = TextStyle(
        fontWeight: .w400,
        fontSize: 12.0,
        color: color,
      );
      columns.add(
        Container(
          margin: inset,
          padding: inset,
          color: backgroundColor,
          child: Text(
            column.value,
            style: column.fixedWidth
                ? GoogleFonts.firaCode(textStyle: textStyle)
                : textStyle,
          ),
        ),
      );
    }
  }
  if (rowIndex == rightArrowPosition.track) {
    columns.add(const _ArrowIcon(arrow: .right, size: _arrowSize));
  } else {
    columns.add(const SizedBox(width: _arrowSize));
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
        children.add(
          _ArrowText(arrow: arrowPosition.arrow, offset: arrowPosition.offset),
        );
      } else {
        // TODO(jpwoodbu) Should I pass the icon data instead of the arrow?
        // TODO(jpwoodbu) It seems the offset may be important when the
        // fixedWidth property is not set, according to an email from Emotiva.
        children.add(_ArrowIcon(arrow: arrowPosition.arrow, size: height));
      }
    } else {
      // Setting this height makes sure the menu table doesn't move on the
      // screen if the arrow is not visible.
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
    if (device.menuNotifyPort == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(padding, 24.0, padding, 0.0),
        child: Text(
          'Menu mirror not supported on this firmware',
          style: TextStyle(
            fontWeight: .bold,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }
    // If the menu is not meant to be displayed, or we don't have enough rows to
    // display the menu correctly, show an empty display with the top and bottom
    // horizontal borders.
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
                border: Border(top: BorderSide(color: borderColor)),
              ),
            ),
            TableRow(children: [SizedBox(height: rowHeight)]),
            TableRow(
              children: [SizedBox(height: rowHeight)],
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
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
              border: Border(top: BorderSide(color: borderColor)),
            ),
          ),
          TableRow(children: _row(device.menuContents, 5)),
          TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
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
    // TODO(jpwoodbu) Dedupe this opacity feature with its use in
    // menu_page.dart.

    // opacity of 1.0 is the default. Reduce the opacity of these controls to
    // 38% when disabled. This is based on how Material 3 describes how to
    // change the opacity for disabled inputs. I looked for how this could be
    // done more directly, but didn't find a way.
    double opacity = device.menuAvailable() ? 1.0 : 0.38;

    return LayoutBuilder(
      builder: (_, constraints) => Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: <TableRow>[
          TableRow(
            children: [
              const SizedBox(),
              Opacity(
                opacity: opacity,
                child: IconButton(
                  padding: .zero,
                  onPressed: device.menuAvailable()
                      ? () => addHaptic(device.menuUp)
                      : null,
                  icon: Icon(
                    Icons.keyboard_arrow_up,
                    size: _buttonSize(constraints),
                    semanticLabel: 'up',
                  ),
                ),
              ),
              const SizedBox(),
            ],
          ),
          TableRow(
            children: [
              Opacity(
                opacity: opacity,
                child: IconButton(
                  padding: .zero,
                  onPressed: device.menuAvailable()
                      ? () => addHaptic(device.menuLeft)
                      : null,
                  icon: Icon(
                    Icons.keyboard_arrow_left,
                    size: _buttonSize(constraints),
                    semanticLabel: 'left',
                  ),
                ),
              ),
              Opacity(
                opacity: opacity,
                child: IconButton(
                  padding: .zero,
                  onPressed: device.menuAvailable()
                      ? () => addHaptic(device.menuEnter)
                      : null,
                  icon: Icon(
                    Icons.circle_outlined,
                    size: _buttonSize(constraints),
                    semanticLabel: 'enter',
                  ),
                ),
              ),
              Opacity(
                opacity: opacity,
                child: IconButton(
                  padding: .zero,
                  onPressed: device.menuAvailable()
                      ? () => addHaptic(device.menuRight)
                      : null,
                  icon: Icon(
                    Icons.keyboard_arrow_right,
                    size: _buttonSize(constraints),
                    semanticLabel: 'right',
                  ),
                ),
              ),
            ],
          ),
          TableRow(
            children: [
              const SizedBox(),
              Opacity(
                opacity: opacity,
                child: IconButton(
                  padding: .zero,
                  onPressed: device.menuAvailable()
                      ? () => addHaptic(device.menuDown)
                      : null,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: _buttonSize(constraints),
                    semanticLabel: 'down',
                  ),
                ),
              ),
              const SizedBox(),
            ],
          ),
          TableRow(
            children: [
              Opacity(
                opacity: opacity,
                child: IconButton(
                  // There's some special padding math here because these icons
                  // are just too big without scaling them down. But making their
                  // size different reduces the row height, which causes the whole
                  // table to appear to scale before it must. The padding makes
                  // the row approximately the size it would have been had the
                  // icon size not been reduced (see below).
                  padding: .all(_buttonSize(constraints) * 0.2),
                  onPressed: device.menuAvailable()
                      ? () => addHaptic(device.info)
                      : null,
                  icon: Icon(
                    Icons.info,
                    size: _buttonSize(constraints) * 0.6,
                    semanticLabel: 'show on screen display info table',
                  ),
                ),
              ),
              const SizedBox(),
              Opacity(
                opacity: opacity,
                child: IconButton(
                  padding: .all(_buttonSize(constraints) * 0.2),
                  onPressed: device.menuAvailable()
                      ? () => addHaptic(device.toggleMenu)
                      : null,
                  icon: Icon(
                    Icons.menu,
                    size: _buttonSize(constraints) * 0.6,
                    semanticLabel:
                        'toggles entering and exiting the Emotiva menu',
                  ),
                ),
              ),
            ],
          ),
          const TableRow(
            children: [SizedBox(height: 15.0), SizedBox(), SizedBox()],
          ),
        ],
      ),
    );
  }
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: .spaceBetween,
        children: [
          _OnScreenDisplay(),
          Flexible(fit: .loose, child: _Controls()),
        ],
      ),
    );
  }
}
