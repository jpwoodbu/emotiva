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
    HapticFeedback.lightImpact();
    await widget.device.updateAll();
    setState(() {});
  }

  void togglePower() async {
    HapticFeedback.lightImpact();
    widget.device.togglePower();
  }

  void toggleMute() async {
    HapticFeedback.lightImpact();
    widget.device.toggleMute();
  }

  void toggleLoudness() async {
    HapticFeedback.lightImpact();
    setState(() {
      widget.device.toggleLoudness();
    });
  }

  void cycleFrontDisplayBrightness() async {
    HapticFeedback.lightImpact();
    setState(() {
      widget.device.cycleFrontDisplayBrightness();
    });
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        return Future(updateAll);
      },
      child: Padding(
        padding: const EdgeInsets.all(15),
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
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Loudness',
                          style: TextStyle(fontSize: 15),
                        ),
                        Switch(
                          value: widget.device.loudness == 'On' ? true : false,
                          onChanged: (bool value) {
                            toggleLoudness();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mute', style: TextStyle(fontSize: 15)),
                        Switch(
                          value: widget.device.muted ? true : false,
                          onChanged: (bool value) {
                            toggleMute();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Front display brightness: ${widget.device.dim}%',
                            style: TextStyle(fontSize: 15)),
                        IconButton(
                            onPressed: cycleFrontDisplayBrightness,
                            icon: Icon(Icons.light_mode))
                      ],
                    )
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
