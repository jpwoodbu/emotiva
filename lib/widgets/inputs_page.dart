import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;
import 'package:emotiva_remote/device_changes.dart';
import 'package:emotiva_remote/util.dart';
import 'package:emotiva_remote/widgets/volume_row.dart';

const double _tableCellPadding = 8.0;

/// This is a workaround for not getting notify messages when changing inputs
/// for zone 2.
void delayedUpdateAll(emotiva.Device device) {
  Future.delayed(const Duration(seconds: 2), device.updateAll);
}

void _bumpCenterTrim(double step, emotiva.Device device) {
  final trim = device.centerTrim += step;
  addHaptic(() => device.trimCenter(trim));
}

void _bumpSubwooferTrim(double step, emotiva.Device device) {
  final trim = device.subwooferTrim += step;
  addHaptic(() => device.trimSubwoofer(trim));
}

void _bumpSurroundTrim(double step, emotiva.Device device) {
  final trim = device.surroundTrim += step;
  addHaptic(() => device.trimSurround(trim));
}

void _bumpBackTrim(double step, emotiva.Device device) {
  final trim = device.backTrim += step;
  addHaptic(() => device.trimBack(trim));
}

void _bumpHeightTrim(double step, emotiva.Device device) {
  final trim = device.heightTrim += step;
  addHaptic(() => device.trimHeight(trim));
}

void _bumpWidthTrim(double step, emotiva.Device device) {
  final trim = device.widthTrim += step;
  addHaptic(() => device.trimWidth(trim));
}

Future<T?> showCustomBottomSheet<T>({
  required BuildContext context,
  required List<Widget> children,
}) {
  return showModalBottomSheet(
    context: context,
    scrollControlDisabledMaxHeightRatio: 1.0, // allows a full height sheet
    builder: (BuildContext context) {
      // SafeArea is needed because this widget doesn't inherit the SafeArea
      // properties from the main app. And without SafeArea, it's been observed
      // that the Android navigation buttons overlap some of the key parts of
      // this sheet.
      return SafeArea(
        child: Padding(
          // Bottom padding is not needed for a bottom sheet. And the bottom
          // margin should be sufficiently handled by the SafeArea wrapper.
          padding: const EdgeInsets.fromLTRB(padding, padding, padding, 0.0),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              children: children,
            ),
          ),
        ),
      );
    },
  );
}

class SelectionButton<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T selection;

  const SelectionButton({
    required this.label,
    required this.icon,
    required this.selection,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: const ButtonStyle(alignment: .centerLeft),
      onPressed: () => Navigator.pop<T>(context, selection),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class CupertinoSelectionButton<T> extends StatelessWidget {
  final String label;
  final T selection;

  const CupertinoSelectionButton({
    required this.label,
    required this.selection,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheetAction(
      onPressed: () => Navigator.pop<T>(context, selection),
      child: Text(label),
    );
  }
}

List<Widget> _buildSourceList(BuildContext context, emotiva.Device device) {
  List<Widget> widgets = [];
  for (var i = 1; i < 9; i++) {
    final bool visible = device.visibility['input_$i'] ?? false;
    String name = device.names['input_$i'] ?? 'Source $i';
    if (name.isEmpty) {
      name = 'Source $i';
    }
    if (visible) {
      if (isApple(context)) {
        widgets.add(CupertinoSelectionButton<int>(label: name, selection: i));
      } else {
        widgets.add(
          SelectionButton<int>(label: name, icon: Icons.person, selection: i),
        );
      }
    }
  }
  return widgets;
}

/// Displays an adaptive modal to select a source.
void _sourceSelector(BuildContext context, emotiva.Device device) async {
  int? selection;
  if (isApple(context)) {
    selection = await showCupertinoModalPopup<int>(
      context: context,
      builder: (BuildContext context) =>
          CupertinoActionSheet(actions: _buildSourceList(context, device)),
    );
  } else {
    selection = await showCustomBottomSheet<int>(
      context: context,
      children: _buildSourceList(context, device),
    );
  }
  if (selection != null) {
    addHaptic(() => device.setSource(selection!));
  }
}

/// Displays an adaptive modal to select an HDMI input.
void _hdmiSelector(BuildContext context, emotiva.Device device) async {
  int? selection;
  if (isApple(context)) {
    selection = await showCupertinoModalPopup<int>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: List<Widget>.generate(8, (index) {
          final number = index + 1;
          return CupertinoSelectionButton<int>(
            label: 'HDMI $number',
            selection: number,
          );
        }),
      ),
    );
  } else {
    selection = await showCustomBottomSheet<int>(
      context: context,
      children: List<Widget>.generate(8, (index) {
        final number = index + 1;
        return SelectionButton<int>(
          label: 'HDMI $number',
          icon: Icons.settings_input_hdmi,
          selection: number,
        );
      }),
    );
  }
  if (selection != null) {
    addHaptic(() => device.setHdmi(selection!));
  }
}

/// Displays an adaptive modal to select a coax input. Also used for Zone 2.
void coaxSelector(
  BuildContext context,
  emotiva.Device device, {
  bool zone2 = false,
}) async {
  int? selection;
  if (isApple(context)) {
    selection = await showCupertinoModalPopup<int>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: List<Widget>.generate(4, (index) {
          final number = index + 1;
          return CupertinoSelectionButton<int>(
            label: 'Coax $number',
            selection: number,
          );
        }),
      ),
    );
  } else {
    selection = await showCustomBottomSheet<int>(
      context: context,
      children: List<Widget>.generate(4, (index) {
        final number = index + 1;
        return SelectionButton<int>(
          label: 'Coax $number',
          icon: Icons.settings_input_composite,
          selection: number,
        );
      }),
    );
  }
  if (selection != null) {
    if (zone2) {
      addHaptic(() => device.zone2SetCoax(selection!));
      delayedUpdateAll(device);
    } else {
      addHaptic(() => device.setCoax(selection!));
    }
  }
}

