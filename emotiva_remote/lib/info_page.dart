import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

import 'device_model.dart';

class InfoPage extends StatefulWidget {
  final emotiva.Device device;
  InfoPage(this.device, {super.key});

  @override
  State<InfoPage> createState() => _InfoState();
}

class _InfoState extends State<InfoPage> {
  late DeviceModel _deviceNotifier;

  void updateAll() async {
    HapticFeedback.vibrate();
    await widget.device.updateAll();
    setState(() {});
  }

  void togglePower() async {
    HapticFeedback.lightImpact();
    widget.device.togglePower();
  }

  void toggleMute() async {
    widget.device.toggleMute();
  }

  void subscribeAll() async {
    await widget.device.subscribeAll();
  }

  @override
  void initState() {
    super.initState();
    _deviceNotifier = DeviceModel(widget.device);
    _deviceNotifier.handleControlPackets();
    _deviceNotifier.handleNotifyPackets();
    subscribeAll();
  }

  void _toggleLoudness() async {
    setState(() {
      widget.device.toggleLoudness();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: RefreshIndicator(
        onRefresh: () {
          return Future(updateAll);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ListenableBuilder(
              listenable: _deviceNotifier,
              builder: (BuildContext context, Widget? child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.device.name,
                          style: TextStyle(fontSize: 25),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: updateAll,
                              icon: Icon(
                                Icons.refresh,
                                size: 30,
                              ),
                            ),
                            IconButton(
                              onPressed: togglePower,
                              icon: Icon(
                                Icons.power_settings_new,
                                color: widget.device.power == 'On'
                                    ? Colors.blue
                                    : Colors.amber,
                                size: 30,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    Text(
                      'Volume: ${widget.device.volume}dB',
                      style: TextStyle(fontSize: 18),
                    ),
                    Table(
                      children: <TableRow>[
                        TableRow(children: [
                          SizedBox(height: 25),
                          SizedBox(height: 25),
                          SizedBox(height: 25),
                        ]),
                        TableRow(children: [
                          Text(widget.device.source),
                          Text(widget.device.mode,
                              overflow: TextOverflow.visible, softWrap: false),
                          Text(''),
                        ]),
                        TableRow(children: [
                          Text('A: ${widget.device.audioInput}'),
                          Text(widget.device.audioBitstream),
                          Text(widget.device.audioBits),
                        ]),
                        TableRow(children: [
                          Text('V: ${widget.device.videoInput}'),
                          Text(widget.device.videoFormat),
                          Text(widget.device.videoSpace),
                        ])
                      ],
                    ),
                    SizedBox(height: 25),
                    /*
                    ElevatedButton.icon(
                      onPressed: _toggleLoudness,
                      icon: Icon(Icons.hearing,
                          color: widget.device.loudness == 'On'
                              ? Colors.green
                              : Colors.grey),
                      label: Text('Loudness'),
                    ),
                    */
                    Row(
                      children: [
                        Text('Loudness'),
                        Switch(value: true, onChanged: (bool value) {}),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: toggleMute,
                      child: Text('Mute'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
