import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

import 'package:emotiva_remote/socket_controller.dart';

final _log = Logger('Emotiva');
const int _pingPort = 7000;
const int _transponderPort = 7001;
const String _broadcastAddress = '255.255.255.255';
// The highest protocol version this library supports.
const String _protocolVersion = '3.0';

String _pingRequest() {
  final builder = XmlBuilder()
    ..processing('xml', 'version="1.0"')
    ..element('emotivaPing', attributes: {'protocol': _protocolVersion});
  return builder.buildDocument().toXmlString();
}

/// Discovers an Emotiva device on the network and returns a [Device].
///
/// A socket is opened to listen for a transponder packet from an Emotiva
/// device. While open, a ping packet is broadcast on the network. The listening
/// socket waits for [timeoutSec] before giving up and throwing an exception.
Future<Device> discover(int timeoutSec) async {
  final socket = await RawDatagramSocket.bind(
    InternetAddress.anyIPv4,
    _transponderPort,
  );
  socket.broadcastEnabled = true;
  final stream = socket.timeout(Duration(seconds: timeoutSec));
  final ping = _pingRequest();
  await for (final event in stream) {
    switch (event) {
      case .write:
        final bytesSent = socket.send(
          ping.codeUnits,
          InternetAddress(_broadcastAddress),
          _pingPort,
        );
        if (bytesSent == 0) {
          throw 'Unable to send broadcast ping.';
        }
        _log.info('sent: $ping');
      case .read:
        final datagram = socket.receive();
        socket.close();
        final data = String.fromCharCodes(datagram!.data);
        _log.info('received: $data');
        final device = parseTransponder(data, datagram.address);
        return device;
      case .closed:
      case .readClosed:
        break;
    }
  }
  throw 'Socket closed before receiving a transponder response from a device.';
}

/// Continuously discovers Emotiva devices on the network.
///
/// [stream] yields [Device] objects as they are discovered. A ping request is
/// broadcast on the network every 5s once [stream] is called and until [close]
/// is called. [close] also tears down the listening socket.
///
/// It is up to the caller of [stream] to deduplicate yielded devices. The
/// [Device] objects can be added to a [Set] to achieve this.
class MultiDeviceDiscover {
  RawDatagramSocket? _socket;
  Timer? _pinger;

  void close() {
    final socket = _socket;
    final pinger = _pinger;
    if (socket != null) {
      socket.close();
      _log.info('No longer listening for Emotiva transponder packets.');
      _socket = null;
    }
    if (pinger != null) {
      pinger.cancel();
      _pinger = null;
    }
  }

  void _ping() {
    if (_socket case RawDatagramSocket socket) {
      final ping = _pingRequest();
      final bytesSent = socket.send(
        ping.codeUnits,
        InternetAddress(_broadcastAddress),
        _pingPort,
      );
      if (bytesSent == 0) {
        _log.severe('Unable to send broadcast ping.');
      } else {
        _log.info('sent: $ping');
      }
    }
  }

  Stream<Device> stream() async* {
    if (_socket != null) {
      throw StateError(
        'The socket was already established. '
        'Was stream() called more than once without calling close()?',
      );
    }
    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _transponderPort,
    );
    final socket = _socket!;
    socket.broadcastEnabled = true;
    _ping();
    _pinger = Timer.periodic(const Duration(seconds: 5), (_) => _ping());
    await for (final event in socket) {
      switch (event) {
        case RawSocketEvent.read:
          final datagram = socket.receive();
          if (datagram == null) {
            // I'm not sure if this indicates a problem, but I at least want to
            // log it to see if it's happening.
            _log.warning('Got a socket read event with an empty datagram');
            continue;
          }
          final data = String.fromCharCodes(datagram.data);
          _log.info('received: $data');
          final device = parseTransponder(data, datagram.address);
          yield device;
        case RawSocketEvent.write:
        case RawSocketEvent.closed:
        case RawSocketEvent.readClosed:
          break;
        default:
          throw 'Unexpected event $event';
      }
    }
  }
}

extension _XmlNodeXPathExtension on XmlNode {
  String textAt(String xpath) {
    try {
      // ignore: experimental_member_use
      return this.xpath(xpath).first.innerText.trim();
    } catch (e) {
      throw FormatException('Error trying to fetch $xpath: $e');
    }
  }

  int intAt(String xpath) {
    final text = textAt(xpath);
    try {
      return int.parse(text);
    } on FormatException {
      throw FormatException('Error casting $text to int.');
    } catch (e) {
      throw FormatException('Unknown error casting $text to int: $e');
    }
  }
}

// Made public only for testing.
Device parseTransponder(String data, InternetAddress address) {
  final document = XmlDocument.parse(data);
  final root = document.rootElement;
  if (root.name.toString() != 'emotivaTransponder') {
    throw Exception(
      'Received improperly formatted emotivaTransponder response.',
    );
  }
  String model;
  String name;
  String controlVersion;
  int controlPort;
  int notifyPort;
  try {
    model = root.textAt('model');
    name = root.textAt('name');
    controlVersion = root.textAt('./control/version');
    controlPort = root.intAt('./control/controlPort');
    notifyPort = root.intAt('./control/notifyPort');
  } catch (e) {
    _log.severe(e);
    throw ('The response from your Emotiva processor is missing some required '
        'fields. Your Emotiva processor may require a firmware update to work '
        'with this app.');
  }
  final device = Device(address, controlPort, notifyPort)
    ..model = model
    ..name = name
    ..controlVersion = controlVersion;
  // Some fields aren't used by this library. And some fields are absent on some
  // devices in the fields. E.g. an XMC-1, perhaps running an older firmware.
  // For those fields, log warnings instead of hard failing.
  try {
    // menuNotifyPort is not available on processors using protocol versions <
    // 2.1.
    device.menuNotifyPort = root.intAt('./control/menuNotifyPort');
    device.infoPort = root.intAt('./control/infoPort');
    device.dataRevision = root.textAt('dataRevision');
    device.setupPortTcp = root.intAt('./control/setupPortTCP');
    device.setupXmlVersion = root.intAt('./control/setupXMLVersion');
    device.keepAlive = root.intAt('./control/keepAlive');
  } catch (e) {
    _log.warning('Missing optional element in transponder packet: $e');
  }
  return device;
}

enum TunerBand { unknown, am, fm }

/// Converts a [trim] value in dB into a value compatible with the Emotiva API.
///
/// The Emotiva API takes [trim] values as a double between -24 and 24
/// representing 0.5dB steps between -12dB and +12dB.
String _convertTrim(double trim) {
  trim = trim * 2;
  return trim.toString();
}

