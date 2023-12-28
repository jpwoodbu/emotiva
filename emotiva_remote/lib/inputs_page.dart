import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'emotiva.dart' as emotiva;
import 'device_changes.dart';
import 'util.dart';

const double _sheetPadding = 15.0;
const double _tableCellPadding = 8.0;

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

void _setAesEbu(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.setAesEbu());
}

void _setOptical(BuildContext context, emotiva.Device device, int input) {
  _addHapticAndPop(context, () => device.setOptical(input));
}

void _setAnalog(BuildContext context, emotiva.Device device, int input) {
  _addHapticAndPop(context, () => device.setAnalog(input));
}

void _setBalancedInput(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.setBalancedInput());
}

void _setArc(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.setArc());
}

void _setUsb(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.setUsb());
}

void _setTuner(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.setTuner());
}

void _setFront(BuildContext context, emotiva.Device device) {
  _addHapticAndPop(context, () => device.setFront());
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
      widgets.add(
        ElevatedButton.icon(
          onPressed: () => _setSource(context, device, i),
          icon: const Icon(Icons.person),
          label: Text(name),
        ),
      );
    }
  }
  return widgets;
}

void _sourceBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(_sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildSourceList(context, device),
        ),
      );
    },
  );
}

void _hdmiBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(_sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton.icon(
                onPressed: () => _setHdmi(context, device, 1),
                icon: const Icon(Icons.settings_input_hdmi),
                label: const Text('HDMI 1')),
            ElevatedButton.icon(
                onPressed: () => _setHdmi(context, device, 2),
                icon: const Icon(Icons.settings_input_hdmi),
                label: const Text('HDMI 2')),
            ElevatedButton.icon(
                onPressed: () => _setHdmi(context, device, 3),
                icon: const Icon(Icons.settings_input_hdmi),
                label: const Text('HDMI 3')),
            ElevatedButton.icon(
                onPressed: () => _setHdmi(context, device, 4),
                icon: const Icon(Icons.settings_input_hdmi),
                label: const Text('HDMI 4')),
            ElevatedButton.icon(
                onPressed: () => _setHdmi(context, device, 5),
                icon: const Icon(Icons.settings_input_hdmi),
                label: const Text('HDMI 5')),
            ElevatedButton.icon(
                onPressed: () => _setHdmi(context, device, 6),
                icon: const Icon(Icons.settings_input_hdmi),
                label: const Text('HDMI 6')),
            ElevatedButton.icon(
                onPressed: () => _setHdmi(context, device, 7),
                icon: const Icon(Icons.settings_input_hdmi),
                label: const Text('HDMI 7')),
            ElevatedButton.icon(
                onPressed: () => _setHdmi(context, device, 8),
                icon: const Icon(Icons.settings_input_hdmi),
                label: const Text('HDMI 8')),
          ],
        ),
      );
    },
  );
}

void _coaxBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(_sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton.icon(
                onPressed: () => _setCoax(context, device, 1),
                icon: const Icon(Icons.settings_input_composite),
                label: const Text('Coax 1')),
            ElevatedButton.icon(
                onPressed: () => _setCoax(context, device, 2),
                icon: const Icon(Icons.settings_input_composite),
                label: const Text('Coax 2')),
            ElevatedButton.icon(
                onPressed: () => _setCoax(context, device, 3),
                icon: const Icon(Icons.settings_input_composite),
                label: const Text('Coax 3')),
            ElevatedButton.icon(
                onPressed: () => _setCoax(context, device, 4),
                icon: const Icon(Icons.settings_input_composite),
                label: const Text('Coax 4')),
          ],
        ),
      );
    },
  );
}

void _opticalBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(_sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton.icon(
                onPressed: () => _setOptical(context, device, 1),
                icon: const Icon(Icons.lightbulb),
                label: const Text('Optical 1')),
            ElevatedButton.icon(
                onPressed: () => _setOptical(context, device, 2),
                icon: const Icon(Icons.lightbulb),
                label: const Text('Optical 2')),
            ElevatedButton.icon(
                onPressed: () => _setOptical(context, device, 3),
                icon: const Icon(Icons.lightbulb),
                label: const Text('Optical 3')),
            ElevatedButton.icon(
                onPressed: () => _setOptical(context, device, 4),
                icon: const Icon(Icons.lightbulb),
                label: const Text('Optical 4')),
          ],
        ),
      );
    },
  );
}

void _xlrBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(_sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton.icon(
                onPressed: () => _setAesEbu(context, device),
                icon: const Icon(Icons.developer_board),
                label: const Text('AES/EBU')),
            ElevatedButton.icon(
                onPressed: () => _setBalancedInput(context, device),
                icon: const Icon(Icons.album),
                label: const Text('Balanced Input')),
          ],
        ),
      );
    },
  );
}

void _analogBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(_sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton.icon(
                onPressed: () => _setAnalog(context, device, 1),
                icon: const Icon(Icons.settings_input_component),
                label: const Text('Analog 1')),
            ElevatedButton.icon(
                onPressed: () => _setAnalog(context, device, 2),
                icon: const Icon(Icons.settings_input_component),
                label: const Text('Analog 2')),
            ElevatedButton.icon(
                onPressed: () => _setAnalog(context, device, 3),
                icon: const Icon(Icons.settings_input_component),
                label: const Text('Analog 3')),
          ],
        ),
      );
    },
  );
}

void _otherBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(_sheetPadding),
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

void _modeBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(_sheetPadding),
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

Widget _trimControls(BuildContext context, emotiva.Device device) {
  // If no trims are visible, don't try to render an empty table. That
  // would throw an error.
  if (!(device.visibility['center']! ||
      device.visibility['subwoofer']! ||
      device.visibility['surround']! ||
      device.visibility['back']! ||
      device.visibility['height']! ||
      device.visibility['width']!)) {
    return Center(
        child: Text(
            'Speaker trim configuration unavailable in the current mode.',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error)));
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
    ],
  );
}

Widget _inputs(BuildContext context, emotiva.Device device) {
  return Table(
    children: [
      TableRow(children: [
        Padding(
          padding: const EdgeInsets.all(_tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => _sourceBottomSheet(context, device),
            icon: const Icon(Icons.person),
            label: const Text('Source'),
            style: const ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(_tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => _hdmiBottomSheet(context, device),
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
            onPressed: () => _opticalBottomSheet(context, device),
            icon: const Icon(Icons.lightbulb),
            label: const Text('Optical'),
            style: const ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(_tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => _coaxBottomSheet(context, device),
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
            onPressed: () => _analogBottomSheet(context, device),
            icon: const Icon(Icons.settings_input_component),
            label: const Text('Analog'),
            style: const ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(_tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => _xlrBottomSheet(context, device),
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
            onPressed: () => _otherBottomSheet(context, device),
            icon: const Icon(Icons.more),
            label: const Text('Other'),
            style: const ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(_tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => _modeBottomSheet(context, device),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
        builder: (BuildContext context, DeviceChanges deviceChanges, child) {
      return _build(context, deviceChanges.device);
    });
  }
}
