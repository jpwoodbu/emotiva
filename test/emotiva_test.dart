import 'dart:io';

import 'package:emotiva_remote/emotiva.dart';
import 'package:test/test.dart';

String createUpdateXml(String name, String value, {bool visible = true}) {
  return '''<?xml version="1.0" encoding="utf-8"?>
    <emotivaUpdate protocol="3.0">
      <property name="$name" value="$value"
        visible="${visible.toString().toLowerCase()}" status="ack"/>
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
      device.loudness = false;
      device.parsePacket(createUpdateXml('loudness', 'On'));
      expect(device.loudness, true);
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

      test('mode_ref_stereo', () {
        device.visibility['mode_ref_stereo'] = false;
        device.parsePacket(
            createUpdateXml('mode_ref_stereo', 'unused', visible: true));
        expect(device.visibility['mode_ref_stereo'], true);
      });

      test('mode_stereo', () {
        device.visibility['mode_stereo'] = false;
        device.parsePacket(
            createUpdateXml('mode_stereo', 'unused', visible: true));
        expect(device.visibility['mode_stereo'], true);
      });

      test('mode_music', () {
        device.visibility['mode_music'] = false;
        device.parsePacket(
            createUpdateXml('mode_music', 'unused', visible: true));
        expect(device.visibility['mode_music'], true);
      });

      test('mode_music', () {
        device.visibility['mode_music'] = false;
        device.parsePacket(
            createUpdateXml('mode_music', 'unused', visible: true));
        expect(device.visibility['mode_music'], true);
      });

      test('mode_movie', () {
        device.visibility['mode_movie'] = false;
        device.parsePacket(
            createUpdateXml('mode_movie', 'unused', visible: true));
        expect(device.visibility['mode_movie'], true);
      });

      test('mode_direct', () {
        device.visibility['mode_direct'] = false;
        device.parsePacket(
            createUpdateXml('mode_direct', 'unused', visible: true));
        expect(device.visibility['mode_direct'], true);
      });

      test('mode_dolby', () {
        device.visibility['mode_dolby'] = false;
        device.parsePacket(
            createUpdateXml('mode_dolby', 'unused', visible: true));
        expect(device.visibility['mode_dolby'], true);
      });

      test('mode_all_stereo', () {
        device.visibility['mode_all_stereo'] = false;
        device.parsePacket(
            createUpdateXml('mode_all_stereo', 'unused', visible: true));
        expect(device.visibility['mode_all_stereo'], true);
      });

      test('mode_auto', () {
        device.visibility['mode_auto'] = false;
        device.parsePacket(
            createUpdateXml('mode_auto', 'unused', visible: true));
        expect(device.visibility['mode_auto'], true);
      });

      test('mode_surround', () {
        device.visibility['mode_surround'] = false;

        device.parsePacket(
            createUpdateXml('mode_surround', 'unused', visible: true));

        expect(device.visibility['mode_surround'], true);
      });

      test('selected_mode', () {
        device.selectedMode = 'Dolby Surround';
        device.parsePacket(createUpdateXml('selected_mode', 'Auto'));
        expect(device.selectedMode, 'Auto');
      });

      test('selected_movie_music', () {
        device.selectedMovieMusic = 'Movie';
        device.parsePacket(createUpdateXml('selected_movie_music', 'Music'));
        expect(device.selectedMovieMusic, 'Music');
      });

      test('zone2_power on', () {
        device.zone2Power = false;
        device.parsePacket(createUpdateXml('zone2_power', 'On'));
        expect(device.zone2Power, true);
      });

      test('zone2_power off', () {
        device.zone2Power = true;
        device.parsePacket(createUpdateXml('zone2_power', 'Off'));
        expect(device.zone2Power, false);
      });
    });
  });
}
