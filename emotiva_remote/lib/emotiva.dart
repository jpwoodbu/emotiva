// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

const pingPort = 7000;
const transponderPort = 7001;
InternetAddress broadcastAddress = InternetAddress('255.255.255.255');

void main() async {
  await listForTransponder();
}

Future<void> broadcastPing() async {
  var data = Uint8List.fromList(
      '<?xml version="1.0" encoding="utf-8"?><emotivaPing />'.codeUnits);
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  socket.broadcastEnabled = true;
  if (socket.send(data, broadcastAddress, pingPort) == 0) {
    throw 'Unable to send broadcast ping.';
  }
  socket.close();
}

Future<void> listForTransponder() async {
  final stream =
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, transponderPort);
  stream.writeEventsEnabled = false;
  await broadcastPing();
  await for (final event in stream) {
    switch (event) {
      case RawSocketEvent.read:
        final Datagram? datagram = stream.receive();
        print(datagram!.address);
        print(String.fromCharCodes(datagram.data));
        stream.close();
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
