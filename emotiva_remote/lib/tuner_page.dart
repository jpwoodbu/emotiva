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
    return Placeholder();
  }
}