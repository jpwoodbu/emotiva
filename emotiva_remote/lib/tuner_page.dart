import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

import 'device_changes.dart';

class TunerPage extends StatelessWidget {
  const TunerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
        builder: (BuildContext context, DeviceChanges deviceChanges, child) {
      return _build(context, deviceChanges.device);
    });
  }

  Widget _build(BuildContext context, emotiva.Device device) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: ListView(
        children: [
          Text(device.tunerBand.name.toUpperCase()),
          Text(device.tunerChannel),
          Text(device.tunerSignal),
          Text(device.tunerProgram),
          Text(device.tunerRds),
          ElevatedButton(onPressed: () {}, child: Text('Set tuner input')),
          ElevatedButton(onPressed: () {}, child: Text('Toggle AM/FM')),
          ElevatedButton(onPressed: () {}, child: Text('Frequency +')),
          ElevatedButton(onPressed: () {}, child: Text('Frequency -')),
          ElevatedButton(onPressed: () {}, child: Text('Seek +')),
          ElevatedButton(onPressed: () {}, child: Text('Seek -')),
          ElevatedButton(onPressed: () {}, child: Text('Channel +')),
          ElevatedButton(onPressed: () {}, child: Text('Channel -')),
          ElevatedButton(onPressed: () {}, child: Text('Channel list')),
        ],
      ),
    );
  }
}