/// A model of an Emotiva device.
class Device(
  var InternetAddress address,
  var int controlPort,
  var int notifyPort,
) {
  String model = '';
  String dataRevision = '';
  String name = '';
  String controlVersion = '';
  int infoPort = 0;
  int setupPortTcp = 0;
  int setupXmlVersion = 0;
  int keepAlive = 0;
  bool power = false;
  String source = '';
  String mode = '';
  double volume = 0.0;
  bool muted = false;
  bool loudness = false;
  String audioInput = '';
  String audioBitstream = '';
  String audioBits = '';
  String videoInput = '';
  String videoFormat = '';
  String videoSpace = '';
  int dim = 0;
  String speakerPreset = '';
  double centerTrim = 0.0;
  double widthTrim = 0.0;
  double subwooferTrim = 0.0;
  double surroundTrim = 0.0;
  double backTrim = 0.0;
  double heightTrim = 0.0;
  double trebleTrim = 0.0;
  double bassTrim = 0.0;
  String selectedMode = '';
  String selectedMovieMusic = '';
  bool menuDisplayed = false;
  Menu menuContents = Menu();
  bool zone2Power = false;
  double zone2Volume = 0.0;
  bool zone2Muted = false;
  String zone2Input = '';
  TunerBand tunerBand = .unknown;
  String tunerChannel = '';
  String tunerSignal = '';
  String tunerProgram = '';
  String tunerRds = '';
  Map<String, String> names = {
    'input_1': '',
    'input_2': '',
    'input_3': '',
    'input_4': '',
    'input_5': '',
    'input_6': '',
    'input_7': '',
    'input_8': '',
  };
  Map<String, bool> visibility = {
    'input_1': true,
    'input_2': true,
    'input_3': true,
    'input_4': true,
    'input_5': true,
    'input_6': true,
    'input_7': true,
    'input_8': true,
    'mode_ref_stereo': true,
    'mode_stereo': true,
    'mode_music': true,
    'mode_movie': true,
    'mode_direct': true,
    'mode_dolby': true,
    'mode_dts': true,
    'mode_all_stereo': true,
    'mode_auto': true,
    'mode_surround': true,
    'center': true,
    'subwoofer': true,
    'surround': true,
    'back': true,
    // height and width trims are not available in protocol version <3.0. By
    // default, make their related widgets invisible.
    'height': false,
    'width': false,
  };
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
    'width',
    'subwoofer',
    'surround',
    'back',
    'height',
    'treble',
    'bass',
    'selected_mode',
    'selected_movie_music',
    'input_1',
    'input_2',
    'input_3',
    'input_4',
    'input_5',
    'input_6',
    'input_7',
    'input_8',
    'mode_ref_stereo',
    'mode_stereo',
    'mode_music',
    'mode_movie',
    'mode_direct',
    'mode_dolby',
    'mode_dts',
    'mode_all_stereo',
    'mode_auto',
    'mode_surround',
    'menu',
    'menu_update',
    'zone2_power',
    'zone2_volume',
    'zone2_input',
    'tuner_band',
    'tuner_channel',
    'tuner_signal',
    'tuner_program',
    'tuner_RDS',
  };
  final Set<String> _subscribedFields = {};
  // Sequence numbers sent bn Emotiva are an unsigned int. -1 indicates we've
  // not yet gotten a real sequence number.
  int _sequenceNumber = -1;
  // late SocketController _control;
  // late SocketController _notify;
  int? _menuNotifyPort;
  SocketController? _menuNotify;
  final _sender = SendSocketController();
  // TODO(jpwoodbu) Do we really need to listen on this port? The docs say we
  // do, but from what I've seen in logging, we do not. I think this is only the
  // port number we need to use to send control commands to the processor.
  final _control = SocketController(address, controlPort);
  final _notify = SocketController(address, notifyPort);

  // The hashCode and == operator override allow Device to be placed into a Set.
  // This is useful when discovering multiple Emotiva devices on a network.
  // The assumption is that each unique device will have its own IP address.
  @override
  int get hashCode => address.address.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Device && address.address == other.address.address;
  }

  /// The protocol version to request after device discovery.
  String __protocolVersion() {
    // We currently only support minor version 0 of major version 3.
    if (controlVersion.startsWith('3.')) return _protocolVersion;
    // Fall back to 2.0 otherwise.
    return '2.0';
  }

  set menuNotifyPort(int? port) {
    _menuNotifyPort = port;
    if (port != null) _menuNotify = SocketController(address, port);
  }

  int? get menuNotifyPort => _menuNotifyPort;

  Future<void> bindSockets() async {
    _log.info('Binding all sockets.');
    await _control.bind();
    await _notify.bind();
    await _menuNotify?.bind();
    await _sender.bind();
  }

  Future<void> closeSockets() async {
    _log.info('Closing all sockets.');
    await _control.close();
    await _notify.close();
    await _menuNotify?.close();
    await _sender.close();
  }

  Stream<String> _decode(Stream<Datagram> stream) async* {
    await for (final datagram in stream) {
      final packet = String.fromCharCodes(datagram.data);
      _log.info('received: $packet');
      yield packet;
    }
  }

  /// Stream of messages arriving on the control stream.
  Stream<String> controlStream() => _decode(_control.stream);

  /// Stream of messages arriving on the notify stream.
  Stream<String> notifyStream() => _decode(_notify.stream);

  /// Stream of messages arriving on the menu notify stream.
  ///
  /// A null assertion error is thrown if this is called when [menuNotifyPort]
  /// is null.
  Stream<String> menuNotifyStream() => _decode(_menuNotify!.stream);

  void _send(String request, int destinationPort) async {
    _log.info('sending: $request');
    // OMG, send() does not return a Future. Since UDP is fire-and-forget, I
    // don't suppose it was necessary for it to.
    final bytesSent = _sender.socket!.send(
      request.codeUnits,
      address,
      destinationPort,
    );
    _log.fine('bytes sent: $bytesSent; ${address.address}:$destinationPort');
    if (bytesSent == 0) {
      throw 'No bytes were sent';
    }
  }

  String _requestWithFields(String requestType, Iterable<String> fields) {
    final builder = XmlBuilder()..processing('xml', 'version="1.0"');
    builder.element(
      requestType,
      attributes: {'protocol': __protocolVersion()},
      nest: () {
        for (final f in fields) {
          builder.element(f);
        }
      },
    );
    return builder.buildDocument().toXmlString();
  }

  String _updateRequest(Iterable<String> fields) {
    return _requestWithFields('emotivaUpdate', fields);
  }

  /// Sends a request to get the current values for [fields].
  void update(Iterable<String> fields) {
    return _send(_updateRequest(fields), controlPort);
  }

  /// Sends a request to get the current value for all supported fields.
  ///
  /// Supported fields are a hardcoded list of fields understood by this
  /// library.
  void updateAll() => update(_fields);

  String _subscribeRequest(Iterable<String> fields) {
    return _requestWithFields('emotivaSubscription', fields);
  }

  /// Sends a request to get notified when any of [fields] change in value.
  void subscribe(Iterable<String> fields) {
    // Since we're going to be looping over this, we should make a local copy to
    // avoid getting a ConcurrentModificationError.
    final localFields = Set<String>.from(fields);
    _send(_subscribeRequest(localFields), controlPort);
    for (final f in localFields) {
      _subscribedFields.add(f);
    }
  }

  /// Sends a request to get notified when any of the supported fields change.
  ///
  /// Supported fields are a hardcoded list of fields understood by this
  /// library.
  void subscribeAll() => subscribe(_fields);

  String _unsubscribeRequest(Iterable<String> fields) {
    return _requestWithFields('emotivaUnsubscribe', fields);
  }

  /// Sends a request to stop being notified when [fields] change.
  ///
  /// Supported fields are a hardcoded list of fields understood by this
  /// library.
  void unsubscribe(Iterable<String> fields) {
    // Since we're going to be looping over this, we should make a local copy to
    // avoid getting a ConcurrentModificationError.
    final localFields = Set<String>.from(fields);
    _send(_unsubscribeRequest(localFields), controlPort);
    for (final f in localFields) {
      _subscribedFields.remove(f);
    }
  }

  /// Sends a request to stop being notified when supported fields change.
  void unsubscribeAll() => unsubscribe(_subscribedFields);

  String _controlRequest(String command, String value, bool ack) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element(
      'emotivaControl',
      attributes: {'protocol': __protocolVersion()},
      nest: () {
        builder.element(
          command,
          attributes: {'value': value, 'ack': ack ? 'yes' : 'no'},
        );
      },
    );
    return builder.buildDocument().toString();
  }

  /// Sends a control command.
  ///
  /// Some commands have a [value]. E.g. increasing the volume by 1dB would have
  /// a [command] of 'volume' and a [value] of '1'.
  ///
  /// You can send arbitrary commands with this method, but prefer to use the
  /// public interface instead. E.g. call [volumeDelta] instead of [control]
  /// with [command] and [value] arguments.
  ///
  /// Setting [ack] to true will ask that the Emotiva device respond with an ack
  /// message if it received the command. An ack message does not indicate that
  /// it understood and acted on the command; only that the command message was
  /// received. This library currently ignores ack messages.
  void control(String command, {String value = '0', bool ack = false}) {
    final request = _controlRequest(command, value, ack);
    return _send(request, controlPort);
  }

  String _valueAttribute(List<XmlAttribute> attributes) {
    for (final a in attributes) {
      if (a.name.toString() == 'value') {
        return a.value.trim();
      }
    }
    throw 'Element missing value attribute';
  }

  bool _visibleAttribute(List<XmlAttribute> attributes) {
    for (final a in attributes) {
      if (a.name.toString() == 'visible') {
        return bool.parse(a.value.trim(), caseSensitive: false);
      }
    }
    _log.severe('Element missing visible attribute: $attributes');
    // Usually visible is set to true. Default to assuming it is.
    return true;
  }

  String _nameAttribute(List<XmlAttribute> attributes) {
    for (final a in attributes) {
      if (a.name.toString() == 'name') {
        return a.value.trim();
      }
    }
    _log.severe('Element missing name attribute: $attributes');
    return 'Unknown';
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
    }
    throw 'Element has no sequence attribute.';
  }

  double _getSpeakerTrim(XmlElement element) {
    final trim = _valueAttribute(element.attributes);
    final speaker = _nameAttribute(element.attributes);
    if (trim == 'None') {
      visibility[speaker] = false;
      return 0.0;
    } else {
      visibility[speaker] = true;
      return _getDoubleAttribute(trim);
    }
  }

  double _getDoubleAttribute(String value) {
    try {
      // Remove any whitespace that might break double.parse().
      return double.parse(value.replaceAll(RegExp(r'\s+'), ''));
    } catch (e) {
      _log.severe('Casting value to double failed for: $value: $e');
      return 0.0;
    }
  }

  String _getProtocolAttribute(XmlElement element) {
    for (final a in element.attributes) {
      if (a.name.toString() == 'protocol') {
        return a.value.trim();
      }
    }
    return '';
  }

  String _getNameAttribute(XmlElement element) {
    for (final a in element.attributes) {
      if (a.name.toString() == 'name') {
        return a.value.trim();
      }
    }
    throw 'Element has no name attribute: ${element.toXmlString()}';
  }

  /// Parses all message types other than transponder messages.
  ///
  /// This method is made public so that callers can inject logic around a
  /// stream yielding a message and the message being parsed (which might update
  /// data in this object). E.g. updating a UI when data in this object changes.
  ///
  /// [data] should be a message yielded by [controlStream] or
  /// [notifyStream].
  void parsePacket(String data) {
    final document = XmlDocument.parse(data);
    final root = document.rootElement;
    final packetType = root.name.toString();
    if (packetType == 'emotivaAck') {
      // We don't currently do anything with acks.
      _log.info('Received an ack message: ${root.toXmlString()}');
      return;
    }
    if (packetType == 'emotivaUnsubscribe') {
      // If we get a response from an unsubscribe request before we tear down
      // the socket, catch it and do nothing.
      _log.info('Received an unsubscribe request: ${root.toXmlString()}');
      return;
    }
    if (packetType == 'emotivaNotify' || packetType == 'emotivaMenuNotify') {
      try {
        final serverSequence = _getSequence(root);
        final delta = serverSequence - _sequenceNumber;
        if (delta == 1) {
          // The sequence number incremented by 1 as expected.
          _sequenceNumber = serverSequence;
        } else if (_sequenceNumber == -1) {
          // Set the initial sequence number.
          _sequenceNumber = serverSequence;
        } else if (delta > 1) {
          _log.warning(
            "It looks like we're behind one or more messages. "
            "Updating all fields.",
          );
          _sequenceNumber = serverSequence;
          updateAll();
        } else {
          // The only case left is that serverSequence is <= _sequenceNumber.
          if (pow(2, 32) - _sequenceNumber < 1000) {
            // My simple attempt at rollover detection. Emotiva documents that
            // the sequence number they produce is an unsigned int. If, somehow
            // we get within 1000 of 2^32 and the serverSequence number is
            // lower than our's, let's assume we've rolled over and adopt the
            // remote sequence number.
            _sequenceNumber = serverSequence;
            _log.info('Sequence rollover heuristic has kicked in.');
          }
          _log.warning(
            "Received a message with an old sequence number. "
            "Calling updateAll() in case we've missed something.",
          );
          updateAll();
          return;
        }
      } catch (e) {
        // If we can't find a sequence number, just assume we should continue
        // processing this packet.
        _log.severe('Sequence number missing: ${root.toXmlString()}');
      }
    }
    if (packetType == 'emotivaMenuNotify') {
      menuContents = _parseMenuNotify(root);
      return;
    }
    if (packetType != 'emotivaUpdate' &&
        packetType != 'emotivaNotify' &&
        packetType != 'emotivaSubscription') {
      throw ('Received improperly formatted '
          'emotivaUpdate/emotivaNotify/emotivaSubscription response: '
          '${root.toXmlString(pretty: true)}');
    }
    final protocol = _getProtocolAttribute(root);
    for (final element in root.childElements) {
      final name = element.name.toString();
      final String field;
      if (protocol.startsWith('3.') && name == 'property') {
        field = _getNameAttribute(element);
      } else if (controlVersion.startsWith('3.') && name == 'property') {
        // The protocol attribute isn't reliably present in messages. But if the
        // device initially reports support for protocol version 3+, let's look
        // for the use of '<property>' tags, which should only be present in
        // protocol version 3+ messages.
        field = _getNameAttribute(element);
      } else {
        field = name;
      }
      switch (field) {
        case 'power':
          power = _valueAttribute(element.attributes).toLowerCase() == 'on'
              ? true
              : false;
        case 'source':
          source = _valueAttribute(element.attributes);
        case 'mode':
          mode = _valueAttribute(element.attributes);
        case 'volume':
          try {
            final reportedVolume = _valueAttribute(element.attributes)
                // Trim any whitespace characters. When the volume is above
                // -10dB, there is whitespace between the value and the sign,
                // which breaks the double parser.
                .replaceAll(RegExp(r'\s+'), '');
            if (reportedVolume == 'Mute') {
              muted = true;
            } else {
              muted = false;
              volume = double.parse(reportedVolume);
            }
          } catch (e) {
            // If parsing fails, that could mean the device is in standby.
            _log.severe('Unable to parse message: $e');
          }
        case 'loudness':
          loudness = _valueAttribute(element.attributes).toLowerCase() == 'on'
              ? true
              : false;
        case 'audio_input':
          audioInput = _valueAttribute(element.attributes);
        case 'audio_bitstream':
          audioBitstream = _valueAttribute(element.attributes);
        case 'audio_bits':
          audioBits = _valueAttribute(element.attributes);
        case 'video_input':
          videoInput = _valueAttribute(element.attributes);
        case 'video_format':
          videoFormat = _valueAttribute(element.attributes);
        case 'video_space':
          videoSpace = _valueAttribute(element.attributes);
        case 'dim':
          dim = int.parse(_valueAttribute(element.attributes));
        case 'speaker_preset':
          speakerPreset = _valueAttribute(element.attributes);
        case 'center':
          centerTrim = _getSpeakerTrim(element);
        case 'subwoofer':
          subwooferTrim = _getSpeakerTrim(element);
        case 'surround':
          surroundTrim = _getSpeakerTrim(element);
        case 'back':
          backTrim = _getSpeakerTrim(element);
        case 'width':
          widthTrim = _getSpeakerTrim(element);
        case 'height':
          heightTrim = _getSpeakerTrim(element);
        case 'treble':
          trebleTrim = _getDoubleAttribute(_valueAttribute(element.attributes));
        case 'bass':
          bassTrim = _getDoubleAttribute(_valueAttribute(element.attributes));
        // "mode_*" fields indicate whether these modes are selectable on the
        // device via the "visible" attribute.
        case 'mode_ref_stereo' ||
            'mode_stereo' ||
            'mode_music' ||
            'mode_movie' ||
            'mode_direct' ||
            'mode_dolby' ||
            'mode_dts' ||
            'mode_all_stereo' ||
            'mode_auto' ||
            'mode_surround':
          visibility[field] = _visibleAttribute(element.attributes);
        case 'selected_mode':
          selectedMode = _valueAttribute(element.attributes);
        case 'selected_movie_music':
          selectedMovieMusic = _valueAttribute(element.attributes);
        case 'zone2_power':
          final value = _valueAttribute(element.attributes);
          if (value == 'On') {
            zone2Power = true;
          } else {
            zone2Power = false;
          }
        case 'zone2_volume':
          try {
            final reportedVolume = _valueAttribute(element.attributes);
            if (reportedVolume == 'Mute') {
              zone2Muted = true;
            } else {
              zone2Muted = false;
              zone2Volume = double.parse(reportedVolume);
            }
          } catch (e) {
            // If parsing fails, that could mean the device is in standby.
            _log.severe('Unable to parse message: $e');
          }
        case 'zone2_input':
          zone2Input = _valueAttribute(element.attributes);
        case 'tuner_band':
          final band = _valueAttribute(element.attributes).toLowerCase();
          if (band == 'am') {
            tunerBand = .am;
          } else if (band == 'fm') {
            tunerBand = .fm;
          } else {
            _log.severe('Unrecognized tuner band: $band');
          }
        case 'tuner_channel':
          tunerChannel = _valueAttribute(element.attributes);
        case 'tuner_signal':
          tunerSignal = _valueAttribute(element.attributes);
        case 'tuner_program':
          tunerProgram = _valueAttribute(element.attributes);
        case 'tuner_RDS':
          tunerRds = _valueAttribute(element.attributes);
        case 'input_1' ||
            'input_2' ||
            'input_3' ||
            'input_4' ||
            'input_5' ||
            'input_6' ||
            'input_7' ||
            'input_8':
          names[field] = _valueAttribute(element.attributes);
          visibility[field] = _visibleAttribute(element.attributes);
        case 'menu':
          if (_valueAttribute(element.attributes).toLowerCase() == 'on') {
            menuDisplayed = true;
          } else {
            menuDisplayed = false;
          }
        case 'menu_update':
          // There's no data in these tags that we need. Menu contents come from
          // MenuNotify messages.
          break;
        case 'source_tuner':
          // I don't know what this one is. It's listed as a command in their
          // doc. But it seems to report the same value as "source".
          // TODO - remove this if Emotiva fixes the interface.
          break;
        default:
          _log.severe('Could not parse ${element.toXmlString()}');
      }
    }
  }

  /// Changes the volume by [delta]dBs.
  void volumeDelta(double delta) => control('volume', value: delta.toString());

  /// Sets the volume to [level]dBs.
  void volumeSet(int level) => control('set_volume', value: level.toString());

  void togglePower() => power ? control('power_off') : control('power_on');
  void toggleLoudness() => control('loudness');
  void toggleMute() => control('mute');

  /// Cycles the front display brightness.
  ///
  /// Brightness values cycle through 0%, 20%, 40%, 60%, 80%, and 100%.
  void cycleFrontDisplayBrightness() => control('dim');

  /// On some older firmware, the menu feature is not available and the device
  /// will not advertise a menu notify port.
  bool menuAvailable() => menuNotifyPort != null;
  void toggleMenu() => control('menu');
  void menuUp() => control('up');
  void menuDown() => control('down');
  void menuLeft() => control('left');
  void menuRight() => control('right');
  void menuEnter() => control('enter');

  /// Displays the info table on OSD.
  void info() => control('info');

  /// Sets the source to the user configurable inputs.
  void setSource(int input) => control('source_$input');

  /// Sets the source to the HDMI input corresponding to [input].
  void setHdmi(int input) => control('hdmi$input');

  /// Sets the audio source to the coax input corresponding to [input].
  void setCoax(int input) => control('coax$input');

  /// Sets the audio source to the balanced digital input.
  void setAesEbu() {
    // coax5 pulls up the AES/EBU input on the RMC-1.
    return control('coax5');
  }

  /// Sets the audio source to the optical input corresponding to [input].
  void setOptical(int input) => control('optical$input');

  void setArc() => control('ARC');
  void setUsb() => control('usb_stream');
  void setTuner() => control('tuner');

  /// Sets the audio source to the analog input corresponding to [input].
  void setAnalog(int input) => control('analog$input');

  /// Sets the audio source to the balanced analog input.
  void setBalancedInput() {
    // analog5 brings up the balanced input on the RMC-1.
    return control('analog5');
  }

  /// Sets the audio source to the front analog input.
  void setFront() => control('front_in');

  void modeAuto() => control('auto');
  void modeStereo() => control('stereo');
  void modeDirect() => control('direct');
  void modeReferenceStereo() => control('reference_stereo');
  void modeDolby() => control('dolby');
  void modeDts() => control('dts');
  void modeAllStereo() => control('all_stereo');
  void speakerPreset1() => control('preset1');
  void speakerPreset2() => control('preset2');

  /// The Dirac speaker preset might only be available on older models, like the
  /// XMC-1.
  void speakerPresetDirac() => control('dirac');

  /// Adjusts the center speaker trim.
  ///
  /// [trim] is should be a value between -12.0 and 12.0 in 0.5 increments which
  /// represent the volume setting for the channel in dB.
  void trimCenter(double trim) =>
      control('center_trim_set', value: _convertTrim(trim));

  /// Adjusts the subwoofer trim.
  ///
  /// [trim] is should be a value between -12.0 and 12.0 in 0.5 increments which
  /// represent the volume setting for the channel in dB.
  void trimSubwoofer(double trim) =>
      control('subwoofer_trim_set', value: _convertTrim(trim));

  /// Adjusts the trim for surround speakers.
  ///
  /// [trim] is should be a value between -12.0 and 12.0 in 0.5 increments which
  /// represent the volume setting for the channel in dB.
  void trimSurround(double trim) =>
      control('surround_trim_set', value: _convertTrim(trim));

  /// Adjusts the trim for back (i.e. rear) speakers.
  ///
  /// [trim] is should be a value between -12.0 and 12.0 in 0.5 increments which
  /// represent the volume setting for the channel in dB.
  void trimBack(double trim) =>
      control('back_trim_set', value: _convertTrim(trim));

  /// Adjusts the trim for height speakers.
  ///
  /// Only available in protocol version >= 3.0.
  /// [trim] is should be a value between -12.0 and 12.0 in 0.5 increments which
  /// represent the volume setting for the channel in db.
  void trimHeight(double trim) =>
      control('height_trim_set', value: _convertTrim(trim));

  /// Adjusts the trim for width speakers.
  ///
  /// Only available in protocol version >= 3.0.
  /// [trim] is should be a value between -12.0 and 12.0 in 0.5 increments which
  /// represent the volume setting for the channel in db.
  void trimWidth(double trim) =>
      control('width_trim_set', value: _convertTrim(trim));

  void trebleUp() => control('treble_up');
  void trebleDown() => control('treble_down');
  void bassUp() => control('bass_up');
  void bassDown() => control('bass_down');

  void zone2TogglePower() => control('zone2_power');

  /// Changes the zone 2 volume by [delta]dBs.
  void zone2VolumeDelta(double delta) =>
      control('zone2_volume', value: delta.toString());

  /// Sets the volume to [level]dBs.
  void zone2VolumeSet(int level) =>
      control('zone2_set_volume', value: level.toString());

  // This does not appear to work.
  void zone2ToggleMute() => control('zone2_mute');

  void zone2SetAnalog(int input) => control('zone2_analog$input');

  void zone2SetBalancedInput() {
    // analog5 bring up the balanced input on the RMC-1.
    return control('zone2_analog5');
  }

  void zone2SetFront() => control('zone2_front_in');

  /// Sets the zone 2 input to follow the main (i.e. zone 1) input.
  void zone2FollowMain() => control('zone2_follow_main');

  void zone2SetCoax(int input) => control('zone2_coax$input');
  void zone2SetOptical(int input) => control('zone2_optical$input');

  // Not in the API docs.
  void zone2SetUsb() => control('zone2_usb_stream');

  // Not in the API docs.
  void zone2SetAesEbu() {
    // coax5 pulls up the AES/EBU input on the RMC-1.
    return control('zone2_coax5');
  }

  // Not in the API docs.
  void zone2SetTuner() => control('zone2_tuner');

  void toggleTunerBand() {
    // Applies to both zones.
    return control('zone1_band');
  }

  void setBand(TunerBand band) =>
      band == TunerBand.am ? control('band_am') : control('band_fm');

  void frequencyHigher() => control('frequency', value: '1');
  void frequencyLower() => control('frequency', value: '-1');
  void seekHigher() => control('seek', value: '1');
  void seekLower() => control('seek', value: '-1');
  void channelUp() => control('channel', value: '1');
  void channelDown() => control('channel', value: '-1');
  void setChannel(int channel) => control('channel_$channel');
}

