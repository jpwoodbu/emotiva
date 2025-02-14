import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../emotiva.dart' as emotiva;
import '../device_changes.dart';
import '../util.dart';

const double _tableCellPadding = 8.0;

// This is a workaround for not getting notify messages when changing inputs for
// zone 2.
void _delayedUpdateAll(emotiva.Device device) {
  Future.delayed(const Duration(seconds: 2), device.updateAll);
}

void _addHapticAndPop(BuildContext context, Function function) {
  addHaptic(function);
  Navigator.pop(context);
}

void _setSource(BuildContext context, emotiva.Device device, int input) {
  _addHapticAndPop(context, () => device.setSource(input));
}

void _setHdmi(BuildContext context, emotiva.Device device, int input) {
  _addHapticAndPop(context, () => device.setHdmi(input));
}

void _setCoax(BuildContext context, emotiva.Device device, int input) {
  _addHapticAndPop(context, () => device.setCoax(input));
}

void _setCoaxZone2(BuildContext context, emotiva.Device device, int input) {
  _addHapticAndPop(context, () => device.zone2SetCoax(input));
  _delayedUpdateAll(device);
}

void _setAesEbu(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.setAesEbu());
}

void _setAesEbuZone2(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.zone2SetAesEbu());
  _delayedUpdateAll(device);
}

void _setOptical(BuildContext context, emotiva.Device device, int input) {
  _addHapticAndPop(context, () => device.setOptical(input));
}

void _setOpticalZone2(BuildContext context, emotiva.Device device, int input) {
  _addHapticAndPop(context, () => device.zone2SetOptical(input));
  _delayedUpdateAll(device);
}

void _setAnalog(BuildContext context, emotiva.Device device, int input) {
  _addHapticAndPop(context, () => device.setAnalog(input));
}

void _setAnalogZone2(BuildContext context, emotiva.Device device, int input) {
  _addHapticAndPop(context, () => device.zone2SetAnalog(input));
  _delayedUpdateAll(device);
}

void _setBalancedInput(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.setBalancedInput());
}

void _setBalancedInputZone2(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.zone2SetBalancedInput());
  _delayedUpdateAll(device);
}

void _setArc(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.setArc());
}

void _setUsb(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.setUsb());
}

void setUsbZone2(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.zone2SetUsb());
  _delayedUpdateAll(device);
}

void _setTuner(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.setTuner());
}

void _setFront(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.setFront());
}

void setFrontZone2(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.zone2SetFront());
  _delayedUpdateAll(device);
}

// This is only used for zone 2 controls, but it makes use of functions in this
// library.
void setFollowMain(emotiva.Device device) {
  addHaptic(device.zone2FollowMain);
  _delayedUpdateAll(device);
}

void _setModeAuto(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.modeAuto());
}

void _setModeStereo(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.modeStereo());
}

void _setModeDirect(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.modeDirect());
}

void _setModeReferenceStereo(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.modeReferenceStereo());
}

void _setModeDolby(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.modeDolby());
}

void _setModeDts(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.modeDts());
}

void _setModeAllStereo(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.modeAllStereo());
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

List<Widget> _buildSourceList(BuildContext context, emotiva.Device device) {
  List<Widget> widgets = [];
  for (var i = 1; i < 9; i++) {
    final bool visible = device.visibility['input_$i'] ?? false;
    String name = device.names['input_$i'] ?? 'Source $i';
    if (name.isEmpty) {
      name = 'Source $i';
    }
    if (visible) {
      void onPressed() => _setSource(context, device, i);
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        widgets.add(
          CupertinoActionSheetAction(
            onPressed: onPressed,
            child: Text(name),
          ),
        );
      } else {
        widgets.add(
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.person),
            label: Text(name),
          ),
        );
      }
    }
  }
  return widgets;
}

void _sourceSelector(BuildContext context, emotiva.Device device) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: _buildSourceList(context, device),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      scrollControlDisabledMaxHeightRatio: 1.0,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildSourceList(context, device),
          ),
        );
      },
    );
  }
}