/// Displays an adaptive modal to select an optical input. Also used for Zone 2.
void opticalSelector(
  BuildContext context,
  emotiva.Device device, {
  bool zone2 = false,
}) async {
  int? selection;
  if (isApple(context)) {
    selection = await showCupertinoModalPopup<int>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: List<Widget>.generate(4, (index) {
          final number = index + 1;
          return CupertinoSelectionButton<int>(
            label: 'Optical $number',
            selection: number,
          );
        }),
      ),
    );
  } else {
    selection = await showCustomBottomSheet<int>(
      context: context,
      children: List<Widget>.generate(4, (index) {
        final number = index + 1;
        return SelectionButton<int>(
          label: 'Optical $number',
          icon: Icons.lightbulb,
          selection: number,
        );
      }),
    );
  }
  if (selection != null) {
    if (zone2) {
      addHaptic(() => device.zone2SetOptical(selection!));
      delayedUpdateAll(device);
    } else {
      addHaptic(() => device.setOptical(selection!));
    }
  }
}

enum XlrSelection { aesebu, balanced }

/// Displays an adaptive modal to select an XLR input. Also used for Zone 2.
void xlrSelector(
  BuildContext context,
  emotiva.Device device, {
  bool zone2 = false,
}) async {
  XlrSelection? selection;
  if (isApple(context)) {
    selection = await showCupertinoModalPopup<XlrSelection>(
      context: context,
      builder: (BuildContext context) => const CupertinoActionSheet(
        actions: <CupertinoSelectionButton<XlrSelection>>[
          CupertinoSelectionButton(label: 'AES/EBU', selection: .aesebu),
          CupertinoSelectionButton(
            label: 'Balanced Input',
            selection: .balanced,
          ),
        ],
      ),
    );
  } else {
    selection = await showCustomBottomSheet<XlrSelection>(
      context: context,
      children: const <SelectionButton<XlrSelection>>[
        SelectionButton(
          label: 'AES/EBU',
          icon: Icons.developer_board,
          selection: .aesebu,
        ),
        SelectionButton(
          label: 'Balanced Input',
          icon: Icons.album,
          selection: .balanced,
        ),
      ],
    );
  }
  switch (selection) {
    case .aesebu:
      if (zone2) {
        addHaptic(() => device.zone2SetAesEbu());
        delayedUpdateAll(device);
      } else {
        addHaptic(() => device.setAesEbu());
      }
    case .balanced:
      if (zone2) {
        addHaptic(() => device.zone2SetBalancedInput());
        delayedUpdateAll(device);
      } else {
        addHaptic(() => device.setBalancedInput());
      }
    case null: // do nothing
  }
}