/// A fake Device class that does not create or handle any network traffic.
///
/// This class is meant to be use for testing and demonstration.
/// This class only supports Emotiva protocol 3.0.
class FakeDevice extends Device {
  int _sequence = 0;

  FakeDevice(super.address, super.controlPort, super.notifyPort) {
    menuNotifyPort = 1234;
    model = 'Fake Emotiva';
    name = 'Fake name';
    controlVersion = '3.0';
    power = false;
    // With the power off, the device normally returns a 'None' value for the
    // speaker trims. We handle that internally as false visibility.
    visibility['center'] = false;
    visibility['subwoofer'] = false;
    visibility['surround'] = false;
    visibility['back'] = false;
    visibility['height'] = false;
    visibility['width'] = false;
    source = 'HDMI 1';
    audioInput = 'HDMI 1';
    videoInput = 'HDMI 1';
    mode = 'Dolby Surround';
    audioBitstream = 'PCM 2.0';
    videoFormat = '2160P/60';
    volume = -35.0;
    audioBits = '48kHz 20bits';
    videoSpace = '10bits';
    loudness = false;
    dim = 0;
    speakerPreset = 'Preset 1';
    names['input_1'] = 'Blu-Ray analog';
    names['input_2'] = 'Fancy pants DAC';
    menuContents = _initMenuContent();
    zone2Input = 'Optical 1';
    zone2Volume = -40.0;
    tunerBand = .fm;
    tunerSignal = '35 dBuV';
    tunerProgram = 'Classical';
    tunerRds = 'WCPE: Mahler 5';
    tunerChannel = 'FM 89.7';
  }

