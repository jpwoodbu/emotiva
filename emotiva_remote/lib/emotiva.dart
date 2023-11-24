// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

const pingPort = 7000;
const transponderPort = 7001;
const String broadcastAddress = '255.255.255.255';

// main() serves only as a demo. This library is meant to be included in another
// binary.
void main() async {
  // final device = await discovery(1);
  final device = FakeDevice();
  print('address: ${device.address}');
  print('name: ${device.name}');
  Future.delayed(Duration(seconds: 1), () async {
    await device.updateAll();
  });
  Future.delayed(Duration(seconds: 3), () async {
    await device.closeSockets();
  });
  await for (final packet in device.controlPortStream()) {
    device.parsePacket(packet);
    print('power: ${device.power}');
    print('source: ${device.source}');
    print('mode: ${device.mode}');
    print('volume: ${device.volume}');
    print('loudness: ${device.loudness}');
    print('audio input: ${device.audioInput}');
    print('audio bitstream: ${device.audioBitstream}');
    print('audio bits: ${device.audioBits}');
    print('video input: ${device.videoInput}');
    print('video format: ${device.videoFormat}');
    print('video space: ${device.videoSpace}');
  }
}

String _pingRequest() {
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0"');
  builder.element('emotivaPing');
  return builder.buildDocument().toXmlString();
}

Future<Device> discovery(int timeoutSec) async {
  final stream =
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, transponderPort);
  final streamWithTimeout = stream.timeout(Duration(seconds: timeoutSec));
  stream.broadcastEnabled = true;
  final ping = _pingRequest();
  await for (final event in streamWithTimeout) {
    switch (event) {
      case RawSocketEvent.write:
        final bytesSent = stream.send(
            ping.codeUnits, InternetAddress(broadcastAddress), pingPort);
        if (bytesSent == 0) {
          throw 'Unable to send broadcast ping.';
        }
        break;
      case RawSocketEvent.read:
        final datagram = stream.receive();
        stream.close();
        final data = String.fromCharCodes(datagram!.data);
        final device = parseTransponder(data);
        device.address = datagram.address;
        return device;
      case RawSocketEvent.closed:
        break;
      case RawSocketEvent.readClosed:
        break;
      default:
        throw 'Unexpected event $event';
    }
  }
  throw 'Socket closed before receiving a transponder response from a device.';
}

String _textFromElement(XmlNode node, String xpath) {
  try {
    return node.xpath(xpath).first.innerText.trim();
  } catch (e) {
    throw 'Error trying to fetch $xpath: $e';
  }
}

int _intFromElement(XmlNode node, String xpath) {
  var text = _textFromElement(node, xpath);
  try {
    return int.parse(text);
  } on FormatException {
    throw 'Error casting $text to int.';
  } catch (e) {
    throw 'Unkonwn error casting $text to int: $e';
  }
}

Device parseTransponder(String data) {
  final document = XmlDocument.parse(data);
  final root = document.rootElement;
  if (root.name.toString() != 'emotivaTransponder') {
    throw Exception(
        'Received improperly formatted emotivaTransponder response.');
  }
  final device = Device();
  device.model = _textFromElement(root, 'model');
  device.name = _textFromElement(root, 'name');
  device.controlVersion = _textFromElement(root, './control/version');
  device.controlPort = _intFromElement(root, './control/controlPort');
  device.notifyPort = _intFromElement(root, './control/notifyPort');
  device.infoPort = _intFromElement(root, './control/infoPort');
  device.setupPortTcp = _intFromElement(root, './control/setupPortTCP');
  return device;
}

