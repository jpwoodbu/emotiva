import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

final _log = Logger('DeviceChanges');

class DeviceChanges with ChangeNotifier {
  final emotiva.Device device;

  DeviceChanges(this.device) {
    device.controlStream().listen(_handleControlPacket);
    _log.info('handling control packets');
    device.notifyStream().listen(_handleNotifyPacket);
    _log.info('handling notify packets');

    if (device.menuNotifyPort != null) {
      device.menuNotifyStream().listen(_handleMenuNotifyPacket);
      _log.info('handling menu notify packets');
    }
  }

  void _handleControlPacket(String packet) {
    _log.fine('packet arrived on control port');
    device.parsePacket(packet);
    notifyListeners();
  }

  void _handleNotifyPacket(String packet) {
    _log.fine('packet arrived on notify port');
    device.parsePacket(packet);
    notifyListeners();
  }

  void _handleMenuNotifyPacket(String packet) {
    _log.fine('packet arrived on menu notify port');
    device.parsePacket(packet);
    notifyListeners();
  }
}
