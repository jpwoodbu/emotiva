import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;
import 'package:emotiva_remote/device_changes.dart';
import 'package:emotiva_remote/util.dart';
import 'package:emotiva_remote/widgets/volume_row.dart';

class _EnableTuner extends StatelessWidget {
  const _EnableTuner();

  @override
  Widget build(BuildContext context) {
    final device = context.read<DeviceChanges>().device;
    final textStyle = TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.error);
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
}

class _FrequencyRow extends StatelessWidget {
  const _FrequencyRow();

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
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
}

class _SignalRow extends StatelessWidget {
  const _SignalRow();

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
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
}

class _ProgramRow extends StatelessWidget {
  const _ProgramRow();

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
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
}

class _RDS extends StatelessWidget {
  const _RDS();

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
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
}

class _BandRow extends StatelessWidget {
  const _BandRow();

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
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
}

class _Controls extends StatelessWidget {
  const _Controls();

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
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
}

bool _tunerActiveInput(emotiva.Device device) {
  return device.source == 'Tuner' || device.audioInput == 'Tuner';
}

class TunerPage extends StatelessWidget {
  const TunerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
    return Padding(
      padding: const EdgeInsets.all(kPadding),
      child: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (device.menuDisplayed) menuWarning(context),
              const _FrequencyRow(),
              const SizedBox(height: 5.0),
              const _SignalRow(),
              const SizedBox(height: 5.0),
              const _ProgramRow(),
              const SizedBox(height: 5.0),
              const _RDS(),
              const SizedBox(height: 5.0),
              const VolumeRow(),
              const SizedBox(height: 15.0),
              const _BandRow(),
              const SizedBox(height: 5.0),
              const _Controls(),
              if (!_tunerActiveInput(device)) const _EnableTuner(),
            ],
          )
        ],
      ),
    );
  }
}
