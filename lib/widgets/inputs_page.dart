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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      );
    },
  );
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
        widgets.add(
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop<int>(context, i),
            child: Text(name),
          ),
        );
      } else {
        widgets.add(
          ElevatedButton.icon(
            onPressed: () => Navigator.pop<int>(context, i),
            icon: const Icon(Icons.person),
            label: Text(name),
          ),
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
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: _buildSourceList(context, device),
      ),
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
          return CupertinoActionSheetAction(
            onPressed: () => Navigator.pop<int>(context, number),
            child: Text('HDMI $number'),
          );
        }),
      ),
    );
  } else {
    selection = await showCustomBottomSheet<int>(
      context: context,
      children: List<Widget>.generate(8, (index) {
        final number = index + 1;
        return ElevatedButton.icon(
          onPressed: () => Navigator.pop<int>(context, number),
          icon: const Icon(Icons.settings_input_hdmi),
          label: Text('HDMI $number'),
        );
      }),
    );
  }
  if (selection != null) {
    addHaptic(() => device.setHdmi(selection!));
  }
}

/// Displays an adaptive modal to select a coax input. Also used for Zone 2.
void coaxSelector(BuildContext context, emotiva.Device device,
    {bool zone2 = false}) async {
  int? selection;
  if (isApple(context)) {
    selection = await showCupertinoModalPopup<int>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: List<Widget>.generate(4, (index) {
          final number = index + 1;
          return CupertinoActionSheetAction(
            onPressed: () => Navigator.pop<int>(context, number),
            child: Text('Coax $number'),
          );
        }),
      ),
    );
  } else {
    selection = await showCustomBottomSheet<int>(
      context: context,
      children: List<Widget>.generate(4, (index) {
        final number = index + 1;
        return ElevatedButton.icon(
            onPressed: () => Navigator.pop<int>(context, number),
            icon: const Icon(Icons.settings_input_composite),
            label: Text('Coax $number'));
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
void opticalSelector(BuildContext context, emotiva.Device device,
    {bool zone2 = false}) async {
  int? selection;
  if (isApple(context)) {
    selection = await showCupertinoModalPopup<int>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: List<Widget>.generate(4, (index) {
          final number = index + 1;
          return CupertinoActionSheetAction(
            onPressed: () => Navigator.pop<int>(context, number),
            child: Text('Optical $number'),
          );
        }),
      ),
    );
  } else {
    selection = await showCustomBottomSheet<int>(
      context: context,
      children: List<Widget>.generate(4, (index) {
        final number = index + 1;
        return ElevatedButton.icon(
            onPressed: () => Navigator.pop<int>(context, number),
            icon: const Icon(Icons.lightbulb),
            label: Text('Optical $number'));
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
void xlrSelector(BuildContext context, emotiva.Device device,
    {bool zone2 = false}) async {
  XlrSelection? selection;
  if (isApple(context)) {
    selection = await showCupertinoModalPopup<XlrSelection>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.pop<XlrSelection>(context, XlrSelection.aesebu),
            child: const Text('AES/EBU'),
          ),
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.pop<XlrSelection>(context, XlrSelection.balanced),
            child: const Text('Balanced Input'),
          ),
        ],
      ),
    );
  } else {
    selection = await showCustomBottomSheet<XlrSelection>(
      context: context,
      children: <Widget>[
        ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop<XlrSelection>(context, XlrSelection.aesebu),
            icon: const Icon(Icons.developer_board),
            label: const Text('AES/EBU')),
        ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop<XlrSelection>(context, XlrSelection.balanced),
            icon: const Icon(Icons.album),
            label: const Text('Balanced Input')),
      ],
    );
  }
  switch (selection) {
    case XlrSelection.aesebu:
      if (zone2) {
        addHaptic(() => device.zone2SetAesEbu());
        delayedUpdateAll(device);
      } else {
        addHaptic(() => device.setAesEbu());
      }
    case XlrSelection.balanced:
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
void analogSelector(BuildContext context, emotiva.Device device,
    {bool zone2 = false}) async {
  int? selection;
  if (isApple(context)) {
    selection = await showCupertinoModalPopup<int>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: List<Widget>.generate(3, (index) {
          final number = index + 1;
          return CupertinoActionSheetAction(
            onPressed: () => Navigator.pop<int>(context, number),
            child: Text('Analog $number'),
          );
        }),
      ),
    );
  } else {
    selection = await showCustomBottomSheet<int>(
      context: context,
      children: List<Widget>.generate(3, (index) {
        final number = index + 1;
        return ElevatedButton.icon(
          onPressed: () => Navigator.pop<int>(context, number),
          icon: const Icon(Icons.settings_input_component),
          label: Text('Analog $number'),
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
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.pop<OtherSelection>(context, OtherSelection.arc),
            child: const Text('ARC'),
          ),
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.pop<OtherSelection>(context, OtherSelection.usb),
            child: const Text('USB'),
          ),
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.pop<OtherSelection>(context, OtherSelection.tuner),
            child: const Text('Tuner'),
          ),
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.pop<OtherSelection>(context, OtherSelection.front),
            child: const Text('Front'),
          ),
        ],
      ),
    );
  } else {
    selection = await showCustomBottomSheet<OtherSelection>(
      context: context,
      children: <Widget>[
        ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop<OtherSelection>(context, OtherSelection.arc),
            icon: const Icon(Icons.settings_input_hdmi),
            label: const Text('ARC')),
        ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop<OtherSelection>(context, OtherSelection.usb),
            icon: const Icon(Icons.usb),
            label: const Text('USB')),
        ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop<OtherSelection>(context, OtherSelection.tuner),
            icon: const Icon(Icons.radio),
            label: const Text('Tuner')),
        ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop<OtherSelection>(context, OtherSelection.front),
            icon: const Icon(Icons.smartphone),
            label: const Text('Front')),
      ],
    );
  }
  switch (selection) {
    case OtherSelection.arc:
      addHaptic(() => device.setArc());
    case OtherSelection.front:
      addHaptic(() => device.setFront());
    case OtherSelection.tuner:
      addHaptic(() => device.setTuner());
    case OtherSelection.usb:
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
  allStereo
}