/// Displays an adaptive modal to select an analog input. Also used for Zone 2.
void analogSelector(
  BuildContext context,
  emotiva.Device device, {
  bool zone2 = false,
}) async {
  int? selection;
  if (isApple(context)) {
    selection = await showCupertinoModalPopup<int>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: List<Widget>.generate(3, (index) {
          final number = index + 1;
          return CupertinoSelectionButton<int>(
            label: 'Analog $number',
            selection: number,
          );
        }),
      ),
    );
  } else {
    selection = await showCustomBottomSheet<int>(
      context: context,
      children: List<Widget>.generate(3, (index) {
        final number = index + 1;
        return SelectionButton<int>(
          label: 'Analog $number',
          icon: Icons.settings_input_component,
          selection: number,
        );
      }),
    );
  }
  if (selection != null) {
    if (zone2) {
      addHaptic(() => device.zone2SetAnalog(selection!));
      delayedUpdateAll(device);
    } else {
      addHaptic(() => device.setAnalog(selection!));
    }
  }
}

enum OtherSelection { arc, usb, tuner, front }

/// Displays an adaptive modal to select an input which doesn't fall into any
/// other category.
void _otherInputsSelector(BuildContext context, emotiva.Device device) async {
  OtherSelection? selection;
  if (isApple(context)) {
    selection = await showCupertinoModalPopup<OtherSelection>(
      context: context,
      builder: (BuildContext context) => const CupertinoActionSheet(
        actions: <CupertinoSelectionButton<OtherSelection>>[
          CupertinoSelectionButton(label: 'ARC', selection: .arc),
          CupertinoSelectionButton(label: 'USB', selection: .usb),
          CupertinoSelectionButton(label: 'Tuner', selection: .tuner),
          CupertinoSelectionButton(label: 'Front', selection: .front),
        ],
      ),
    );
  } else {
    selection = await showCustomBottomSheet<OtherSelection>(
      context: context,
      children: const <SelectionButton<OtherSelection>>[
        SelectionButton(
          label: 'ARC',
          icon: Icons.settings_input_hdmi,
          selection: .arc,
        ),
        SelectionButton(label: 'USB', icon: Icons.usb, selection: .usb),
        SelectionButton(label: 'Tuner', icon: Icons.radio, selection: .tuner),
        SelectionButton(
          label: 'Front',
          icon: Icons.smartphone,
          selection: .front,
        ),
      ],
    );
  }
  switch (selection) {
    case .arc:
      addHaptic(() => device.setArc());
    case .front:
      addHaptic(() => device.setFront());
    case .tuner:
      addHaptic(() => device.setTuner());
    case .usb:
      addHaptic(() => device.setUsb());
    case null: // do nothing
  }
}

enum ModeSelection {
  auto,
  stereo,
  direct,
  referenceStereo,
  dolby,
  dts,
  allStereo,
}

/// Displays an adaptive modal to select a playback mode.
void _modeSelector(BuildContext context, emotiva.Device device) async {
  ModeSelection? selection;
  if (isApple(context)) {
    selection = await showCupertinoModalPopup<ModeSelection>(
      context: context,
      builder: (BuildContext context) => const CupertinoActionSheet(
        actions: <CupertinoSelectionButton<ModeSelection>>[
          CupertinoSelectionButton(label: 'Auto', selection: .auto),
          CupertinoSelectionButton(label: 'Stereo', selection: .stereo),
          CupertinoSelectionButton(label: 'Direct', selection: .direct),
          CupertinoSelectionButton(
            label: 'Reference Stereo',
            selection: .referenceStereo,
          ),
          CupertinoSelectionButton(label: 'Dolby', selection: .dolby),
          CupertinoSelectionButton(label: 'DTS', selection: .dts),
          CupertinoSelectionButton(label: 'All Stereo', selection: .allStereo),
        ],
      ),
    );
  } else {
    selection = await showCustomBottomSheet<ModeSelection>(
      context: context,
      children: const <SelectionButton<ModeSelection>>[
        SelectionButton(
          label: 'Auto',
          icon: Icons.surround_sound,
          selection: .auto,
        ),
        SelectionButton(
          label: 'Stereo',
          icon: Icons.speaker_group,
          selection: .stereo,
        ),
        SelectionButton(
          label: 'Direct',
          icon: Icons.arrow_forward,
          selection: .direct,
        ),
        SelectionButton(
          label: 'Reference Stereo',
          icon: Icons.hearing,
          selection: .referenceStereo,
        ),
        SelectionButton(
          label: 'Dolby',
          icon: Icons.surround_sound,
          selection: .dolby,
        ),
        SelectionButton(
          label: 'DTS',
          icon: Icons.surround_sound,
          selection: .dts,
        ),
        SelectionButton(
          label: 'All Stereo',
          icon: Icons.hub,
          selection: .allStereo,
        ),
      ],
    );
  }
  switch (selection) {
    case .allStereo:
      addHaptic(() => device.modeAllStereo());
    case .auto:
      addHaptic(() => device.modeAuto());
    case .direct:
      addHaptic(() => device.modeDirect());
    case .dolby:
      addHaptic(() => device.modeDolby());
    case .dts:
      addHaptic(() => device.modeDts());
    case .referenceStereo:
      addHaptic(() => device.modeReferenceStereo());
    case .stereo:
      addHaptic(() => device.modeStereo());
    case null: // do nothing
  }
}

