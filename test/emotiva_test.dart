import 'dart:io';

import 'package:emotiva_remote/emotiva.dart';
import 'package:test/test.dart';

void main() {
  group('operator ==', () {
    test('Devices with the same IP address are considered the same device', () {
      final device1 = Device(InternetAddress('1.1.1.1'));
      final device2 = Device(InternetAddress('1.1.1.1'));

      expect(device1 == device2, true);
    });

    test(
        'Devices with a different IP address are considered different devices',
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
}
