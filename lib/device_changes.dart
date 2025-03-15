import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

import 'emotiva.dart' as emotiva;

final _log = Logger('DeviceChanges');

class DeviceChanges with ChangeNotifier {
  final emotiva.Device device;

  DeviceChanges(this.device) {
    if (!device.socketsBound) {
      throw 'Cannot set up ChangeNotifier until sockets have been bound on the '
          'device.';
    }
    _handleControlPackets();
    _log.info('handling control packets');
    _handleNotifyPackets();
    _log.info('handling notify packets');
    _handleMenuNotifyPackets();
    _log.info('handling menu notify packets');
  }

  Future<void> _handleControlPackets() async {
    await for (final packet in device.controlPortStream()) {
      device.parsePacket(packet);
      notifyListeners();
    }
  }

  Future<void> _handleNotifyPackets() async {
    await for (final packet in device.notifyPortStream()) {
      device.parsePacket(packet);
      notifyListeners();
    }
  }

  Future<void> _handleMenuNotifyPackets() async {
    await for (final packet in device.menuNotifyPortStream()) {
      device.parsePacket(packet);
      notifyListeners();
    }
  }
}
