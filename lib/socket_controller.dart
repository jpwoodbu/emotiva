import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

final _log = Logger('SocketController');

/// An intermediate for socket consumers to manage the socket lifecycle.
///
/// When the socket is closed by the OS, which can easily happen on a mobile OS
/// when the app is backgrounded, the socket is automatically recreated.
/// The [stream] used by consumers of this class is not disrupted when the
/// socket needs to be recreated.
///
/// This class is meant for sockets which only receieve data. If you want to be
/// able to send data, use [SendSocketController].
class SocketController {
  /// The port on which to listen for inbound [Datagram]s.
  int port;

  /// The address of the Emotiva device. [Datagram]s received from other
  /// addresses will be discard.
  InternetAddress address;

  /// Consumers should listen to this stream to read the received [Datagram]s.
  late Stream<Datagram> stream;

  /// The [StreamController] managing [stream]. It should be considered private,
  /// but it has been made public for testing.
  final controller = StreamController<Datagram>();
  RawDatagramSocket? _socket;
  StreamSubscription? _subscription;

  SocketController(this.address, this.port) {
    stream = controller.stream;
  }

  /// Bind the socket and set up [stream] to emit its [Datagram]s.
  Future<void> bind() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    _log.info('Bound to port $port');
    _socket!.writeEventsEnabled = false;
    await _setUpStream();
  }

  /// Close the underlying socket.
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
              return;
            }
            // Drop packets not from the provided address.
            if (datagram.address != address) {
              _log.warning('Ignoring packet from ${datagram.address}');
              return;
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

/// An intermediate for socket users to manage the socket lifecycle.
///
/// When the socket is closed by the OS, which can easily happen on a mobile OS
/// when the app is backgrounded, the socket is automatically recreated.
///
/// This class is meant for sockets which only send data. If you want to receive
/// data, use [SocketController].
class SendSocketController {
  /// The underlying socket. Users should use it directly to send data.
  RawDatagramSocket? socket;
  StreamSubscription? _subscription;

  /// Bind [socket].
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

  /// Close [socket].
  Future<void> close() async {
    // Stop the socket event listener, which includes a handler to rebind the
    // socket when it closes, which we don't want running after an explicit call
    // to close().
    await _subscription?.cancel();
    socket?.close();
  }
}
