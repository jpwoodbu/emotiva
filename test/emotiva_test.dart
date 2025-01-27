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

    test('mode', () {
      device.mode = 'All stereo';
      device.parsePacket(createUpdateXml('mode', 'Dolby ATMOS'));
      expect(device.mode, 'Dolby ATMOS');
    });

    test('volume is set', () {
      device.volume = -30.0;
      device.parsePacket(createUpdateXml('volume', '-20.0'));
      expect(device.volume, -20.0);
    });

    test('mute', () {
      device.muted = false;
      device.parsePacket(createUpdateXml('volume', 'Mute'));
      expect(device.muted, true);
    });

    test('volume value has extra whitespace', () {
      device.volume = -30.0;
      device.parsePacket(createUpdateXml('volume', '- 9.0'));
      expect(device.volume, -9.0);
    });

    test('loudness', () {
      device.loudness = 'Off';
      device.parsePacket(createUpdateXml('loudness', 'On'));
      expect(device.loudness, 'On');
    });

    test('audio input', () {
      device.audioInput = 'Optical 1';
      device.parsePacket(createUpdateXml('audio_input', 'Optical 2'));
      expect(device.audioInput, 'Optical 2');
    });

    test('video input', () {
      device.videoInput = 'HDMI 1';
      device.parsePacket(createUpdateXml('video_input', 'HDMI 2'));
      expect(device.videoInput, 'HDMI 2');
    });

    test('video format', () {
      device.videoFormat = '1080P/60';
      device.parsePacket(createUpdateXml('video_format', '2160P/60'));
      expect(device.videoFormat, '2160P/60');
    });

    test('video space', () {
      device.videoSpace = '8bits';
      device.parsePacket(createUpdateXml('video_space', '10bits'));
      expect(device.videoSpace, '10bits');
    });

    test('dim', () {
      device.dim = 0;
      device.parsePacket(createUpdateXml('dim', '20'));
      expect(device.dim, 20);
    });

    test('speaker_preset', () {
      device.speakerPreset = 'preset 1';
      device.parsePacket(createUpdateXml('speaker_preset', 'preset 2'));
      expect(device.speakerPreset, 'preset 2');
    });

    group('Trims', () {
      test('center', () {
        device.centerTrim = 0.0;
        device.parsePacket(createUpdateXml('center', '1.0'));
        expect(device.centerTrim, 1.0);
      });

      test('subwoofer', () {
        device.subwooferTrim = 0.0;
        device.parsePacket(createUpdateXml('subwoofer', '1.0'));
        expect(device.subwooferTrim, 1.0);
      });

      test('surround', () {
        device.surroundTrim = 0.0;
        device.parsePacket(createUpdateXml('surround', '1.0'));
        expect(device.surroundTrim, 1.0);
      });

      test('back', () {
        device.backTrim = 0.0;
        device.parsePacket(createUpdateXml('back', '1.0'));
        expect(device.backTrim, 1.0);
      });

      test('width', () {
        device.widthTrim = 0.0;
        device.parsePacket(createUpdateXml('width', '1.0'));
        expect(device.widthTrim, 1.0);
      });

      test('height', () {
        device.heightTrim = 0.0;
        device.parsePacket(createUpdateXml('height', '1.0'));
        expect(device.heightTrim, 1.0);
      });

      test('speaker trim is "None", visibility set to false', () {
        device.visibility['center'] = true;
        device.parsePacket(createUpdateXml('center', 'None'));
        expect(device.visibility['center'], false);
      });

      test('speaker trim is "None", trim set to 0.0', () {
        device.centerTrim = 1.0;
        device.parsePacket(createUpdateXml('center', 'None'));
        expect(device.centerTrim, 0.0);
      });

      test('treble', () {
        device.trebleTrim = 0.0;
        device.parsePacket(createUpdateXml('treble', '-1.0'));
        expect(device.trebleTrim, -1.0);
      });

      test('bass', () {
        device.bassTrim = 0.0;
        device.parsePacket(createUpdateXml('bass', '-1.0'));
        expect(device.bassTrim, -1.0);
      });
    });
  });
}
