// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

const pingPort = 7000;
const transponderPort = 7001;
const String broadcastAddress = '255.255.255.255';

void main() async {
  var device = await discovery(1);
  print('address: ${device.address}');
  print('name: ${device.name}');
  await device.updateAll();
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
        var bytesSent = stream.send(
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
    return node.xpath(xpath).first.innerText;
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
  var root = document.rootElement;
  if (root.name.toString() != 'emotivaTransponder') {
    throw Exception(
        'Received improperly formatted emotivaTransponder response.');
  }
  var device = Device();
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
  String loudness = '';
  String audioInput = '';
  String audioBitstream = '';
  String audioBits = '';
  String videoInput = '';
  String videoFormat = '';
  String videoSpace = '';
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
    'video_space'
  };

  Future<void> update(Iterable<String> fields, {int timeoutSec = 1}) async {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('emotivaUpdate', nest: () {
      for (final f in fields) {
        builder.element(f);
      }
    });
    final request = builder.buildDocument();

    // Set the source port to the controlPort since no matter what our source
    // port is, the device will send the response to the controlPort.
    // WARNING: This approach won't work if we want to listen for changes to
    // subscribed fields as those messages will also arrive on the controlPort
    // and we'll need to have a long running lister on that port to catch them.
    final stream =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, controlPort);
    final streamWithTimeout = stream.timeout(Duration(seconds: timeoutSec));
    await for (final event in streamWithTimeout) {
      switch (event) {
        case RawSocketEvent.write:
          stream.send(request.toXmlString().codeUnits, address!, controlPort);
          break;
        case RawSocketEvent.read:
          final datagram = stream.receive();
          stream.close();
          final data = String.fromCharCodes(datagram!.data);
          parseUpdate(data);
          return;
        case RawSocketEvent.closed:
          break;
        case RawSocketEvent.readClosed:
          break;
        default:
          throw 'Unexpected event $event';
      }
    }
  }

  Future<void> updateAll({int timeoutSec = 1}) async {
    await update(_fields);
  }

  String _valueAttribute(List<XmlAttribute> attributes) {
    for (final a in attributes) {
      if (a.name.toString() == 'value') {
        return a.value.trim();
      }
    }
    throw 'Element missing value attribute';
  }

  void parseUpdate(String data) {
    final document = XmlDocument.parse(data);
    var root = document.rootElement;
    if (root.name.toString() != 'emotivaUpdate') {
      throw Exception('Received improperly formatted emotivaUpdate response.');
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
          volume = double.parse(_valueAttribute(element.attributes));
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
      }
    }
  }
}