class Device {
  String model = '';
  String name = '';
  String controlVersion = '';
  int controlPort = 0;
  int notifyPort = 0;
  int infoPort = 0;
  int setupPortTcp = 0;
  InternetAddress? address;
  String power = '';
  String source = '';
  String mode = '';
  double volume = 0.0;
  bool muted = false;
  String loudness = '';
  String audioInput = '';
  String audioBitstream = '';
  String audioBits = '';
  String videoInput = '';
  String videoFormat = '';
  String videoSpace = '';
  int dim = 0;
  String speakerPreset = '';
  double centerTrim = 0.0;
  double subwooferTrim = 0.0;
  double surroundTrim = 0.0;
  double backTrim = 0.0;
  // List of tracked fields. Used for *_all() convenience functions.
  static const _fields = {
    'power',
    'source',
    'mode',
    'volume',
    'loudness',
    'audio_input',
    'audio_bitstream',
    'audio_bits',
    'video_input',
    'video_format',
    'video_space',
    'dim',
    'speaker_preset',
    'center',
    'subwoofer',
    'surround',
    'back',
  };
  final List<RawDatagramSocket> _sockets = [];
  final Set<String> _subscribedFields = {};
  // The first sequence number sent by the Emotiva device is 0.
  int _sequenceNumber = -1;

  Stream<String> _socketStream(int port) async* {
    final stream = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    stream.writeEventsEnabled = false;
    _sockets.add(stream);
    await for (final event in stream) {
      switch (event) {
        case RawSocketEvent.read:
          final datagram = stream.receive();
          yield String.fromCharCodes(datagram!.data);
        case RawSocketEvent.closed:
          break;
        case RawSocketEvent.readClosed:
          break;
        default:
          throw 'Unexpected event $event';
      }
    }
  }

  Stream<String> controlPortStream() {
    return _socketStream(controlPort);
  }

  Stream<String> notifyPortStream() {
    return _socketStream(notifyPort);
  }

  Future<void> closeSockets() async {
    for (RawDatagramSocket s in _sockets) {
      s.close();
    }
  }

  Future<void> _send(String request, int destinationPort) async {
    if (address == null) {
      throw 'Address needs to be set first.';
    }
    final stream = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    await for (final event in stream) {
      switch (event) {
        case RawSocketEvent.write:
          final bytesSent =
              stream.send(request.codeUnits, address!, destinationPort);
          stream.close();
          if (bytesSent == 0) {
            throw 'No bytes were sent';
          }
          break;
        case RawSocketEvent.read:
          break;
        case RawSocketEvent.closed:
          break;
        case RawSocketEvent.readClosed:
          break;
        default:
          throw 'Unexpected event $event';
      }
    }
  }