  Datagram _encode(String request) {
    return Datagram(
      // In the fake, the address and port don't matter, but are required by
      // DataGram.
      Uint8List.fromList(request.codeUnits),
      address,
      notifyPort,
    );
  }

  Menu _initMenuContent() {
    final menu = Menu();
    // Their API docs say there are always 11 rows.
    for (int i = 0; i < 11; i++) {
      final row = Row(i);
      // Their API docs say there are always 3 columns.
      for (int j = 0; j < 3; j++) {
        final column = Column(j, false, .no, false);
        row.columns.add(column);
      }
      // We only display rows 4, 5, and 6. The actual front display of the
      // RMC-1L does the same thing.
      if (i == 4) {
        row.columns[1].value = 'Lip Synch Auto';
        row.columns[1].arrow = .up;
        row.columns[2].checkbox = true;
      }
      if (i == 5) {
        row.columns[0].value = 'HDMI 1';
        row.columns[0].arrow = .left;
        row.columns[1].value = 'Button';
        row.columns[1].highlight = true;
        row.columns[2].value = 'Input 1';
        row.columns[2].arrow = .right;
      }
      if (i == 6) {
        row.columns[1].value = '5.1 Mode';
        row.columns[1].arrow = .down;
        row.columns[2].value = 'Auto';
      }
      menu.rows.add(row);
    }
    return menu;
  }

