import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

import 'emotiva.dart' as emotiva;

final _log = Logger('DeviceChanges');

class DeviceChanges with ChangeNotifier {
  final emotiva.Device device;

  DeviceChanges(this.device) {
    _handleControlPackets();
    _log.info('handling control packets');
    _handleNotifyPackets();
    _log.info('handling notify packets');
    _handleMenuNotifyPackets();
    _log.info('handling menu notify packets');
  }

  Future<void> _handleControlPackets() async {
    await for (final packet in device.controlStream()) {
      _log.fine('packet arrived on control port');
      device.parsePacket(packet);
      notifyListeners();
    }
  }

  Future<void> _handleNotifyPackets() async {
    await for (final packet in device.notifyStream()) {
      _log.fine('packet arrived on notify port');
      device.parsePacket(packet);
      notifyListeners();
    }
  }

  Future<void> _handleMenuNotifyPackets() async {
    await for (final packet in device.menuNotifyStream()) {
      _log.fine('packet arrived on menu notify port');
      device.parsePacket(packet);
      notifyListeners();
    }
  }
}