  String _requestWithFields(String requestType, Iterable<String> fields) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element(requestType, nest: () {
      for (final f in fields) {
        builder.element(f);
      }
    });
    return builder.buildDocument().toXmlString();
  }

  String _updateRequest(Iterable<String> fields) {
    return _requestWithFields('emotivaUpdate', fields);
  }

  Future<void> update(Iterable<String> fields) async {
    await _send(_updateRequest(fields), controlPort);
  }

  Future<void> updateAll() async => await update(_fields);

  String _subscribeRequest(Iterable<String> fields) {
    return _requestWithFields('emotivaSubscription', fields);
  }

  Future<void> subscribe(Iterable<String> fields) async {
    await _send(_subscribeRequest(fields), controlPort);
    for (final f in fields) {
      _subscribedFields.add(f);
    }
  }

  Future<void> subscribeAll() async => await subscribe(_fields);

  String _unsubscribeRequest(Iterable<String> fields) {
    return _requestWithFields('emotivaUnsubscribe', fields);
  }

  Future<void> unsubscribe(Iterable<String> fields) async {
    await _send(_unsubscribeRequest(fields), controlPort);
    for (final f in fields) {
      _subscribedFields.remove(f);
    }
  }

  Future<void> unsubscribeAll() async => await unsubscribe(_subscribedFields);

  String _controlRequest(String command, String value, bool ack) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('emotivaControl', nest: () {
      builder.element(command,
          attributes: {'value': value, 'ack': ack ? 'yes' : 'no'});
    });
    return builder.buildDocument().toString();
  }

  Future<void> control(String command,
      {String value = '0', bool ack = false, int timeoutSec = 1}) async {
    final request = _controlRequest(command, value, ack);
    await _send(request, controlPort);
  }

  String _valueAttribute(List<XmlAttribute> attributes) {
    for (final a in attributes) {
      if (a.name.toString() == 'value') {
        return a.value.trim();
      }
    }
    throw 'Element missing value attribute';
  }

  int _getSequence(XmlElement element) {
    for (final a in element.attributes) {
      if (a.name.toString() == 'sequence') {
        try {
          return int.parse(a.value);
        } catch (e) {
          throw 'Unable to parse sequence number: $e';
        }
      }
      throw 'Sequence attribute not found.';
    }
    throw 'Element has no sequence attribute.';
  }

  void parsePacket(String data) {
    final document = XmlDocument.parse(data);
    final root = document.rootElement;
    final packetType = root.name.toString();
    if (packetType == 'emotivaAck') {
      // We don't currently do anything with acks.
      return;
    }
    if (packetType == 'emotivaSubscription') {
      try {
        final sequence = _getSequence(root);
        if (sequence > _sequenceNumber) {
          _sequenceNumber = sequence;
        } else {
          // In this case, we've already seen this packet or a newer packet in
          // the sequence and should disregard it.
          // TODO - add logging when packets are rejected.
          return;
        }
      } catch (e) {
        // If we can't find a sequence number, just assume we should continue
        // processing this packet.
      }
    }
    if (packetType != 'emotivaUpdate' &&
        packetType != 'emotivaNotify' &&
        packetType != 'emotivaSubscription') {
      throw ('Received improperly formatted '
          'emotivaUpdate/emotivaNotify/emotivaSubscription response: '
          '${root.toXmlString(pretty: true)}');
    }
    for (final element in root.childElements) {
      switch (element.name.toString()) {
        case 'power':
          power = _valueAttribute(element.attributes);
          break;
        case 'source':
          source = _valueAttribute(element.attributes);
          break;
        case 'mode':
          mode = _valueAttribute(element.attributes);
          break;
        case 'volume':
          try {
            final reportedVolume = _valueAttribute(element.attributes);
            if (reportedVolume == 'Mute') {
              muted = true;
            } else {
              muted = false;
              volume = double.parse(reportedVolume);
            }
          } catch (e) {
            // If parsing fails, that could mean the device is in standby.
          }
          break;
        case 'loudness':
          loudness = _valueAttribute(element.attributes);
          break;
        case 'audio_input':
          audioInput = _valueAttribute(element.attributes);
          break;
        case 'audio_bitstream':
          audioBitstream = _valueAttribute(element.attributes);
          break;
        case 'audio_bits':
          audioBits = _valueAttribute(element.attributes);
          break;
        case 'video_input':
          videoInput = _valueAttribute(element.attributes);
          break;
        case 'video_format':
          videoFormat = _valueAttribute(element.attributes);
          break;
        case 'video_space':
          videoSpace = _valueAttribute(element.attributes);
          break;
        case 'dim':
          dim = int.parse(_valueAttribute(element.attributes));
          break;
        case 'speaker_preset':
          speakerPreset = _valueAttribute(element.attributes);
          break;
        // Trims are delivered from Emotiva in 0.5dB steps. So we divide by two
        // for better presentation.
        case 'center':
          try {
            centerTrim = double.parse(_valueAttribute(element.attributes));
          } catch (e) {
            // TODO - add logging.
          }
          break;
        case 'subwoofer':
          try {
            subwooferTrim = double.parse(_valueAttribute(element.attributes));
          } catch (e) {
            // TODO - add logging.
          }
          break;
        case 'surround':
          try {
            surroundTrim = double.parse(_valueAttribute(element.attributes));
          } catch (e) {
            // TODO - add logging.
          }
        case 'back':
          try {
            backTrim = double.parse(_valueAttribute(element.attributes));
          } catch (e) {
            // TODO - add logging.
          }
          break;
        default:
          // TODO - add logging.
          break;
      }
    }
  }

  void volumeDelta(double delta) async {
    await control('volume', value: delta.toString());
  }

  void togglePower() async {
    if (power == 'On') {
      await control('power_off');
    } else {
      await control('power_on');
    }
  }

  void toggleLoudness() async {
    await control('loudness');
  }

  void toggleMute() async {
    await control('mute');
  }

  void cycleFrontDisplayBrightness() async {
    await control('dim');
  }

  void toggleMenu() async {
    await control('menu');
  }

  void menuUp() async {
    await control('up');
  }

  void menuDown() async {
    await control('down');
  }

  void menuLeft() async {
    await control('left');
  }

  void menuRight() async {
    await control('right');
  }

  void menuEnter() async {
    await control('enter');
  }

  void info() async {
    await control('info');
  }

  void setHdmi(int input) async {
    await control('hdmi$input');
  }

  void setCoax(int input) async {
    await control('coax$input');
  }

  void setAesEbu() async {
    // coax5 pulls up the AES/EBU input on the RMC-1.
    await control('coax5');
  }

  void setOptical(int input) async {
    await control('optical$input');
  }

  void setArc() async {
    await control('ARC');
  }

  void setUsb() async {
    await control('usb_stream');
  }

  void setTuner() async {
    await control('tuner');
  }

  void setAnalog(int input) async {
    await control('analog$input');
  }

  void setBalancedInput() async {
    // analog5 bring up the balanced input on the RMC-1.
    await control('analog5');
  }

  void setFront() async {
    await control('front_in');
  }

  void modeAuto() async {
    await control('auto');
  }

  void modeStereo() async {
    await control('stereo');
  }

  void modeDirect() async {
    await control('direct');
  }

  void modeReferenceStereo() async {
    await control('reference_stereo');
  }

  void modeDolby() async {
    await control('dolby');
  }

  void modeDts() async {
    await control('dts');
  }

  void modeAllStereo() async {
    await control('all_stereo');
  }

  void speakerPreset1() async {
    await control('preset1');
  }

  void speakerPreset2() async {
    await control('preset2');
  }

  // All trim values are in steps of 0.5dB.
  void trimCenter(double trim) async {
    trim = trim * 2;
    await control('center_trim_set', value: trim.toString());
  }

  void trimSubwoofer(double trim) async {
    trim = trim * 2;
    await control('subwoofer_trim_set', value: trim.toString());
  }

  void trimSurround(double trim) async {
    trim = trim * 2;
    await control('surround_trim_set', value: trim.toString());
  }

  void trimBack(double trim) async {
    trim = trim * 2;
    await control('back_trim_set', value: trim.toString());
  }
}

