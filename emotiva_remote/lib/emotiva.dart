// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

const pingPort = 7000;
const transponderPort = 7001;
InternetAddress broadcastAddress = InternetAddress('255.255.255.255');

void main() async {
  var device = await listForTransponder(1);
  print(device.address);
  print(device.name);
  await device.update();
}

Future<void> broadcastPing() async {
  var data = Uint8List.fromList(
      '<?xml version="1.0" encoding="utf-8"?><emotivaPing />'.codeUnits);
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  socket.broadcastEnabled = true;
  if (socket.send(data, broadcastAddress, pingPort) == 0) {
    throw 'Unable to send broadcast ping.';
  }
  print('Sent broadcast ping.');
  socket.close();
}

Future<Device> listForTransponder(int timeoutSec) async {
  final stream =
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, transponderPort);
  stream.writeEventsEnabled = false;
  final streamWithTimeout = stream.timeout(Duration(seconds: timeoutSec));
  await broadcastPing();
  await for (final event in streamWithTimeout) {
    switch (event) {
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
    print('Error trying to fetch $xpath: $e');
  }
  return '';
}

int _intFromElement(XmlNode node, String xpath) {
  var text = _textFromElement(node, xpath);
  // TODO - maybe use int.tryParse() and allow the fields to be null on the
  // Device class.
  try {
    return int.parse(text);
  } on FormatException {
    print('Error casting $text to int.');
  } catch (e) {
    print('Unkonwn error casting $text to int: $e');
  }
  return 0;
}

Device parseTransponder(String data) {
  // TODO - handle XmlException.
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

  Future<void> update({int timeoutSec = 1}) async {
    // TODO - use the xml builder instead.
    var text = ('<?xml version="1.0" encoding="utf-8"?>'
        '<emotivaUpdate>'
        '<power />'
        '<volume />'
        '</emotivaUpdate>');

    // Set the source port to the controlPort since no matter what our source
    // port is, the device will send the response to the controlPort.
    final stream =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, controlPort);
    final streamWithTimeout = stream.timeout(Duration(seconds: timeoutSec));
    await for (final event in streamWithTimeout) {
      switch (event) {
        case RawSocketEvent.write:
          stream.send(text.codeUnits, address!, controlPort);
          break;
        case RawSocketEvent.read:
          final datagram = stream.receive();
          stream.close();
          final data = String.fromCharCodes(datagram!.data);
          print(data);
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
}
