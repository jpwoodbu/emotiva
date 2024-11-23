import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../emotiva.dart' as emotiva;
import '../device_changes.dart';
import '../util.dart';

Widget _enableTuner(BuildContext context, emotiva.Device device) {
  final textStyle = TextStyle(
      fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error);
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Tuner controls unavailable.', style: textStyle),
        Text('Set the Main input to Tuner.', style: textStyle),
        const SizedBox(height: 20),
        ElevatedButton(
            onPressed: () => addHaptic(device.setTuner),
            child: const Text('Input -> Tuner')),
      ],
    ),
  );
}

Widget _frequencyRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Channel',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      Text(device.tunerChannel,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _signalRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Signal',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      Text(device.tunerSignal,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _programRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Program',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      Text(device.tunerProgram,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _rds(emotiva.Device device) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(),
      Text(
        device.tunerRds,
        overflow: TextOverflow.visible,
        softWrap: true,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
      ),
      const Divider(),
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

Widget _bandRow(emotiva.Device device) {
  bool enabled = _tunerActiveInput(device);
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Band',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      SegmentedButton<emotiva.TunerBand>(
        segments: [
          ButtonSegment(
              value: emotiva.TunerBand.am,
              label: const Text('AM'),
              enabled: enabled),
          ButtonSegment(
              value: emotiva.TunerBand.fm,
              label: const Text('FM'),
              enabled: enabled),
        ],
        emptySelectionAllowed: true,
        selected: device.tunerBand == emotiva.TunerBand.unknown
            ? {}
            : {device.tunerBand},
        onSelectionChanged: (selection) => addHaptic(device.toggleTunerBand),
      )
    ],
  );
}

Widget _controls(BuildContext context, emotiva.Device device) {
  const double arrowSize = 50.0;
  // opacity of 1.0 is the default. Reduce the opacity of these controls to 38%
  // when disabled. This is based on how Material 3 describes how to change the
  // opacity for disabled inputs. I looked for how this could be done more
  // directly, but didn't find a way.
  double opacity = 1.0;
  if (!_tunerActiveInput(device)) opacity = 0.38;
  return Table(
    children: [
      TableRow(children: [
        Opacity(
          opacity: opacity,
          child: IconButton(
            onPressed: _tunerActiveInput(device)
                ? () => addHaptic(device.channelUp)
                : null,
            icon: const Icon(
              Icons.keyboard_arrow_up,
              size: arrowSize,
              semanticLabel: 'preset up',
            ),
          ),
        ),
        Opacity(
          opacity: opacity,
          child: IconButton(
            onPressed: _tunerActiveInput(device)
                ? () => addHaptic(device.seekHigher)
                : null,
            icon: const Icon(
              Icons.keyboard_arrow_up,
              size: arrowSize,
              semanticLabel: 'seek up',
            ),
          ),
        ),
        Opacity(
          opacity: opacity,
          child: IconButton(
            onPressed: _tunerActiveInput(device)
                ? () => addHaptic(device.frequencyHigher)
                : null,
            icon: const Icon(
              Icons.keyboard_arrow_up,
              size: arrowSize,
              semanticLabel: 'tune up',
            ),
          ),
        ),
      ]),
      TableRow(children: [
        Opacity(
          opacity: opacity,
          child: const Center(child: Text('Preset')),
        ),
        Opacity(
          opacity: opacity,
          child: const Center(child: Text('Seek')),
        ),
        Opacity(
          opacity: opacity,
          child: const Center(child: Text('Tune')),
        ),
      ]),
      TableRow(children: [
        Opacity(
          opacity: opacity,
          child: IconButton(
            onPressed: _tunerActiveInput(device)
                ? () => addHaptic(device.channelDown)
                : null,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: arrowSize,
              semanticLabel: 'preset down',
            ),
          ),
        ),
        Opacity(
          opacity: opacity,
          child: IconButton(
            onPressed: _tunerActiveInput(device)
                ? () => addHaptic(device.seekLower)
                : null,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: arrowSize,
              semanticLabel: 'seek down',
            ),
          ),
        ),
        Opacity(
          opacity: opacity,
          child: IconButton(
            onPressed: _tunerActiveInput(device)
                ? () => addHaptic(device.frequencyLower)
                : null,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: arrowSize,
              semanticLabel: 'tune down',
            ),
          ),
        ),
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
              const SizedBox(height: 5.0),
              _signalRow(device),
              const SizedBox(height: 5.0),
              _programRow(device),
              const SizedBox(height: 5.0),
              _rds(device),
              const SizedBox(height: 5.0),
              _volumeRow(device),
              const SizedBox(height: 15.0),
              _bandRow(device),
              const SizedBox(height: 5.0),
              _controls(context, device),
              if (!_tunerActiveInput(device)) _enableTuner(context, device),
            ],
          )
        ],
      ),
    );
  }
}
