import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

import 'device_changes.dart';

class Zone2Page extends StatelessWidget {
  const Zone2Page({super.key});

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