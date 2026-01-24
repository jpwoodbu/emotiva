import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

final _log = Logger('DeviceChanges');

class DeviceChanges with ChangeNotifier {
  final emotiva.Device device;

  DeviceChanges(this.device) {
    device.controlStream().listen((packet) {
      _log.fine('packet arrived on control port');
      _onPacket(packet);
    });
    _log.info('handling control packets');
    device.notifyStream().listen((packet) {
      _log.fine('packet arrived on notify port');
      _onPacket(packet);
    });
    _log.info('handling notify packets');

    if (device.menuNotifyPort != null) {
      device.menuNotifyStream().listen((packet) {
        _log.fine('packet arrived on menu notify port');
        _onPacket(packet);
      });
      _log.info('handling menu notify packets');
    }
  }

  void _onPacket(String packet) {
    device.parsePacket(packet);
    notifyListeners();
  }
}