/// Displays an adaptive modal to select a playback mode.
void _modeSelector(BuildContext context, emotiva.Device device) async {
  ModeSelection? selection;
  if (isApple(context)) {
    selection = await showCupertinoModalPopup<ModeSelection>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.pop<ModeSelection>(context, ModeSelection.auto),
            child: const Text('Auto'),
          ),
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.pop<ModeSelection>(context, ModeSelection.stereo),
            child: const Text('Stereo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.pop<ModeSelection>(context, ModeSelection.direct),
            child: const Text('Direct'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop<ModeSelection>(
                context, ModeSelection.referenceStereo),
            child: const Text('Reference Stereo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.pop<ModeSelection>(context, ModeSelection.dolby),
            child: const Text('Dolby'),
          ),
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.pop<ModeSelection>(context, ModeSelection.dts),
            child: const Text('DTS'),
          ),
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.pop<ModeSelection>(context, ModeSelection.allStereo),
            child: const Text('All Stereo'),
          ),
        ],
      ),
    );
  } else {
    selection = await showCustomBottomSheet<ModeSelection>(
      context: context,
      children: <Widget>[
        ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop<ModeSelection>(context, ModeSelection.auto),
            icon: const Icon(Icons.surround_sound),
            label: const Text('Auto')),
        ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop<ModeSelection>(context, ModeSelection.stereo),
            icon: const Icon(Icons.speaker_group),
            label: const Text('Stereo')),
        ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop<ModeSelection>(context, ModeSelection.direct),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Direct')),
        ElevatedButton.icon(
            onPressed: () => Navigator.pop<ModeSelection>(
                context, ModeSelection.referenceStereo),
            icon: const Icon(Icons.hearing),
            label: const Text('Reference Stereo')),
        ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop<ModeSelection>(context, ModeSelection.dolby),
            icon: const Icon(Icons.surround_sound),
            label: const Text('Dolby')),
        ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop<ModeSelection>(context, ModeSelection.dts),
            icon: const Icon(Icons.surround_sound),
            label: const Text('DTS')),
        ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop<ModeSelection>(context, ModeSelection.allStereo),
            icon: const Icon(Icons.hub),
            label: const Text('All Stereo')),
      ],
    );
  }
  switch (selection) {
    case ModeSelection.allStereo:
      addHaptic(() => device.modeAllStereo());
    case ModeSelection.auto:
      addHaptic(() => device.modeAuto());
    case ModeSelection.direct:
      addHaptic(() => device.modeDirect());
    case ModeSelection.dolby:
      addHaptic(() => device.modeDolby());
    case ModeSelection.dts:
      addHaptic(() => device.modeDts());
    case ModeSelection.referenceStereo:
      addHaptic(() => device.modeReferenceStereo());
    case ModeSelection.stereo:
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
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error)),
        ),
      );
    }
    const double arrowSize = 50.0;
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        if (device.visibility['center']!)
          Column(children: [
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
          ]),
        if (device.visibility['subwoofer']!)
          Column(children: [
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
          ]),
        if (device.visibility['surround']!)
          Column(children: [
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
          ]),
        if (device.visibility['back']!)
          Column(children: [
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
          ]),
        if (device.visibility['height']!)
          Column(children: [
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
          ]),
        if (device.visibility['width']!)
          Column(children: [
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
          ]),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(children: [
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
            ]),
            Column(children: [
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
            ]),
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
        TableRow(children: [
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
              style: const ButtonStyle(alignment: Alignment.centerLeft),
            ),
          ),
        ]),
        TableRow(children: [
          Padding(
            padding: const EdgeInsets.all(_tableCellPadding),
            child: ElevatedButton.icon(
              onPressed: () => opticalSelector(context, device),
              icon: const Icon(Icons.lightbulb),
              label: const Text('Optical'),
              style: const ButtonStyle(alignment: Alignment.centerLeft),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(_tableCellPadding),
            child: ElevatedButton.icon(
              onPressed: () => coaxSelector(context, device),
              icon: const Icon(Icons.settings_input_composite),
              label: const Text('Coax'),
              style: const ButtonStyle(alignment: Alignment.centerLeft),
            ),
          ),
        ]),
        TableRow(children: [
          Padding(
            padding: const EdgeInsets.all(_tableCellPadding),
            child: ElevatedButton.icon(
              onPressed: () => analogSelector(context, device),
              icon: const Icon(Icons.settings_input_component),
              label: const Text('Analog'),
              style: const ButtonStyle(alignment: Alignment.centerLeft),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(_tableCellPadding),
            child: ElevatedButton.icon(
              onPressed: () => xlrSelector(context, device),
              icon: const Icon(Icons.donut_large),
              label: const Text('XLR'),
              style: const ButtonStyle(alignment: Alignment.centerLeft),
            ),
          ),
        ]),
        TableRow(children: [
          Padding(
            padding: const EdgeInsets.all(_tableCellPadding),
            child: ElevatedButton.icon(
              onPressed: () => _otherInputsSelector(context, device),
              icon: const Icon(Icons.more),
              label: const Text('Other'),
              style: const ButtonStyle(alignment: Alignment.centerLeft),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(_tableCellPadding),
            child: ElevatedButton.icon(
              onPressed: () => _modeSelector(context, device),
              icon: const Icon(Icons.surround_sound),
              label: const Text('Mode'),
              style: const ButtonStyle(alignment: Alignment.centerLeft),
            ),
          ),
        ]),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            device.source,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        Flexible(
          child: Text(device.mode,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