class FakeDevice extends Device {
  final _controlStream = StreamController<String>();
  final _notifyStream = StreamController<String>();
  int _sequence = 0;

  FakeDevice() {
    model = 'Fake Emotiva';
    name = 'Fake name';
    controlVersion = '42';
    controlPort = 1;
    notifyPort = 2;
    infoPort = 3;
    setupPortTcp = 4;
    power = 'Off';
    source = 'HDMI 1';
    audioInput = 'HDMI 1';
    videoInput = 'HDMI 1';
    mode = 'Dolby Surround';
    audioBitstream = 'PCM 2.0';
    videoFormat = '2160P/60';
    volume = -35.0;
    audioBits = '48kHz 20bits';
    videoSpace = '10bits';
    loudness = 'Off';
    dim = 0;
    speakerPreset = 'Preset 1';
    address = InternetAddress('192.168.42.1');
  }

  Iterable<String> _elementsToFields(Iterable<XmlElement> elements) {
    final fields = <String>[];
    for (final e in elements) {
      fields.add(e.name.toString());
    }
    return fields;
  }

  void _updateBuilder(builder, String field, String value) {
    builder.element(field, attributes: {'value': value, 'status': 'ack'});
  }

  // TODO - There's probably a code reuse opportunity with _getValueForField().
  void _parseUpdateRequest(Iterable<String> fields) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('emotivaUpdate', nest: () {
      for (final f in fields) {
        switch (f) {
          case 'power':
            _updateBuilder(builder, f, power);
            break;
          case 'source':
            _updateBuilder(builder, f, source);
            break;
          case 'mode':
            _updateBuilder(builder, f, mode);
            break;
          case 'volume':
            if (muted) {
              _updateBuilder(builder, f, 'Mute');
            } else {
              _updateBuilder(builder, f, volume.toString());
            }
            break;
          case 'loudness':
            _updateBuilder(builder, f, loudness);
            break;
          case 'audio_input':
            _updateBuilder(builder, f, audioInput);
            break;
          case 'audio_bitstream':
            _updateBuilder(builder, f, audioBitstream);
            break;
          case 'audio_bits':
            _updateBuilder(builder, f, audioBits);
            break;
          case 'video_input':
            _updateBuilder(builder, f, videoInput);
            break;
          case 'video_format':
            _updateBuilder(builder, f, videoFormat);
            break;
          case 'video_space':
            _updateBuilder(builder, f, videoSpace);
            break;
          case 'dim':
            _updateBuilder(builder, f, dim.toString());
            break;
          case 'speaker_preset':
            _updateBuilder(builder, f, speakerPreset);
            break;
          case 'center':
            _updateBuilder(builder, f, centerTrim.toString());
            break;
          case 'subwoofer':
            _updateBuilder(builder, f, subwooferTrim.toString());
            break;
          case 'surround':
            _updateBuilder(builder, f, surroundTrim.toString());
            break;
          case 'back':
            _updateBuilder(builder, f, backTrim.toString());
            break;
          default:
            // Unknown field.
            builder.element(f, attributes: {'value': '', 'status': 'nak'});
            break;
        }
      }
    });
    final response = builder.buildDocument().toXmlString();
    print('response: $response');
    _controlStream.add(response);
  }

  void _toggleLoudness() {
    switch (loudness) {
      case 'On':
        loudness = 'Off';
        break;
      case 'Off':
        loudness = 'On';
        break;
      default:
        // If loudness wasn't set, set it to off since the device probably would
        // have it off by default.
        loudness = 'Off';
        break;
    }
  }

  String _getValue(XmlElement element) {
    try {
      for (final a in element.attributes) {
        if (a.name.toString() == 'value') {
          return a.value;
        }
      }
    } catch (e) {
      print(e);
    }
    return '';
  }

  void _handleHdmiControlRequest(String command, Set<String> updatedFields) {
    final input = command.substring(4);
    videoInput = 'HDMI $input';
    audioInput = 'HDMI $input';
    source = 'HDMI $input';
    updatedFields.add('video_input');
    updatedFields.add('audio_input');
    updatedFields.add('source');
  }

  void _handleCoaxControlRequest(String command, Set<String> updatedFields) {
    final input = command.substring(4);
    if (input == '5') {
      audioInput = 'AES/EBU';
    } else {
      audioInput = 'Coax $input';
    }
    updatedFields.add('audio_input');
  }

  void _handleOpticalControlRequest(String command, Set<String> updatedFields) {
    final input = command.substring(7);
    audioInput = 'Optical $input';
    updatedFields.add('audio_input');
  }

  void _handleAnalogControlRequest(String command, Set<String> updatedFields) {
    final input = command.substring(6);
    if (input == '5') {
      audioInput = 'Balanced In';
    } else {
      audioInput = 'Analog $input';
    }
    updatedFields.add('audio_input');
  }

  double _sanitizeTrimValue(double trim) {
    if (trim > 24.0) {
      return 24.0;
    } else if (trim < -24.0) {
      return -24.0;
    } else {
      return trim;
    }
  }

  void _parseControlRequest(Iterable<XmlElement> elements) {
    Set<String> updatedFields = {};
    for (final element in elements) {
      String field = element.name.toString();
      switch (field) {
        case 'power_on':
          power = 'On';
          updatedFields.add('power');
          break;
        case 'power_off':
          power = 'Off';
          updatedFields.add('power');
          break;
        case 'source':
          source = _getValue(element);
          updatedFields.add(field);
          break;
        case 'mode':
          mode = _getValue(element);
          updatedFields.add(field);
          break;
        case 'volume':
          try {
            final delta = double.parse(_getValue(element));
            volume += delta;
            muted = false;
            updatedFields.add(field);
          } catch (e) {
            print(e);
            // Nothing to do until we start sending Notify packets.
          }
          break;
        case 'loudness':
          _toggleLoudness();
          updatedFields.add(field);
          break;
        case 'audio_input':
          audioInput = _getValue(element);
          updatedFields.add(field);
          break;
        case 'video_input':
          videoInput = _getValue(element);
          updatedFields.add(field);
          break;
        case 'mute':
          if (muted) {
            muted = false;
          } else {
            muted = true;
          }
          // Emotiva uses the volume field to indicate whether the device is
          // muted.
          updatedFields.add('volume');
        case 'dim':
          // cycle through values of 0, 20, 40, 80, and 100.
          if (dim >= 100) {
            dim = 0;
          } else {
            dim += 20;
          }
          break;
        case 'hdmi1':
          _handleHdmiControlRequest(field, updatedFields);
          break;
        case 'hdmi2':
          _handleHdmiControlRequest(field, updatedFields);
          break;
        case 'hdmi3':
          _handleHdmiControlRequest(field, updatedFields);
          break;
        case 'hdmi4':
          _handleHdmiControlRequest(field, updatedFields);
          break;
        case 'hdmi5':
          _handleHdmiControlRequest(field, updatedFields);
          break;
        case 'hdmi6':
          _handleHdmiControlRequest(field, updatedFields);
          break;
        case 'hdmi7':
          _handleHdmiControlRequest(field, updatedFields);
          break;
        case 'hdmi8':
          _handleHdmiControlRequest(field, updatedFields);
          break;
        case 'coax1':
          _handleCoaxControlRequest(field, updatedFields);
          break;
        case 'coax2':
          _handleCoaxControlRequest(field, updatedFields);
          break;
        case 'coax3':
          _handleCoaxControlRequest(field, updatedFields);
          break;
        case 'coax4':
          _handleCoaxControlRequest(field, updatedFields);
          break;
        case 'coax5':
          _handleCoaxControlRequest(field, updatedFields);
        case 'optical1':
          _handleOpticalControlRequest(field, updatedFields);
          break;
        case 'optical2':
          _handleOpticalControlRequest(field, updatedFields);
          break;
        case 'optical3':
          _handleOpticalControlRequest(field, updatedFields);
          break;
        case 'optical4':
          _handleOpticalControlRequest(field, updatedFields);
          break;
        case 'ARC':
          audioInput = 'ARC';
          updatedFields.add('audio_input');
          break;
        case 'usb_stream':
          audioInput = 'USB';
          updatedFields.add('audio_input');
          break;
        case 'tuner':
          audioInput = 'Tuner';
          updatedFields.add('audio_input');
          break;
        case 'analog1':
          _handleAnalogControlRequest(field, updatedFields);
          break;
        case 'analog2':
          _handleAnalogControlRequest(field, updatedFields);
          break;
        case 'analog3':
          _handleAnalogControlRequest(field, updatedFields);
          break;
        case 'analog5':
          _handleAnalogControlRequest(field, updatedFields);
          break;
        case 'front_in':
          audioInput = 'Front';
          updatedFields.add('audio_input');
          break;
        case 'auto':
          // Dolby Surround is a reasonable fake since it's usually what's
          // chosen if the source is 2 channel.
          mode = 'Dolby Surround';
          updatedFields.add('mode');
          break;
        case 'stereo':
          mode = 'Stereo';
          updatedFields.add('mode');
          break;
        case 'direct':
          mode = 'Direct';
          updatedFields.add('mode');
          break;
        case 'reference_stereo':
          mode = 'Reference Stereo';
          updatedFields.add('mode');
          break;
        case 'dolby':
          mode = 'Dolby Surround';
          updatedFields.add('mode');
          break;
        case 'dts':
          mode = 'dts Neural:X';
          updatedFields.add('mode');
          break;
        case 'all_stereo':
          mode = 'All Stereo';
          updatedFields.add('mode');
          break;
        case 'preset1':
          speakerPreset = 'Preset 1';
          updatedFields.add('speaker_preset');
          break;
        case 'preset2':
          speakerPreset = 'Preset 2';
          updatedFields.add('speaker_preset');
          break;
        case 'center_trim_set':
          final rawTrim = double.parse(_getValue(element));
          final sanitizedTrim = _sanitizeTrimValue(rawTrim);
          // Divide by 2 because this normally happens inside the Emotiva
          // device.
          centerTrim = sanitizedTrim / 2;
          updatedFields.add('center');
          break;
        case 'subwoofer_trim_set':
          final rawTrim = double.parse(_getValue(element));
          final sanitizedTrim = _sanitizeTrimValue(rawTrim);
          subwooferTrim = sanitizedTrim / 2;
          updatedFields.add('subwoofer');
          break;
        case 'surround_trim_set':
          final rawTrim = double.parse(_getValue(element));
          final sanitizedTrim = _sanitizeTrimValue(rawTrim);
          surroundTrim = sanitizedTrim / 2;
          updatedFields.add('surround');
          break;
        case 'back_trim_set':
          final rawTrim = double.parse(_getValue(element));
          final sanitizedTrim = _sanitizeTrimValue(rawTrim);
          backTrim = sanitizedTrim / 2;
          updatedFields.add('back');
          break;
        default:
          // Unknown field.
          break;
      }
    }
    _notifySubscribers(updatedFields);
  }

  void _notifySubscribers(Set<String> updatedFields) {
    // Note that updatedFields has already been vetted by other methods before
    // this method is called.
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('emotivaNotify',
        attributes: {'sequence': _sequence.toString()}, nest: () {
      for (final field in updatedFields) {
        var value = _getValueForField(field);
        // TODO - only include the visible attribute for the fields documented
        // in the API docs where it applies.
        builder.element(field, attributes: {'value': value, 'visible': 'true'});
      }
    });
    final response = builder.buildDocument().toXmlString();
    print('response: $response');
    _sequence++;
    _notifyStream.add(response);
  }

  String _getValueForField(String field) {
    switch (field) {
      case 'power':
        return power;
      case 'source':
        return source;
      case 'mode':
        return mode;
      case 'volume':
        if (muted) {
          return 'Mute';
        }
        return volume.toString();
      case 'loudness':
        return loudness;
      case 'audio_input':
        return audioInput;
      case 'audio_bitstream':
        return audioBitstream;
      case 'audio_bits':
        return audioBits;
      case 'video_input':
        return videoInput;
      case 'video_format':
        return videoFormat;
      case 'video_space':
        return videoSpace;
      case 'dim':
        return dim.toString();
      case 'speaker_preset':
        return speakerPreset;
      case 'center':
        return centerTrim.toString();
      case 'subwoofer':
        return subwooferTrim.toString();
      case 'surround':
        return surroundTrim.toString();
      case 'back':
        return backTrim.toString();
      default:
        throw 'Unsupported field: $field';
    }
  }

  void _parseSubscriptionRequest(Iterable<String> fields) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('emotivaSubscription', nest: () {
      for (final field in fields) {
        if (Device._fields.contains(field)) {
          _subscribedFields.add(field);
          builder.element(field, attributes: {
            'value': _getValueForField(field),
            'status': 'ack',
            'visible': 'true',
          });
        } else {
          // Return nak status for unknown fields.
          builder.element(field, attributes: {'status': 'nak'});
        }
      }
    });
    final response = builder.buildDocument().toXmlString();
    print('response: $response');
    _controlStream.add(response);
  }

  void _parseUnsubscribeRequest(Iterable<String> fields) {
    String status = 'nak';
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('emotivaUnsubscribe', nest: () {
      for (final f in fields) {
        _subscribedFields.remove(f);
        if (Device._fields.contains(f)) {
          status = 'ack';
        }
        builder.element(f, attributes: {'status': status});
      }
    });
  }

  void _parseRequest(String request) {
    final document = XmlDocument.parse(request);
    final root = document.rootElement;
    final requestType = root.name.toString();
    final fields = _elementsToFields(root.childElements);
    print('request: $request');
    switch (requestType) {
      case 'emotivaControl':
        _parseControlRequest(root.childElements);
        break;
      case 'emotivaUpdate':
        _parseUpdateRequest(fields);
        break;
      case 'emotivaSubscription':
        _parseSubscriptionRequest(fields);
        break;
      case 'emotivaUnsubscribe':
        _parseUnsubscribeRequest(fields);
        break;
      default:
        throw 'Unknown request type $requestType';
    }
  }

  @override
  // destinationPort seems to always be controlPort.
  Future<void> _send(String request, int destinationPort) async {
    return _parseRequest(request);
  }

  @override
  Stream<String> controlPortStream() async* {
    await for (final data in _controlStream.stream) {
      yield data;
    }
  }

  @override
  Stream<String> notifyPortStream() async* {
    await for (final data in _notifyStream.stream) {
      yield data;
    }
  }
}

Future<FakeDevice> futureFakeDevice() async {
  return FakeDevice();
}