  Iterable<String> _elementsToFields(Iterable<XmlElement> elements) {
    final fields = <String>[];
    for (final e in elements) {
      fields.add(e.name.toString());
    }
    return fields;
  }

  void _updateBuilder(XmlBuilder builder, String field, String value) {
    builder.element(
      'property',
      attributes: {
        'name': field,
        'value': value,
        'visible': _getVisibilityForField(field),
        'status': 'ack',
      },
    );
  }

  void _parseUpdateRequest(Iterable<String> fields) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element(
      'emotivaUpdate',
      attributes: {'protocol': '3.0'},
      nest: () {
        for (final f in fields) {
          try {
            _updateBuilder(builder, f, _getValueForField(f));
          } catch (e) {
            // Unknown field.
            builder.element(
              f,
              attributes: {'value': '', 'visible': 'true', 'status': 'nak'},
            );
          }
        }
      },
    );
    final response = builder.buildDocument().toXmlString(pretty: true);
    _log.info('response: $response');
    _control.controller.add(_encode(response));
  }

  void _toggleLoudness() {
    loudness = !loudness;
  }

  String _getValue(XmlElement element) {
    try {
      for (final a in element.attributes) {
        if (a.name.toString() == 'value') {
          return a.value;
        }
      }
    } catch (e) {
      _log.severe('Unable to get value from ${element.toXmlString()}: $e');
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
    source = audioInput;
    updatedFields.add('audio_input');
    updatedFields.add('source');
  }

  void _handleOpticalControlRequest(String command, Set<String> updatedFields) {
    final input = command.substring(7);
    audioInput = 'Optical $input';
    source = audioInput;
    updatedFields.add('audio_input');
    updatedFields.add('source');
  }

  void _handleAnalogControlRequest(String command, Set<String> updatedFields) {
    final input = command.substring(6);
    if (input == '5') {
      audioInput = 'Balanced In';
    } else {
      audioInput = 'Analog $input';
    }
    source = audioInput;
    updatedFields.add('audio_input');
    updatedFields.add('source');
  }

  double _clampTrimValue(double trim) => switch (trim) {
    > 24.0 => 24.0,
    < -24.0 => -24.0,
    _ => trim,
  };

  void _parseControlRequest(Iterable<XmlElement> elements) {
    Set<String> updatedFields = {};
    for (final element in elements) {
      String field = element.name.toString();
      switch (field) {
        case 'power_on':
          power = true;
          visibility['center'] = true;
          visibility['subwoofer'] = true;
          visibility['surround'] = true;
          visibility['back'] = true;
          visibility['height'] = true;
          visibility['width'] = true;
          updatedFields.addAll([
            'power',
            'center',
            'subwoofer',
            'surround',
            'back',
            'height',
            'width',
          ]);
        case 'power_off':
          power = false;
          visibility['center'] = false;
          visibility['subwoofer'] = false;
          visibility['surround'] = false;
          visibility['back'] = false;
          visibility['height'] = false;
          visibility['width'] = false;
          updatedFields.addAll([
            'power',
            'center',
            'subwoofer',
            'surround',
            'back',
            'height',
            'width',
          ]);
        case 'mode':
          mode = _getValue(element);
          updatedFields.add(field);
        case 'volume':
          try {
            final delta = double.parse(_getValue(element));
            volume += delta;
            muted = false;
            updatedFields.add(field);
          } catch (e) {
            _log.severe(
              'Unable to parse volume delta: ${element.toXmlString()}',
            );
          }
        case 'loudness':
          _toggleLoudness();
          updatedFields.add(field);
        case 'audio_input':
          audioInput = _getValue(element);
          updatedFields.add(field);
        case 'video_input':
          videoInput = _getValue(element);
          updatedFields.add(field);
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
        case 'hdmi1':
        case 'hdmi2':
        case 'hdmi3':
        case 'hdmi4':
        case 'hdmi5':
        case 'hdmi6':
        case 'hdmi7':
        case 'hdmi8':
          _handleHdmiControlRequest(field, updatedFields);
        case 'coax1':
        case 'coax2':
        case 'coax3':
        case 'coax4':
        case 'coax5':
          _handleCoaxControlRequest(field, updatedFields);
        case 'optical1':
        case 'optical2':
        case 'optical3':
        case 'optical4':
          _handleOpticalControlRequest(field, updatedFields);
        case 'ARC':
          audioInput = 'HDMI ARC';
          source = audioInput;
          updatedFields.addAll(['audio_input', 'source']);
        case 'usb_stream':
          audioInput = 'USB Stream';
          source = audioInput;
          updatedFields.addAll(['audio_input', 'source']);
        case 'tuner':
          audioInput = 'Tuner';
          source = audioInput;
          updatedFields.addAll(['audio_input', 'source']);
        case 'analog1':
        case 'analog2':
        case 'analog3':
        case 'analog5':
          _handleAnalogControlRequest(field, updatedFields);
        case 'front_in':
          audioInput = 'Front';
          source = audioInput;
          updatedFields.addAll(['audio_input', 'source']);
        case 'source_1':
          audioInput = 'Balanced In';
          videoInput = 'HDMI 1';
          source = names['input_1']!;
          updatedFields.addAll(['audio_input', 'video_input', 'source']);
        case 'source_2':
          audioInput = 'Analog 1';
          source = names['input_2']!;
          updatedFields.addAll(['audio_input', 'source']);
        case 'source_3':
          audioInput = 'HDMI 3';
          videoInput = 'HDMI 3';
          source = 'HDMI 3';
          updatedFields.addAll(['audio_input', 'video_input', 'source']);
        case 'source_4':
          audioInput = 'HDMI 4';
          videoInput = 'HDMI 4';
          source = 'HDMI 4';
          updatedFields.addAll(['audio_input', 'video_input', 'source']);
        case 'source_5':
          audioInput = 'HDMI 5';
          videoInput = 'HDMI 5';
          source = 'HDMI 5';
          updatedFields.addAll(['audio_input', 'video_input', 'source']);
        case 'source_6':
          audioInput = 'HDMI 6';
          videoInput = 'HDMI 6';
          source = 'HDMI 6';
          updatedFields.addAll(['audio_input', 'video_input', 'source']);
        case 'source_7':
          audioInput = 'HDMI 7';
          videoInput = 'HDMI 7';
          source = 'HDMI 7';
          updatedFields.addAll(['audio_input', 'video_input', 'source']);
        case 'source_8':
          audioInput = 'HDMI 8';
          videoInput = 'HDMI 8';
          source = 'HDMI 8';
          updatedFields.addAll(['audio_input', 'video_input', 'source']);
        case 'auto':
          // Dolby Surround is a reasonable fake since it's usually what's
          // chosen if the source is 2 channel.
          mode = 'Dolby Surround';
          updatedFields.add('mode');
        case 'stereo':
          mode = 'Stereo';
          updatedFields.add('mode');
        case 'direct':
          mode = 'Direct';
          updatedFields.add('mode');
        case 'reference_stereo':
          mode = 'Reference Stereo';
          updatedFields.add('mode');
        case 'dolby':
          mode = 'Dolby Surround';
          updatedFields.add('mode');
        case 'dts':
          mode = 'dts Neural:X';
          updatedFields.add('mode');
        case 'all_stereo':
          mode = 'All Stereo';
          updatedFields.add('mode');
        case 'preset1':
          speakerPreset = 'Preset 1';
          updatedFields.add('speaker_preset');
        case 'preset2':
          speakerPreset = 'Preset 2';
          updatedFields.add('speaker_preset');
        case 'center_trim_set':
          final rawTrim = double.parse(_getValue(element));
          final sanitizedTrim = _clampTrimValue(rawTrim);
          // Divide by 2 because this normally happens inside the Emotiva
          // device.
          centerTrim = sanitizedTrim / 2;
          updatedFields.add('center');
        case 'subwoofer_trim_set':
          final rawTrim = double.parse(_getValue(element));
          final sanitizedTrim = _clampTrimValue(rawTrim);
          subwooferTrim = sanitizedTrim / 2;
          updatedFields.add('subwoofer');
        case 'surround_trim_set':
          final rawTrim = double.parse(_getValue(element));
          final sanitizedTrim = _clampTrimValue(rawTrim);
          surroundTrim = sanitizedTrim / 2;
          updatedFields.add('surround');
        case 'back_trim_set':
          final rawTrim = double.parse(_getValue(element));
          final sanitizedTrim = _clampTrimValue(rawTrim);
          backTrim = sanitizedTrim / 2;
          updatedFields.add('back');
        case 'treble_up':
          trebleTrim += 0.5;
          updatedFields.add('treble');
        case 'treble_down':
          trebleTrim -= 0.5;
          updatedFields.add('treble');
        case 'bass_up':
          bassTrim += 0.5;
          updatedFields.add('bass');
        case 'bass_down':
          bassTrim -= 0.5;
          updatedFields.add('bass');
        case 'menu':
          menuDisplayed = menuDisplayed ? false : true;
          updatedFields.add('menu');
          if (menuDisplayed) _notifyMenuSubscribers();
        case 'up':
        case 'down':
        case 'left':
        case 'right':
        case 'enter':
          _notifyMenuSubscribers();
        case 'zone2_power':
          zone2Power = zone2Power ? false : true;
          updatedFields.add('zone2_power');
        case 'zone2_volume':
          try {
            final delta = double.parse(_getValue(element));
            zone2Volume += delta;
            zone2Muted = false;
            updatedFields.add(field);
          } catch (e) {
            _log.severe(
              'Unable to parse zone 2 volume delta: ${element.toXmlString()}',
            );
          }
        case 'zone2_mute':
          zone2Muted = zone2Muted ? false : true;
          // Emotiva uses the volume field to indicate whether the device is
          // muted.
          updatedFields.add('zone2_volume');
        case 'zone2_analog1':
          zone2Input = 'Analog 1';
          updatedFields.add('zone2_input');
        case 'zone2_analog2':
          zone2Input = 'Analog 2';
          updatedFields.add('zone2_input');
        case 'zone2_analog3':
          zone2Input = 'Analog 3';
          updatedFields.add('zone2_input');
        case 'zone2_analog4':
          zone2Input = 'Analog 4';
          updatedFields.add('zone2_input');
        case 'zone2_analog5':
          zone2Input = 'Balanced In';
          updatedFields.add('zone2_input');
        case 'zone2_front_in':
          zone2Input = 'Front';
          updatedFields.add('zone2_input');
        case 'zone2_follow_main':
          zone2Input = audioInput;
          updatedFields.add('zone2_input');
        case 'zone2_coax1':
          zone2Input = 'Coax 1';
          updatedFields.add('zone2_input');
        case 'zone2_coax2':
          zone2Input = 'Coax 2';
          updatedFields.add('zone2_input');
        case 'zone2_coax3':
          zone2Input = 'Coax 3';
          updatedFields.add('zone2_input');
        case 'zone2_coax4':
          zone2Input = 'Coax 4';
          updatedFields.add('zone2_input');
        case 'zone2_coax5':
          zone2Input = 'AES/EBU';
          updatedFields.add('zone2_input');
        case 'zone2_optical1':
          zone2Input = 'Optical 1';
          updatedFields.add('zone2_input');
        case 'zone2_optical2':
          zone2Input = 'Optical 2';
          updatedFields.add('zone2_input');
        case 'zone2_optical3':
          zone2Input = 'Optical 3';
          updatedFields.add('zone2_input');
        case 'zone2_optical4':
          zone2Input = 'Optical 4';
          updatedFields.add('zone2_input');
        case 'zone2_usb_stream':
          zone2Input = 'USB Stream';
          updatedFields.add('zone2_input');
        case 'zone2_tuner':
          zone2Input = 'Tuner';
          updatedFields.add('zone2_input');
        case 'zone1_band':
          if (tunerBand == TunerBand.am) {
            tunerBand = .fm;
            tunerChannel = 'FM 89.7';
            tunerProgram = 'Classical';
            tunerRds = 'WCPE: Mahler 5';
            tunerSignal = '45 dBuV';
          } else {
            tunerBand = .am;
            tunerChannel = 'AM 680';
            tunerProgram = 'News';
            tunerRds = 'Nothing but good news all day long.';
            tunerSignal = '8 dBuV';
          }
          updatedFields.addAll([
            'tuner_band',
            'tuner_channel',
            'tuner_program',
            'tuner_RDS',
            'tuner_signal',
          ]);
        default:
          _log.warning('FakeDevice does not support: $field');
      }
    }
    _notifySubscribers(updatedFields);
  }

  void _notifyMenuSubscribers() {
    final builder = XmlBuilder()..processing('xml', 'version="1.0"');
    builder.element(
      'emotivaMenuNotify',
      attributes: {'sequence': _sequence.toString()},
      nest: () {
        for (final row in menuContents.rows) {
          builder.element(
            'row',
            attributes: {'number': row.number.toString()},
            nest: () {
              for (final column in row.columns) {
                Map<String, String> attributes = {
                  'number': column.number.toString(),
                  'value': column.value,
                  'fixedWidth': column.fixedWidth.toString(),
                  'highlight': column.highlight.toString(),
                  'arrow': column.arrow.name,
                };
                if (column.fixedWidth) {
                  attributes['offset'] =
                      '5'; // just making something up for now
                }
                if (column.checkbox ?? false) {
                  attributes.remove('value');
                  attributes['checkbox'] = 'on';
                }
                builder.element('col', attributes: attributes);
              }
            },
          );
        }
      },
    );
    final response = builder.buildDocument().toXmlString(pretty: true);
    _log.info('response: $response');
    _sequence++;
    _menuNotify!.controller.add(_encode(response));
  }

  void _notifySubscribers(Set<String> updatedFields) {
    // Note that updatedFields has already been vetted by other methods before
    // this method is called.
    final builder = XmlBuilder()..processing('xml', 'version="1.0"');
    builder.element(
      'emotivaNotify',
      attributes: {'sequence': _sequence.toString()},
      nest: () {
        for (final field in updatedFields) {
          String value = _getValueForField(field);
          String visible = _getVisibilityForField(field);
          builder.element(
            'property',
            attributes: {'name': field, 'value': value, 'visible': visible},
          );
        }
      },
    );
    final response = builder.buildDocument().toXmlString(pretty: true);
    _log.info('response: $response');
    _sequence++;
    _notify.controller.add(_encode(response));
  }

  String _getValueForField(String field) => switch (field) {
    'power' => power ? 'On' : 'False',
    'source' => source,
    'mode' => mode,
    'volume' => muted ? 'Mute' : volume.toString(),
    'loudness' => loudness ? 'On' : 'Off',
    'audio_input' => audioInput,
    'audio_bitstream' => audioBitstream,
    'audio_bits' => audioBits,
    'video_input' => videoInput,
    'video_format' => videoFormat,
    'video_space' => videoSpace,
    'dim' => dim.toString(),
    'speaker_preset' => speakerPreset,
    'center' => (visibility[field] ?? false) ? centerTrim.toString() : 'None',
    'width' => (visibility[field] ?? false) ? widthTrim.toString() : 'None',
    'subwoofer' =>
      (visibility[field] ?? false) ? subwooferTrim.toString() : 'None',
    'surround' =>
      (visibility[field] ?? false) ? surroundTrim.toString() : 'None',
    'back' => (visibility[field] ?? false) ? backTrim.toString() : 'None',
    'height' => (visibility[field] ?? false) ? heightTrim.toString() : 'None',
    'treble' => trebleTrim.toString(),
    'bass' => bassTrim.toString(),
    'selected_mode' => selectedMode,
    'selected_movie_music' => selectedMovieMusic,
    'input_1' => names['input_1']!,
    'input_2' => names['input_2']!,
    'input_3' => names['input_3']!,
    'input_4' => names['input_4']!,
    'input_5' => names['input_5']!,
    'input_6' => names['input_6']!,
    'input_7' => names['input_7']!,
    'input_8' => names['input_8']!,
    'mode_ref_stereo' => 'Reference Stereo',
    'mode_stereo' => 'Stereo',
    'mode_music' => 'Music',
    'mode_movie' => 'Movie',
    'mode_direct' => 'Direct',
    'mode_dolby' => 'Dolby Surround',
    'mode_dts' => 'dtsX',
    'mode_all_stereo' => 'All Stereo',
    'mode_auto' => 'Auto',
    'mode_surround' => 'Dolby Surround',
    'menu' => menuDisplayed ? 'On' : 'Off',
    'menu_update' => '',
    'zone2_power' => zone2Power ? 'On' : 'Off',
    'zone2_volume' => zone2Muted ? 'Mute' : zone2Volume.toString(),
    'zone2_input' => zone2Input,
    'tuner_band' => tunerBand.name.toUpperCase(),
    'tuner_channel' => tunerChannel,
    'tuner_signal' => tunerSignal,
    'tuner_RDS' => tunerRds,
    'tuner_program' => tunerProgram,
    _ => throw 'Unsupported field: $field',
  };

  String _getVisibilityForField(String field) {
    bool visible = visibility[field] ?? true;
    return visible.toString().toLowerCase();
  }

  void _parseSubscriptionRequest(Iterable<String> fields) {
    final builder = XmlBuilder()..processing('xml', 'version="1.0"');
    builder.element(
      'emotivaSubscription',
      attributes: {'protocol': '3.0'},
      nest: () {
        for (final field in fields) {
          if (Device._fields.contains(field)) {
            _subscribedFields.add(field);
            builder.element(
              'property',
              attributes: {
                'name': field,
                'value': _getValueForField(field),
                'status': 'ack',
                'visible': _getVisibilityForField(field),
              },
            );
          } else {
            // Return nak status for unknown fields.
            builder.element(field, attributes: {'status': 'nak'});
          }
        }
      },
    );
    final response = builder.buildDocument().toXmlString(pretty: true);
    _log.info('response: $response');
    _control.controller.add(_encode(response));
  }

  void _parseUnsubscribeRequest(Iterable<String> fields) {
    String status = 'nak';
    final builder = XmlBuilder()..processing('xml', 'version="1.0"');
    builder.element(
      'emotivaUnsubscribe',
      nest: () {
        for (final f in fields) {
          _subscribedFields.remove(f);
          if (Device._fields.contains(f)) {
            status = 'ack';
          }
          builder.element(f, attributes: {'status': status});
        }
      },
    );
  }

  void _parseRequest(String request) {
    final document = XmlDocument.parse(request);
    final root = document.rootElement;
    final requestType = root.name.toString();
    final fields = _elementsToFields(root.childElements);
    _log.info('request: ${root.toXmlString(pretty: true)}');
    switch (requestType) {
      case 'emotivaControl':
        _parseControlRequest(root.childElements);
      case 'emotivaUpdate':
        _parseUpdateRequest(fields);
      case 'emotivaSubscription':
        _parseSubscriptionRequest(fields);
      case 'emotivaUnsubscribe':
        _parseUnsubscribeRequest(fields);
      default:
        throw 'Unknown request type $requestType';
    }
  }

  @override
  void _send(String request, int destinationPort) {
    // destinationPort seems to always be controlPort.
    _parseRequest(request);
  }

  @override
  Future<void> bindSockets() async {}

  @override
  Future<void> closeSockets() async {}
}

