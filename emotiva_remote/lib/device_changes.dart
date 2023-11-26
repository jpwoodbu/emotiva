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
  }

  Future<void> handleControlPackets() async {
    await for (final packet in controlPortStream) {
      developer.log('got a control response');
      device.parsePacket(packet);
      notifyListeners();
      developer.log('control: notifying listeners');
    }
  }

  Future<void> handleNotifyPackets() async {
    await for (final packet in notifyPortStream) {
      developer.log('got a notify packets');
      device.parsePacket(packet);
      notifyListeners();
      developer.log('notify: notifying listeners');
    }
  }
}
