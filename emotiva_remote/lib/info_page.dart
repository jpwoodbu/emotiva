import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'emotiva.dart' as emotiva;
import 'device_changes.dart';
import 'util.dart';

Widget _nameRow(emotiva.Device device) {
  return Row(
    mainAxisSize: MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        device.name,
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      Row(
        children: [
          IconButton(
            onPressed: () => addHaptic(device.updateAll),
            icon: Icon(
              Icons.refresh,
              size: 30,
              semanticLabel: 'Refresh data',
            ),
          ),
          IconButton(
            onPressed: () => addHaptic(device.togglePower),
            icon: Icon(
              Icons.power_settings_new,
              color: device.power == 'On' ? Colors.blue : Colors.amber,
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
      Text(
        'Volume',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      Text('${device.volume.toString()}dB',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _infoTable(emotiva.Device device) {
  return Table(
    children: <TableRow>[
      TableRow(children: [
        Text(device.source),
        Text(device.mode, overflow: TextOverflow.visible, softWrap: false),
        Text(''),
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
      Text(
        'Speaker preset',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      PopupMenuButton(
        child: Row(
          children: [
            Text(device.speakerPreset,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            SizedBox(width: 5),
            Icon(Icons.more_vert),
          ],
        ),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem(
            child: Text('Preset 1'),
            onTap: () => addHaptic(device.speakerPreset1),
          ),
          PopupMenuItem(
            child: Text('Preset 2'),
            onTap: () => addHaptic(device.speakerPreset2),
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
      Text(
        'Loudness',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      Switch(
        value: device.loudness == 'On' ? true : false,
        onChanged: (bool _) => addHaptic(device.toggleLoudness),
      ),
    ],
  );
}

Widget _muteRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('Mute', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      Switch(
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
      Text('Front display brightness:  ${device.dim}%',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      IconButton(
          onPressed: () => addHaptic(device.cycleFrontDisplayBrightness),
          icon: Icon(Icons.light_mode))
    ],
  );
}

class InfoPage extends StatelessWidget {
  InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
        builder: (BuildContext context, DeviceChanges deviceChanges, child) {
      return _build(context, deviceChanges.device);
    });
  }

  Widget _build(BuildContext context, emotiva.Device device) {
    return RefreshIndicator(
      semanticsLabel: 'Info page',
      onRefresh: device.updateAll,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _nameRow(device),
                SizedBox(height: 5),
                _volumeRow(device),
                SizedBox(height: 20),
                _infoTable(device),
                SizedBox(height: 30),
                _speakerPresetRow(device),
                SizedBox(height: 20),
                _loudnessRow(device),
                SizedBox(height: 20),
                _muteRow(device),
                SizedBox(height: 20),
                _frontDisplayBrightnessRow(device),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