/// This function is meant to be mostly a stand-in replacement for [discover].
Future<FakeDevice> futureFakeDevice() async =>
    FakeDevice(InternetAddress('192.168.42.1'), 1, 2);

// These enums represent the UI elements of the on-screen display menu.

/// Arrow direction. This would be named ArrowDirection except that I wanted to
/// be consistent with reusing names of the attributes in the XML as described
/// in the Emotiva API docs.
enum Arrow { no, up, down, right, left }

class Column([
  var int number = 0,
  var bool highlight = false,
  var Arrow arrow = .no,
  var bool fixedWidth = false,
]) {
  // The offset seems to be only informational. It's only used when fixedWidth
  // is true and the contents of "value" already includes the offset padding.
  int? offset;
  bool? checkbox;
  String value = '';
}

class Row([var int number = 0]) {
  List<Column> columns = [];
}

typedef ArrowPosition = ({Arrow arrow, int track, int offset, bool fixedWidth});

class Menu {
  List<Row> rows = [];

  /// Provide the column/row position for an [arrow].
  ///
  /// A value of -1 means that [arrow] is not currently visible. If the [arrow]
  /// is left or right, the returned value represents which row should display
  /// the arrow. If the [arrow] is up or down, the returned value represents
  /// which column should display the arrow.
  ArrowPosition _arrowPosition(Arrow arrow) {
    for (final row in rows) {
      for (final column in row.columns) {
        switch (arrow) {
          case Arrow.up || Arrow.down:
            if (column.arrow == arrow) {
              return (
                arrow: arrow,
                track: column.number,
                offset: column.offset ?? 0,
                fixedWidth: column.fixedWidth,
              );
            }
          case Arrow.left || Arrow.right:
            if (column.arrow == arrow) {
              return (
                arrow: arrow,
                track: row.number,
                offset: column.offset ?? 0,
                fixedWidth: column.fixedWidth,
              );
            }
          case Arrow.no:
            continue;
        }
      }
    }
    return const (arrow: .no, track: -1, offset: 0, fixedWidth: false);
  }

