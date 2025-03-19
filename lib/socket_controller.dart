import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

final _log = Logger('SocketController');

class SocketController {
  int port;
  InternetAddress address;
  late Stream<Datagram> stream;
  // Making this public as it's useful for fakes.
  final controller = StreamController<Datagram>();
  RawDatagramSocket? _socket;
  StreamSubscription? _subscription;

  SocketController(this.address, this.port) {
    stream = controller.stream;
  }

  Future<void> bind() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    _log.info('Bound to port $port');
    _socket!.writeEventsEnabled = false;
    await _setUpStream();
  }

  Future<void> close() async {
    // Stop the socket event listener, which includes a handler to rebind the
    // socket when it closes, which we don't want running after an explicit call
    // to close().
    await _subscription?.cancel();
    _socket?.close();
  }

  Future<void> _setUpStream() async {
    if (_socket == null) {
      throw 'Streaming cannot be set up without first calling bind().';
    }
    _subscription = _socket!.listen(
      (event) async {
        switch (event) {
          case RawSocketEvent.read:
            final datagram = _socket!.receive();
            if (datagram == null) {
              _log.warning('$event on port $port with a null datagram');
              break;
            }
            // Drop packets not from the provided address.
            if (datagram.address != address) {
              _log.warning('Ignoring packet from ${datagram.address}');
              break;
            }
            controller.add(datagram);
          case RawSocketEvent.readClosed:
          case RawSocketEvent.closed:
            _log.info('$event on port $port');
            await _subscription?.cancel();
            await bind();
          case RawSocketEvent.write:
            _log.warning('$event on port $port');
        }
      },
    );
  }
}

class SendSocketController {
  RawDatagramSocket? socket;
  StreamSubscription? _subscription;

  Future<void> bind() async {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _subscription = socket!.listen((event) async {
      if (event == RawSocketEvent.closed) {
        _log.info('$event on sending socket');
        await _subscription?.cancel();
        await bind();
      }
    });
  }

  Future<void> close() async {
    // Stop the socket event listener, which includes a handler to rebind the
    // socket when it closes, which we don't want running after an explicit call
    // to close().
    await _subscription?.cancel();
    socket?.close();
  }
}
