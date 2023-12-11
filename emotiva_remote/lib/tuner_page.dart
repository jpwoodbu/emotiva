import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'emotiva.dart' as emotiva;
import 'device_changes.dart';
import 'util.dart';

Widget _enableTuner(BuildContext context, emotiva.Device device) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Tuner controls unavailable.'),
        Text('Set the Main input to Tuner.'),
        SizedBox(height: 20),
        ElevatedButton(
            onPressed: () => addHaptic(device.setTuner),
            child: Text('Input -> Tuner')),
      ],
    ),
  );
}

Widget _frequencyRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        'Channel',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      Text(device.tunerChannel,
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _signalRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        'Signal',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      Text(device.tunerSignal,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _programRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        'Program',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      Text(device.tunerProgram,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _rds(emotiva.Device device) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Divider(),
      Text(
        device.tunerRds,
        overflow: TextOverflow.visible,
        softWrap: true,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
      ),
      Divider(),
    ],
  );
}

Widget _volumeRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        'Volume',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      Text('${device.volume.toString()}dB',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _bandRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        'Band',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      SegmentedButton<emotiva.TunerBand>(
        segments: [
          ButtonSegment(value: emotiva.TunerBand.am, label: Text('AM')),
          ButtonSegment(value: emotiva.TunerBand.fm, label: Text('FM')),
        ],
        selected: {device.tunerBand},
        onSelectionChanged: _tunerActiveInput(device)
            ? (selection) => addHaptic(device.toggleTunerBand)
            : null,
      )
    ],
  );
}

Widget _controls(BuildContext context, emotiva.Device device) {
  const double arrowSize = 50.0;
  TextStyle? textStyle;
  if (!_tunerActiveInput(device)) {
    textStyle = TextStyle(
      color: Theme.of(context).colorScheme.error,
      decoration: TextDecoration.lineThrough,
    );
  }
  return Table(
    children: [
      TableRow(children: [
        IconButton(
            onPressed: () => addHaptic(device.channelUp),
            tooltip: 'preset up',
            icon: Icon(Icons.keyboard_arrow_up, size: arrowSize)),
        IconButton(
            onPressed: () => addHaptic(device.seekHigher),
            tooltip: 'seek up',
            icon: Icon(Icons.keyboard_arrow_up, size: arrowSize)),
        IconButton(
            onPressed: () => addHaptic(device.frequencyHigher),
            tooltip: 'tune up',
            icon: Icon(Icons.keyboard_arrow_up, size: arrowSize)),
      ]),
      TableRow(children: [
        Center(child: Text('Preset', style: textStyle)),
        Center(child: Text('Seek', style: textStyle)),
        Center(child: Text('Tune', style: textStyle)),
      ]),
      TableRow(children: [
        IconButton(
            onPressed: () => addHaptic(device.channelDown),
            tooltip: 'preset down',
            icon: Icon(Icons.keyboard_arrow_down, size: arrowSize)),
        IconButton(
            onPressed: () => addHaptic(device.seekLower),
            tooltip: 'seek down',
            icon: Icon(Icons.keyboard_arrow_down, size: arrowSize)),
        IconButton(
            onPressed: () => addHaptic(device.frequencyLower),
            tooltip: 'tune down',
            icon: Icon(Icons.keyboard_arrow_down, size: arrowSize)),
      ]),
    ],
  );
}

bool _tunerActiveInput(emotiva.Device device) {
  return device.source == 'Tuner' || device.audioInput == 'Tuner';
}

class TunerPage extends StatelessWidget {
  const TunerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
        builder: (BuildContext context, DeviceChanges deviceChanges, _) {
      final device = deviceChanges.device;
      return _build(context, device);
    });
  }

  Widget _build(BuildContext context, emotiva.Device device) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (device.menuDisplayed) menuWarning(context),
              _frequencyRow(device),
              SizedBox(height: 5.0),
              _signalRow(device),
              SizedBox(height: 5.0),
              _programRow(device),
              SizedBox(height: 5.0),
              _rds(device),
              SizedBox(height: 5.0),
              _volumeRow(device),
              SizedBox(height: 15.0),
              _bandRow(device),
              SizedBox(height: 5.0),
              _controls(context, device),
              if (!_tunerActiveInput(device)) _enableTuner(context, device),
            ],
          )
        ],
      ),
    );
  }
}