void _hdmiSelector(BuildContext context, emotiva.Device device) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: List<Widget>.generate(8, (index) {
          final number = index + 1;
          return CupertinoActionSheetAction(
            onPressed: () => _setHdmi(context, device, number),
            child: Text('HDMI $number'),
          );
        }),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      scrollControlDisabledMaxHeightRatio: 1.0,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(8, (index) {
              final number = index + 1;
              return ElevatedButton.icon(
                onPressed: () => _setHdmi(context, device, number),
                icon: const Icon(Icons.settings_input_hdmi),
                label: Text('HDMI $number'),
              );
            }),
          ),
        );
      },
    );
  }
}

void coaxSelector(BuildContext context, emotiva.Device device,
    {bool zone2 = false}) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: List<Widget>.generate(4, (index) {
          final number = index + 1;
          return CupertinoActionSheetAction(
            onPressed: zone2
                ? () => _setCoaxZone2(context, device, number)
                : () => _setCoax(context, device, number),
            child: Text('Coax $number'),
          );
        }),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      scrollControlDisabledMaxHeightRatio: 1.0,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(4, (index) {
              final number = index + 1;
              return ElevatedButton.icon(
                  onPressed: zone2
                      ? () => _setCoaxZone2(context, device, number)
                      : () => _setCoax(context, device, number),
                  icon: const Icon(Icons.settings_input_composite),
                  label: Text('Coax $number'));
            }),
          ),
        );
      },
    );
  }
}

void opticalSelector(BuildContext context, emotiva.Device device,
    {bool zone2 = false}) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: List<Widget>.generate(4, (index) {
          final number = index + 1;
          return CupertinoActionSheetAction(
            onPressed: zone2
                ? () => _setOpticalZone2(context, device, number)
                : () => _setOptical(context, device, number),
            child: Text('Optical $number'),
          );
        }),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      scrollControlDisabledMaxHeightRatio: 1.0,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(4, (index) {
              final number = index + 1;
              return ElevatedButton.icon(
                  onPressed: zone2
                      ? () => _setOpticalZone2(context, device, number)
                      : () => _setOptical(context, device, number),
                  icon: const Icon(Icons.lightbulb),
                  label: Text('Optical $number'));
            }),
          ),
        );
      },
    );
  }
}

void xlrSelector(BuildContext context, emotiva.Device device,
    {bool zone2 = false}) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: zone2
                ? () => _setAesEbuZone2(context, device)
                : () => _setAesEbu(context, device),
            child: Text('AES/EBU'),
          ),
          CupertinoActionSheetAction(
            onPressed: zone2
                ? () => _setBalancedInputZone2(context, device)
                : () => _setBalancedInput(context, device),
            child: Text('Balanced Input'),
          ),
        ],
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      scrollControlDisabledMaxHeightRatio: 1.0,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: zone2
                      ? () => _setAesEbuZone2(context, device)
                      : () => _setAesEbu(context, device),
                  icon: const Icon(Icons.developer_board),
                  label: const Text('AES/EBU')),
              ElevatedButton.icon(
                  onPressed: zone2
                      ? () => _setBalancedInputZone2(context, device)
                      : () => _setBalancedInput(context, device),
                  icon: const Icon(Icons.album),
                  label: const Text('Balanced Input')),
            ],
          ),
        );
      },
    );
  }
}

void analogSelector(BuildContext context, emotiva.Device device,
    {bool zone2 = false}) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: List<Widget>.generate(3, (index) {
          final number = index + 1;
          return CupertinoActionSheetAction(
            onPressed: zone2
                ? () => _setAnalogZone2(context, device, number)
                : () => _setAnalog(context, device, number),
            child: Text('Analog $number'),
          );
        }),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      scrollControlDisabledMaxHeightRatio: 1.0,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(3, (index) {
              final number = index + 1;
              return ElevatedButton.icon(
                onPressed: zone2
                    ? () => _setAnalogZone2(context, device, number)
                    : () => _setAnalog(context, device, number),
                icon: const Icon(Icons.settings_input_component),
                label: Text('Analog $number'),
              );
            }),
          ),
        );
      },
    );
  }
}