class _TrimControls extends StatelessWidget {
  const _TrimControls();

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
    if (!(device.visibility['center']! ||
        device.visibility['subwoofer']! ||
        device.visibility['surround']! ||
        device.visibility['back']! ||
        device.visibility['height']! ||
        device.visibility['width']! ||
        device.power)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: Text(
            'Speaker and EQ trim configuration unavailable in the current mode.',
            style: TextStyle(
              fontWeight: .bold,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      );
    }
    const double arrowSize = 50.0;
    return Wrap(
      alignment: .center,
      children: [
        if (device.visibility['center']!)
          Column(
            children: [
              Text('${device.centerTrim}dB'),
              IconButton(
                onPressed: () => _bumpCenterTrim(0.5, device),
                icon: const Icon(
                  Icons.keyboard_arrow_up,
                  size: arrowSize,
                  semanticLabel: 'center trim up',
                ),
              ),
              const Text('Center'),
              IconButton(
                onPressed: () => _bumpCenterTrim(-0.5, device),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: arrowSize,
                  semanticLabel: 'center trim down',
                ),
              ),
            ],
          ),
        if (device.visibility['subwoofer']!)
          Column(
            children: [
              Text('${device.subwooferTrim}dB'),
              IconButton(
                onPressed: () => _bumpSubwooferTrim(0.5, device),
                icon: const Icon(
                  Icons.keyboard_arrow_up,
                  size: arrowSize,
                  semanticLabel: 'subwoofer trim up',
                ),
              ),
              const Text('Sub'),
              IconButton(
                onPressed: () => _bumpSubwooferTrim(-0.5, device),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: arrowSize,
                  semanticLabel: 'subwoofer trim down',
                ),
              ),
            ],
          ),
        if (device.visibility['surround']!)
          Column(
            children: [
              Text('${device.surroundTrim}dB'),
              IconButton(
                onPressed: () => _bumpSurroundTrim(0.5, device),
                icon: const Icon(
                  Icons.keyboard_arrow_up,
                  size: arrowSize,
                  semanticLabel: 'surround trim up',
                ),
              ),
              const Text('Surround'),
              IconButton(
                onPressed: () => _bumpSurroundTrim(-0.5, device),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: arrowSize,
                  semanticLabel: 'surround trim down',
                ),
              ),
            ],
          ),
        if (device.visibility['back']!)
          Column(
            children: [
              Text('${device.backTrim}dB'),
              IconButton(
                onPressed: () => _bumpBackTrim(0.5, device),
                icon: const Icon(
                  Icons.keyboard_arrow_up,
                  size: arrowSize,
                  semanticLabel: 'back trim up',
                ),
              ),
              const Text('Back'),
              IconButton(
                onPressed: () => _bumpBackTrim(-0.5, device),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: arrowSize,
                  semanticLabel: 'back trim down',
                ),
              ),
            ],
          ),
        if (device.visibility['height']!)
          Column(
            children: [
              Text('${device.heightTrim}dB'),
              IconButton(
                onPressed: () => _bumpHeightTrim(0.5, device),
                icon: const Icon(
                  Icons.keyboard_arrow_up,
                  size: arrowSize,
                  semanticLabel: 'height trim up',
                ),
              ),
              const Text('Height'),
              IconButton(
                onPressed: () => _bumpHeightTrim(-0.5, device),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: arrowSize,
                  semanticLabel: 'height trim down',
                ),
              ),
            ],
          ),
        if (device.visibility['width']!)
          Column(
            children: [
              Text('${device.widthTrim}dB'),
              IconButton(
                onPressed: () => _bumpWidthTrim(0.5, device),
                icon: const Icon(
                  Icons.keyboard_arrow_up,
                  size: arrowSize,
                  semanticLabel: 'width trim up',
                ),
              ),
              const Text('Width'),
              IconButton(
                onPressed: () => _bumpWidthTrim(-0.5, device),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: arrowSize,
                  semanticLabel: 'width trim down',
                ),
              ),
            ],
          ),
        Row(
          mainAxisSize: .min,
          children: [
            Column(
              children: [
                Text('${device.trebleTrim}dB'),
                IconButton(
                  onPressed: () => addHaptic(device.trebleUp),
                  icon: const Icon(
                    Icons.keyboard_arrow_up,
                    size: arrowSize,
                    semanticLabel: 'treble trim up',
                  ),
                ),
                const Text('Treble'),
                IconButton(
                  onPressed: () => addHaptic(device.trebleDown),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: arrowSize,
                    semanticLabel: 'treble trim down',
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text('${device.bassTrim}dB'),
                IconButton(
                  onPressed: () => addHaptic(device.bassUp),
                  icon: const Icon(
                    Icons.keyboard_arrow_up,
                    size: arrowSize,
                    semanticLabel: 'bass trim up',
                  ),
                ),
                const Text('Bass'),
                IconButton(
                  onPressed: () => addHaptic(device.bassDown),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: arrowSize,
                    semanticLabel: 'bass trim down',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Inputs extends StatelessWidget {
  const _Inputs();

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
    return Table(
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(_tableCellPadding),
              child: ElevatedButton.icon(
                onPressed: () => _sourceSelector(context, device),
                icon: const Icon(Icons.person),
                label: const Text('Source'),
                style: const ButtonStyle(alignment: Alignment.centerLeft),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(_tableCellPadding),
              child: ElevatedButton.icon(
                onPressed: () => _hdmiSelector(context, device),
                icon: const Icon(Icons.settings_input_hdmi),
                label: const Text('HDMI'),
                style: const ButtonStyle(alignment: .centerLeft),
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(_tableCellPadding),
              child: ElevatedButton.icon(
                onPressed: () => opticalSelector(context, device),
                icon: const Icon(Icons.lightbulb),
                label: const Text('Optical'),
                style: const ButtonStyle(alignment: .centerLeft),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(_tableCellPadding),
              child: ElevatedButton.icon(
                onPressed: () => coaxSelector(context, device),
                icon: const Icon(Icons.settings_input_composite),
                label: const Text('Coax'),
                style: const ButtonStyle(alignment: .centerLeft),
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(_tableCellPadding),
              child: ElevatedButton.icon(
                onPressed: () => analogSelector(context, device),
                icon: const Icon(Icons.settings_input_component),
                label: const Text('Analog'),
                style: const ButtonStyle(alignment: .centerLeft),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(_tableCellPadding),
              child: ElevatedButton.icon(
                onPressed: () => xlrSelector(context, device),
                icon: const Icon(Icons.donut_large),
                label: const Text('XLR'),
                style: const ButtonStyle(alignment: .centerLeft),
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(_tableCellPadding),
              child: ElevatedButton.icon(
                onPressed: () => _otherInputsSelector(context, device),
                icon: const Icon(Icons.more),
                label: const Text('Other'),
                style: const ButtonStyle(alignment: .centerLeft),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(_tableCellPadding),
              child: ElevatedButton.icon(
                onPressed: () => _modeSelector(context, device),
                icon: const Icon(Icons.surround_sound),
                label: const Text('Mode'),
                style: const ButtonStyle(alignment: .centerLeft),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status();

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Flexible(
          child: Text(
            device.source,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        Flexible(
          child: Text(
            device.mode,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class InputsPage extends StatelessWidget {
  const InputsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
    return Padding(
      padding: const EdgeInsets.all(padding),
      child: ListView(
        children: [
          if (device.menuDisplayed) menuWarning(context),
          const _Status(),
          const SizedBox(height: 15),
          const VolumeRow(),
          const SizedBox(height: 15),
          const _Inputs(),
          const SizedBox(height: 25),
          const _TrimControls(),
        ],
      ),
    );
  }
}
