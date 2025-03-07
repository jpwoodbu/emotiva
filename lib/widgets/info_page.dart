import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../emotiva.dart' as emotiva;
import '../device_changes.dart';
import '../util.dart';

Widget _nameRow(emotiva.Device device) {
  return Row(
    mainAxisSize: MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        device.name,
        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      Row(
        children: [
          IconButton(
            onPressed: () => addHaptic(device.updateAll),
            icon: const Icon(
              Icons.refresh,
              size: 30,
              semanticLabel: 'Refresh data',
            ),
          ),
          IconButton(
            onPressed: () {
              addHaptic(device.togglePower);
              // Workaround for no notification when the devices powers on and
              // sets the initial power-on config.
              Future.delayed(const Duration(seconds: 2), device.updateAll);
            },
            icon: Icon(
              Icons.power_settings_new,
              color: device.power ? Colors.blue : Colors.amber,
              size: 30,
              semanticLabel: 'Toggle power',
            ),
          ),
        ],
      )
    ],
  );
}

Widget _volumeRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Volume',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      Text('${device.volume.toString()}dB',
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _infoTable(emotiva.Device device) {
  return Table(
    children: <TableRow>[
      TableRow(children: [
        Text(device.source),
        Text(device.mode, overflow: TextOverflow.visible, softWrap: false),
        const Text(''),
      ]),
      TableRow(children: [
        Text('A: ${device.audioInput}'),
        Text(device.audioBitstream),
        Text(device.audioBits),
      ]),
      TableRow(children: [
        Text('V: ${device.videoInput}'),
        Text(device.videoFormat),
        Text(device.videoSpace),
      ])
    ],
  );
}

Widget _speakerPresetRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Flexible(
        child: Text(
          'Speaker preset',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      MenuAnchor(
        builder: (BuildContext context, MenuController controller, _) {
          return TextButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: Text(
              device.speakerPreset,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          );
        },
        menuChildren: [
          MenuItemButton(
            child: const Text('Preset 1'),
            onPressed: () => addHaptic(device.speakerPreset1),
          ),
          MenuItemButton(
            child: const Text('Preset 2'),
            onPressed: () => addHaptic(device.speakerPreset2),
          ),
        ],
      ),
    ],
  );
}

Widget _loudnessRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Loudness',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      Switch.adaptive(
        value: device.loudness,
        onChanged: (bool _) => addHaptic(device.toggleLoudness),
      ),
    ],
  );
}

Widget _muteRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text('Mute',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      Switch.adaptive(
        value: device.muted ? true : false,
        onChanged: (bool _) => addHaptic(device.toggleMute),
      ),
    ],
  );
}

Widget _frontDisplayBrightnessRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child: Text('Front display brightness:  ${device.dim}%',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      IconButton(
        onPressed: () => addHaptic(device.cycleFrontDisplayBrightness),
        icon: const Icon(
          Icons.light_mode,
          semanticLabel: 'cycle front display brightness',
        ),
      )
    ],
  );
}

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
        builder: (BuildContext context, DeviceChanges deviceChanges, _) {
      return _build(context, deviceChanges.device);
    });
  }

  Widget _build(BuildContext context, emotiva.Device device) {
    return RefreshIndicator(
      semanticsLabel: 'Info page',
      onRefresh: () => addHaptic(device.updateAll),
      child: Padding(
        padding: const EdgeInsets.all(kPadding),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (device.menuDisplayed) menuWarning(context),
                _nameRow(device),
                const SizedBox(height: 5),
                _volumeRow(device),
                const SizedBox(height: 20),
                _infoTable(device),
                const SizedBox(height: 30),
                _speakerPresetRow(device),
                const SizedBox(height: 20),
                _loudnessRow(device),
                const SizedBox(height: 20),
                _muteRow(device),
                const SizedBox(height: 20),
                _frontDisplayBrightnessRow(device),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
