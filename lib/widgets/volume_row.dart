import 'package:emotiva_remote/device_changes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VolumeRow extends StatelessWidget {
  final double _fontSize;
  final bool _zone2;

  const VolumeRow({super.key, double fontSize = 15.0, bool zone2 = false})
    : _fontSize = fontSize,
      _zone2 = zone2;

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
    final volume = _zone2 ? device.zone2Volume : device.volume;
    return DefaultTextStyle(
      style: TextStyle(fontSize: _fontSize, fontWeight: .bold),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [const Text('Volume'), Text('${volume.toString()}dB')],
      ),
    );
  }
}
