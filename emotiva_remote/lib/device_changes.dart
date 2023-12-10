import 'dart:developer' as developer;
import 'package:flutter/material.dart';

import 'emotiva.dart' as emotiva;

void _log(String message) {
  developer.log(message, name: 'DeviceChanges');
}

class DeviceChanges with ChangeNotifier {
  final emotiva.Device device;
  late Stream<String> controlPortStream;
  late Stream<String> notifyPortStream;
  late Stream<String> menuNotifyPortStream;

  DeviceChanges(this.device) {
    controlPortStream = device.controlPortStream(device.address!);
    notifyPortStream = device.notifyPortStream(device.address!);
    menuNotifyPortStream = device.menuNotifyPortStream(device.address!);
    handleControlPackets();
    _log('handling control packets');
    handleNotifyPackets();
    _log('handling notify packets');
    handleMenuNotifyPackets();
    _log('handling menu notify packets');
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

  Future<void> handleMenuNotifyPackets() async {
    await for (final packet in menuNotifyPortStream) {
      device.parsePacket(packet);
      notifyListeners();
    }
  }
}
