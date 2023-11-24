import 'package:flutter/material.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

class DeviceChanges with ChangeNotifier {
  final emotiva.Device device;
  late Stream<String> controlPortStream;
  late Stream<String> notifyPortStream;

  DeviceChanges(this.device) {
    controlPortStream = device.controlPortStream();
    notifyPortStream = device.notifyPortStream();
  }

  Future<void> handleControlPackets() async {
    await for (final packet in controlPortStream) {
      device.parsePacket(packet);
      notifyListeners();
    }
  }

  Future<void> handleNotifyPackets() async {
    await for (final packet in notifyPortStream) {
      device.parsePacket(packet);
      notifyListeners();
    }
  }
}