void _otherInputsSelector(BuildContext context, emotiva.Device device) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () => _setArc(context, device),
            child: Text('ARC'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => _setUsb(context, device),
            child: Text('USB'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => _setTuner(context, device),
            child: Text('Tuner'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => _setFront(context, device),
            child: Text('Front'),
          ),
        ],
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      scrollControlDisabledMaxHeightRatio: 1.0,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: () => _setArc(context, device),
                  icon: const Icon(Icons.settings_input_hdmi),
                  label: const Text('ARC')),
              ElevatedButton.icon(
                  onPressed: () => _setUsb(context, device),
                  icon: const Icon(Icons.usb),
                  label: const Text('USB')),
              ElevatedButton.icon(
                  onPressed: () => _setTuner(context, device),
                  icon: const Icon(Icons.radio),
                  label: const Text('Tuner')),
              ElevatedButton.icon(
                  onPressed: () => _setFront(context, device),
                  icon: const Icon(Icons.smartphone),
                  label: const Text('Front')),
            ],
          ),
        );
      },
    );
  }
}

void _modeSelector(BuildContext context, emotiva.Device device) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () => _setModeAuto(context, device),
            child: Text('Auto'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => _setModeStereo(context, device),
            child: Text('Stereo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => _setModeDirect(context, device),
            child: Text('Direct'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => _setModeReferenceStereo(context, device),
            child: Text('Reference Stereo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => _setModeDolby(context, device),
            child: Text('Dolby'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => _setModeDts(context, device),
            child: Text('DTS'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => _setModeAllStereo(context, device),
            child: Text('All Stereo'),
          ),
        ],
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      scrollControlDisabledMaxHeightRatio: 1.0,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: () => _setModeAuto(context, device),
                  icon: const Icon(Icons.surround_sound),
                  label: const Text('Auto')),
              ElevatedButton.icon(
                  onPressed: () => _setModeStereo(context, device),
                  icon: const Icon(Icons.speaker_group),
                  label: const Text('Stereo')),
              ElevatedButton.icon(
                  onPressed: () => _setModeDirect(context, device),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Direct')),
              ElevatedButton.icon(
                  onPressed: () => _setModeReferenceStereo(context, device),
                  icon: const Icon(Icons.hearing),
                  label: const Text('Reference Stereo')),
              ElevatedButton.icon(
                  onPressed: () => _setModeDolby(context, device),
                  icon: const Icon(Icons.surround_sound),
                  label: const Text('Dolby')),
              ElevatedButton.icon(
                  onPressed: () => _setModeDts(context, device),
                  icon: const Icon(Icons.surround_sound),
                  label: const Text('DTS')),
              ElevatedButton.icon(
                  onPressed: () => _setModeAllStereo(context, device),
                  icon: const Icon(Icons.hub),
                  label: const Text('All Stereo')),
            ],
          ),
        );
      },
    );
  }
}

Widget _trimControls(BuildContext context, emotiva.Device device) {
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
    ));
  } else {
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

Widget _inputs(BuildContext context, emotiva.Device device) {
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

Widget _status(emotiva.Device device) {
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
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    ],
  );
}

Widget _volumeRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Volume',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      Text('${device.volume.toString()}dB',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    ],
  );
}

class InputsPage extends StatelessWidget {
  const InputsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
        builder: (BuildContext context, DeviceChanges deviceChanges, _) {
      return _build(context, deviceChanges.device);
    });
  }

  Widget _build(BuildContext context, emotiva.Device device) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: ListView(
        children: [
          if (device.menuDisplayed) menuWarning(context),
          _status(device),
          const SizedBox(height: 15),
          _volumeRow(device),
          const SizedBox(height: 15),
          _inputs(context, device),
          const SizedBox(height: 25),
          _trimControls(context, device),
        ],
      ),
    );
  }
}
