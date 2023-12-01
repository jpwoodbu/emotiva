import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;
import 'device_changes.dart';

class InfoPage extends StatelessWidget {
  InfoPage({super.key});

  Future<void> futureUpdateAll(emotiva.Device device) async {
    HapticFeedback.lightImpact();
    await device.updateAll();
  }

  void updateAll(emotiva.Device device) async {
    await futureUpdateAll(device);
  }

  void togglePower(emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.togglePower();
  }

  void toggleMute(emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.toggleMute();
  }

  void toggleLoudness(emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.toggleLoudness();
  }

  void cycleFrontDisplayBrightness(emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.cycleFrontDisplayBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
      builder: (BuildContext context, DeviceChanges deviceChanges, child) {
        return _build(context, deviceChanges.device);
      }
    );
  }

  Widget _build(BuildContext context, emotiva.Device device) {
    return RefreshIndicator(
      semanticsLabel: 'Info page',
      onRefresh: () => futureUpdateAll(device),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                          onPressed: () {updateAll(device);},
                          icon: Icon(
                            Icons.refresh,
                            size: 30,
                          ),
                        ),
                        IconButton(
                          onPressed: () {togglePower(device);},
                          icon: Icon(
                            Icons.power_settings_new,
                            color: device.power == 'On'
                                ? Colors.blue
                                : Colors.amber,
                            size: 30,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Volume',
                      style: TextStyle(
                          fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    Text('${device.volume.toString()}dB',
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 20),
                Table(
                  children: <TableRow>[
                    TableRow(children: [
                      Text(device.source),
                      Text(device.mode,
                          overflow: TextOverflow.visible, softWrap: false),
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
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Speaker preset',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(device.speakerPreset,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Loudness',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: device.loudness == 'On' ? true : false,
                      onChanged: (bool value) {
                        toggleLoudness(device);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mute',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    Switch(
                      value: device.muted ? true : false,
                      onChanged: (bool value) {
                        toggleMute(device);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Front display brightness:  ${device.dim}%',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    IconButton(
                        onPressed: () {cycleFrontDisplayBrightness(device);},
                        icon: Icon(Icons.light_mode))
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
