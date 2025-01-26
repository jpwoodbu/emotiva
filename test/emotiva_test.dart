import 'dart:io';

import 'package:emotiva_remote/emotiva.dart';
import 'package:test/test.dart';

String createUpdateXml(String name, String value) {
  return '''<?xml version="1.0" encoding="utf-8"?>
    <emotivaUpdate protocol="3.0">
      <property name="$name" value="$value" visible="true" status="ack"/>
    </emotivaUpdate>''';
}

void main() {
  group('operator ==', () {
    test('Devices with the same IP address are considered the same device', () {
      final device1 = Device(InternetAddress('1.1.1.1'));
      final device2 = Device(InternetAddress('1.1.1.1'));

      expect(device1 == device2, true);
    });

    test('Devices with a different IP address are considered different devices',
        () {
      final device1 = Device(InternetAddress('1.1.1.1'));
      final device2 = Device(InternetAddress('1.1.1.2'));

      expect(device1 == device2, false);
    });

    test('The same device object is considered the same device', () {
      final device = Device(InternetAddress('1.1.1.1'));

      expect(device == device, true);
    });
  });

// TODO: Write some tests for packet parsing. How will I feed in the XML in a
// way that's obviously correct?
  group('Packet parsing', () {
    // TODO: Add test for menu notify packet.

    late Device device;
    setUp(() {
      device = Device(InternetAddress('1.1.1.1'));
    });

    test('power on', () {
      device.power = false;
      device.parsePacket(createUpdateXml('power', 'On'));
      expect(device.power, true);
    });

    test('power off', () {
      device.power = true;
      device.parsePacket(createUpdateXml('power', 'Off'));
      expect(device.power, false);
    });

    test('source', () {
      device.source = 'HDMI 1';
      device.parsePacket(createUpdateXml('source', 'HDMI 2'));
      expect(device.source, 'HDMI 2');
    });
  });
}
