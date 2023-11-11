import 'dart:io';
import 'dart:typed_data';

const int transponderPort = 7000;
InternetAddress broadcastAddress = InternetAddress('255.255.255.255');

void main() async {
  broadcastPing();
}

void broadcastPing() async {
  var data = Uint8List.fromList(
      '<?xml version="1.0" encoding="utf-8"?><emotivaPing />'.codeUnits);
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  socket.broadcastEnabled = true;

  if (socket.send(data, broadcastAddress, transponderPort) == 0) {
    throw 'Unable to send broadcast ping.';
  }
}
