import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

import 'emotiva.dart' as emotiva;

final _log = Logger('DeviceChanges');

class DeviceChanges with ChangeNotifier {
  final emotiva.Device device;
  late Stream<String> _controlPortStream;
  late Stream<String> _notifyPortStream;
  late Stream<String> _menuNotifyPortStream;

  DeviceChanges(this.device) {
    _controlPortStream = device.controlPortStream(device.address!);
    _notifyPortStream = device.notifyPortStream(device.address!);
    _menuNotifyPortStream = device.menuNotifyPortStream(device.address!);
    _handleControlPackets();
    _log.info('handling control packets');
    _handleNotifyPackets();
    _log.info('handling notify packets');
    _handleMenuNotifyPackets();
    _log.info('handling menu notify packets');
  }

  Future<void> _handleControlPackets() async {
    await for (final packet in _controlPortStream) {
      device.parsePacket(packet);
      notifyListeners();
    }
  }

  Future<void> _handleNotifyPackets() async {
    await for (final packet in _notifyPortStream) {
      device.parsePacket(packet);
      notifyListeners();
    }
  }

  Future<void> _handleMenuNotifyPackets() async {
    await for (final packet in _menuNotifyPortStream) {
      device.parsePacket(packet);
      notifyListeners();
    }
  }
}