  ArrowPosition upArrow() => _arrowPosition(Arrow.up);
  ArrowPosition downArrow() => _arrowPosition(Arrow.down);
  ArrowPosition leftArrow() => _arrowPosition(Arrow.left);
  ArrowPosition rightArrow() => _arrowPosition(Arrow.right);
}

Menu _parseMenuNotify(XmlElement element) {
  final menu = Menu();
  if (element.name.toString() != 'emotivaMenuNotify') {
    _log.severe('Invalid menu notify message: ${element.toXmlString()}');
    return menu;
  }
  for (final e in element.childElements) {
    menu.rows.add(_parseMenuNotifyRow(e));
  }
  return menu;
}

Row _parseMenuNotifyRow(XmlElement element) {
  final row = Row(0);
  if (element.name.toString() != 'row') {
    _log.severe('Invalid menu notify row: ${element.toXmlString()}');
    return row;
  }
  for (final a in element.attributes) {
    if (a.name.toString() != 'number') {
      _log.severe('Unexpected attribute in row: ${a.toString()}');
    }
    try {
      row.number = int.parse(a.value);
    } catch (e) {
      _log.severe('Unable to parse row number: ${a.toXmlString()}');
    }
  }
  for (final e in element.childElements) {
    row.columns.add(_parseMenuNotifyColumn(e));
  }
  return row;
}

