import 'dart:developer' as developer;
import 'package:flutter/material.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

class DeviceChanges with ChangeNotifier {
  final emotiva.Device device;
  late Stream<String> controlPortStream;
  late Stream<String> notifyPortStream;

  DeviceChanges(this.device) {
    controlPortStream = device.controlPortStream(device.address!);
    notifyPortStream = device.notifyPortStream(device.address!);
    handleControlPackets();
    developer.log('handling control packets');
    handleNotifyPackets();
    developer.log('handling notify packets');
  }

  Future<void> handleControlPackets() async {
    await for (final packet in controlPortStream) {
      developer.log('got a control message: $packet');
      device.parsePacket(packet);
      notifyListeners();
    }
  }

  Future<void> handleNotifyPackets() async {
    await for (final packet in notifyPortStream) {
      developer.log('got a notify message: $packet');
      device.parsePacket(packet);
      notifyListeners();
    }
  }
}
