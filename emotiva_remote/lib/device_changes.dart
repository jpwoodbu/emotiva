import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

import 'emotiva.dart' as emotiva;

final _log = Logger('DeviceChanges');

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
    _log.info('handling control packets');
    handleNotifyPackets();
    _log.info('handling notify packets');
    handleMenuNotifyPackets();
    _log.info('handling menu notify packets');
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