Column _parseMenuNotifyColumn(XmlElement element) {
  final column = Column(0, false, Arrow.no, false);
  if (element.name.toString() != 'col') {
    _log.severe('Invalid menu notify column: ${element.toXmlString()}');
    return column;
  }
  for (final a in element.attributes) {
    final name = a.name.toString();
    final value = a.value.toString();
    switch (name) {
      case 'highlight':
        try {
          column.highlight = bool.parse(value);
        } catch (e) {
          _log.severe('Unable to parse highlight as bool: ${a.toXmlString()}');
        }
      case 'arrow':
        switch (value.toLowerCase()) {
          case 'no':
            column.arrow = .no;
          case 'up':
            column.arrow = .up;
          case 'down':
            column.arrow = .down;
          case 'right':
            column.arrow = .right;
          case 'left':
            column.arrow = .left;
          default:
            _log.severe('Unexpected value for "arrow": $value');
        }
      case 'fixedWidth':
        try {
          column.fixedWidth = bool.parse(value);
        } catch (e) {
          _log.severe('Unable to parse fixedWidth as bool: ${a.toXmlString()}');
        }
      case 'offset':
        try {
          column.offset = int.parse(value);
        } catch (e) {
          _log.severe('Unable to parse offset as int: ${a.toXmlString()}');
        }
      case 'checkbox':
        switch (value) {
          case 'on':
            column.checkbox = true;
          case 'off':
            column.checkbox = false;
          default:
            _log.severe('Unable to parse checkbox as bool: ${a.toXmlString()}');
        }
      case 'value':
        column.value = value;
      case 'number':
        try {
          column.number = int.parse(value);
        } catch (e) {
          _log.severe('Unable to parse number as int: ${a.toXmlString()}');
        }
      default:
        _log.severe('Unexpected attribute name in menu notify message: $name');
    }
  }
  return column;
}
