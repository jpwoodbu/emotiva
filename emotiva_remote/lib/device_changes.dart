import 'dart:developer' as developer;
import 'package:flutter/material.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

void _log(String message) {
  developer.log(message, name: 'DeviceChanges');
}

class DeviceChanges with ChangeNotifier {
  final emotiva.Device device;
  late Stream<String> controlPortStream;
  late Stream<String> notifyPortStream;

  DeviceChanges(this.device) {
    controlPortStream = device.controlPortStream(device.address!);
    notifyPortStream = device.notifyPortStream(device.address!);
    handleControlPackets();
    _log('handling control packets');
    handleNotifyPackets();
    _log('handling notify packets');
  }

  Future<void> handleControlPackets() async {
    await for (final packet in controlPortStream) {
      _log('got a control message: $packet');
      device.parsePacket(packet);
      notifyListeners();
    }
  }

  Future<void> handleNotifyPackets() async {
    await for (final packet in notifyPortStream) {
      _log('got a notify message: $packet');
      device.parsePacket(packet);
      notifyListeners();
    }
  }
}
