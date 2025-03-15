import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

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
  final socket =
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, _transponderPort);
  socket.broadcastEnabled = true;
  final stream = socket.timeout(Duration(seconds: timeoutSec));
  final ping = _pingRequest();
  await for (final event in stream) {
    switch (event) {
      case RawSocketEvent.write:
        final bytesSent = socket.send(
            ping.codeUnits, InternetAddress(_broadcastAddress), _pingPort);
        if (bytesSent == 0) {
          throw 'Unable to send broadcast ping.';
        }
        _log.info('sent: $ping');
        break;
      case RawSocketEvent.read:
        final datagram = socket.receive();
        socket.close();
        final data = String.fromCharCodes(datagram!.data);
        _log.info('received: $data');
        final device = _parseTransponder(data, datagram.address);
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

/// Continuously discovers Emotiva devices on the network.
///
/// [listen] yields [Device] objects as they are discovered. A ping request is
/// broadcast on the network every 5s once [listen] is called and until [close]
/// is called. [close] also tears down the listening socket.
///
/// It is up to the caller of [listen] to deduplicate yielded devices. The
/// [Device] objects can be added to a [Set] to acheve this.
class MultiDeviceDiscover {
  RawDatagramSocket? _socket;
  Timer? _pinger;

  void close() {
    if (_socket != null) {
      _socket!.close();
      _log.info('No longer listening for Emotiva transponder packets.');
    }
    if (_pinger != null) {
      _pinger!.cancel();
    }
  }

  void _ping() {
    final ping = _pingRequest();
    final bytesSent = _socket!
        .send(ping.codeUnits, InternetAddress(_broadcastAddress), _pingPort);
    if (bytesSent == 0) {
      _log.severe('Unable to send broadcast ping.');
    } else {
      _log.info('sent: $ping');
    }
  }

  Stream<Device> listen() async* {
    _socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, _transponderPort);
    _socket!.broadcastEnabled = true;
    _ping();
    _pinger = Timer.periodic(const Duration(seconds: 5), (_) => _ping());
    await for (final event in _socket!) {
      switch (event) {
        case RawSocketEvent.write:
          break;
        case RawSocketEvent.read:
          final datagram = _socket!.receive();
          final data = String.fromCharCodes(datagram!.data);
          _log.info('received: $data');
          final device = _parseTransponder(data, datagram.address);
          yield device;
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

Device _parseTransponder(String data, InternetAddress address) {
  final document = XmlDocument.parse(data);
  final root = document.rootElement;
  if (root.name.toString() != 'emotivaTransponder') {
    throw Exception(
        'Received improperly formatted emotivaTransponder response.');
  }
  final device = Device(address);
  device.model = _textFromElement(root, 'model');
  device.name = _textFromElement(root, 'name');
  device.dataRevision = _textFromElement(root, 'dataRevision');
  device.controlVersion = _textFromElement(root, './control/version');
  device.controlPort = _intFromElement(root, './control/controlPort');
  device.notifyPort = _intFromElement(root, './control/notifyPort');
  device.infoPort = _intFromElement(root, './control/infoPort');
  device.setupPortTcp = _intFromElement(root, './control/setupPortTCP');
  device.menuNotifyPort = _intFromElement(root, './control/menuNotifyPort');
  device.setupXmlVersion = _intFromElement(root, './control/setupXMLVersion');
  return device;
}

enum TunerBand { unknown, am, fm }

/// A model of an Emotiva device.
class Device {
  InternetAddress address;
  String model = '';
  String dataRevision = '';
  String name = '';
  String controlVersion = '';
  int controlPort = 0;
  int notifyPort = 0;
  int infoPort = 0;
  int setupPortTcp = 0;
  int menuNotifyPort = 0;
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
  TunerBand tunerBand = TunerBand.unknown;
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
  late RawDatagramSocket _controlSocket;
  late RawDatagramSocket _notifySocket;
  late RawDatagramSocket _menuNotifySocket;
  late RawDatagramSocket _sendSocket;
  // Used in a lot of places to safety check whether it's OK to work with the
  // socket objects.
  /// Set to true in [bindListeningSockets].
  bool socketsBound = false;
  final Set<String> _subscribedFields = {};
  // Sequence numbers sent bn Emotiva are an unsigned int. -1 indicates we've
  // not yet gotten a real sequence number.
  int _sequenceNumber = -1;

  Device(this.address);

  // The hashCode and == operator override allow Device to be placed into a Set.
  // This is useful when discoverying multiple Emotiva devices on a network.
  // The assuption is that each unique device will have its own IP address.
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

  Stream<String> _socketStream(RawDatagramSocket socket) async* {
    if (!socketsBound) {
      throw 'Sockets must be bound before listening streams can be set up.';
    }
    await for (final event in socket) {
      switch (event) {
        case RawSocketEvent.read:
          final datagram = socket.receive();
          // Drop packets not from the address of the discovered Emotiva device.
          if (datagram!.address != address) {
            _log.warning('Ignoring packet from ${datagram.address}');
            break;
          }
          final packet = String.fromCharCodes(datagram.data);
          _log.info('received: $packet');
          yield packet;
        case RawSocketEvent.closed:
          break;
        case RawSocketEvent.readClosed:
          break;
        default:
          throw 'Unexpected event $event';
      }
    }
  }

  Future<void> bindListeningSockets() async {
    _controlSocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, controlPort);
    _controlSocket.writeEventsEnabled = false;
    _log.info('Control socket bound.');
    _notifySocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, notifyPort);
    _notifySocket.writeEventsEnabled = false;
    _log.info('Notify socket bound.');
    _menuNotifySocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, menuNotifyPort);
    _menuNotifySocket.writeEventsEnabled = false;
    _log.info('Menu Notify socket bound.');
    _sendSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _log.info('Send socket bound.');
    socketsBound = true;
  }

  /// Close any sockets opened so far by this object.
  void closeSockets() {
    if (!socketsBound) return;
    _controlSocket.close();
    _notifySocket.close();
    _menuNotifySocket.close();
    _sendSocket.close();
    socketsBound = false;
    _log.info('Sockets closed.');
  }

  /// Stream of messages arriving on the control socket.
  Stream<String> controlPortStream() => _socketStream(_controlSocket);

  /// Stream of messages arriving on the notify socket.
  Stream<String> notifyPortStream() => _socketStream(_notifySocket);

  /// Stream of messages arriving on the menu notify socket.
  Stream<String> menuNotifyPortStream() => _socketStream(_menuNotifySocket);

  void _send(String request, int destinationPort) {
    if (!socketsBound) {
      throw 'Send socket must be bound before sending data on it.';
    }
    _log.info('sending: $request');
    // OMG, send() does not return a Future. Since UDP is fire-and-forget, I
    // don't suppose it was necessary for it to.
    final bytesSent =
        _sendSocket.send(request.codeUnits, address, destinationPort);
    if (bytesSent == 0) {
      throw 'No bytes were sent';
    }
  }

  String _requestWithFields(String requestType, Iterable<String> fields) {
    final builder = XmlBuilder()..processing('xml', 'version="1.0"');
    builder.element(requestType, attributes: {'protocol': __protocolVersion()},
        nest: () {
      for (final f in fields) {
        builder.element(f);
      }
    });
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
    builder.element('emotivaControl',
        attributes: {'protocol': __protocolVersion()}, nest: () {
      builder.element(command,
          attributes: {'value': value, 'ack': ack ? 'yes' : 'no'});
    });
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
  /// [data] should be a message yielded by [controlPortStream] or
  /// [notifyPortStream].
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
      _log.info('Recieved an unsubscribe request: ${root.toXmlString()}');
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
          _log.warning("It looks like we're behind one or more messages. "
              "Updating all fields.");
          _sequenceNumber = serverSequence;
          updateAll();
        } else {
          // The only case left is that serverSequence is <= _sequnceNumber.
          if (pow(2, 32) - _sequenceNumber < 1000) {
            // My simple attempt at rollover detection. Emotiva documents that
            // the sequence number they produce is an unsigned int. If, somehow
            // we get within 1000 of 2^32 and the serverSequence number is
            // lower than our's, let's assume we've rolled over and adopt the
            // remote sequence number.
            _sequenceNumber = serverSequence;
            _log.info('Sequence rollover heuristic has kicked in.');
          }
          _log.warning("Received a message with an old sequence number. "
              "Calling updateAll() in case we've missed something.");
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
          break;
        case 'source':
          source = _valueAttribute(element.attributes);
          break;
        case 'mode':
          mode = _valueAttribute(element.attributes);
          break;
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
          break;
        case 'loudness':
          loudness = _valueAttribute(element.attributes).toLowerCase() == 'on'
              ? true
              : false;
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
        case 'center':
          centerTrim = _getSpeakerTrim(element);
          break;
        case 'subwoofer':
          subwooferTrim = _getSpeakerTrim(element);
          break;
        case 'surround':
          surroundTrim = _getSpeakerTrim(element);
          break;
        case 'back':
          backTrim = _getSpeakerTrim(element);
          break;
        case 'width':
          widthTrim = _getSpeakerTrim(element);
          break;
        case 'height':
          heightTrim = _getSpeakerTrim(element);
          break;
        case 'treble':
          trebleTrim = _getDoubleAttribute(_valueAttribute(element.attributes));
          break;
        case 'bass':
          bassTrim = _getDoubleAttribute(_valueAttribute(element.attributes));
          break;
        // "mode_*" fields indicate whether these modes are selectable on the
        // device via the "visible" atttribute.
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
          break;
        case 'selected_mode':
          selectedMode = _valueAttribute(element.attributes);
          break;
        case 'selected_movie_music':
          selectedMovieMusic = _valueAttribute(element.attributes);
          break;
        case 'zone2_power':
          final value = _valueAttribute(element.attributes);
          if (value == 'On') {
            zone2Power = true;
          } else {
            zone2Power = false;
          }
          break;
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
          break;
        case 'zone2_input':
          zone2Input = _valueAttribute(element.attributes);
          break;
        case 'tuner_band':
          final band = _valueAttribute(element.attributes).toLowerCase();
          if (band == 'am') {
            tunerBand = TunerBand.am;
          } else if (band == 'fm') {
            tunerBand = TunerBand.fm;
          } else {
            _log.severe('Unrecognized tuner band: $band');
          }
          break;
        case 'tuner_channel':
          tunerChannel = _valueAttribute(element.attributes);
          break;
        case 'tuner_signal':
          tunerSignal = _valueAttribute(element.attributes);
          break;
        case 'tuner_program':
          tunerProgram = _valueAttribute(element.attributes);
          break;
        case 'tuner_RDS':
          tunerRds = _valueAttribute(element.attributes);
          break;
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
          break;
        case 'menu':
          if (_valueAttribute(element.attributes).toLowerCase() == 'on') {
            menuDisplayed = true;
          } else {
            menuDisplayed = false;
          }
          break;
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
          break;
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

  /// Adjusts the center speaker trim.
  ///
  /// [trim] is a value between -24 and 24 representing 0.5dB steps between
  /// -12dB and +12dB.
  void trimCenter(double trim) {
    trim = trim * 2;
    return control('center_trim_set', value: trim.toString());
  }

  /// Adjusts the subwoofer trim.
  ///
  /// [trim] is a value between -24 and 24 representing 0.5dB steps between
  /// -12dB and +12dB.
  void trimSubwoofer(double trim) {
    trim = trim * 2;
    return control('subwoofer_trim_set', value: trim.toString());
  }

  /// Adjusts the trim for surround speakers.
  ///
  /// [trim] is a value between -24 and 24 representing 0.5dB steps between
  /// -12dB and +12dB.
  void trimSurround(double trim) {
    trim = trim * 2;
    return control('surround_trim_set', value: trim.toString());
  }

  /// Adjusts the trim for back (i.e. rear) speakers.
  ///
  /// [trim] is a value between -24 and 24 representing 0.5dB steps between
  /// -12dB and +12dB.
  void trimBack(double trim) {
    trim = trim * 2;
    return control('back_trim_set', value: trim.toString());
  }

  /// Adjusts the trim for height speakers.
  ///
  /// Only available in protocol version >= 3.0.
  /// [trim] is a value between -24 and 24 representing 0.5dB steps between
  /// -12dB and +12dB.
  void trimHeight(double trim) {
    trim = trim * 2;
    return control('height_trim_set', value: trim.toString());
  }

  /// Adjusts the trim for width speakers.
  ///
  /// Only available in protocol version >= 3.0.
  /// [trim] is a value between -24 and 24 representing 0.5dB steps between
  /// -12dB and +12dB.
  void trimWidth(double trim) {
    trim = trim * 2;
    return control('width_trim_set', value: trim.toString());
  }

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
  final _controlStream = StreamController<String>();
  final _notifyStream = StreamController<String>();
  final _menuNotifyStream = StreamController<String>();
  int _sequence = 0;

  FakeDevice(super.address) {
    socketsBound = true;
    model = 'Fake Emotiva';
    name = 'Fake name';
    controlVersion = '3.0';
    controlPort = 1;
    notifyPort = 2;
    infoPort = 3;
    setupPortTcp = 4;
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
    tunerBand = TunerBand.fm;
    tunerSignal = '35 dBuV';
    tunerProgram = 'Classical';
    tunerRds = 'WCPE: Mahler 5';
    tunerChannel = 'FM 89.7';
  }

  Menu _initMenuContent() {
    final menu = Menu();
    // Their API docs say there are always 11 rows.
    for (int i = 0; i < 11; i++) {
      final row = Row(i);
      // Their API docs say there are always 3 columns.
      for (int j = 0; j < 3; j++) {
        final column = Column(j, false, Arrow.no, false);
        row.columns.add(column);
      }
      // We only display rows 4, 5, and 6. The actual front display of the
      // RMC-1L does the same thing.
      if (i == 4) {
        row.columns[1].value = 'Lip Synch Auto';
        row.columns[1].arrow = Arrow.up;
        row.columns[2].checkbox = true;
      }
      if (i == 5) {
        row.columns[0].value = 'HDMI 1';
        row.columns[0].arrow = Arrow.left;
        row.columns[1].value = 'Button';
        row.columns[1].highlight = true;
        row.columns[2].value = 'Input 1';
        row.columns[2].arrow = Arrow.right;
      }
      if (i == 6) {
        row.columns[1].value = '5.1 Mode';
        row.columns[1].arrow = Arrow.down;
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

  void _updateBuilder(builder, String field, String value) {
    builder.element('property', attributes: {
      'name': field,
      'value': value,
      'visible': _getVisibilityForField(field),
      'status': 'ack'
    });
  }

  void _parseUpdateRequest(Iterable<String> fields) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('emotivaUpdate', attributes: {'protocol': '3.0'}, nest: () {
      for (final f in fields) {
        try {
          _updateBuilder(builder, f, _getValueForField(f));
        } catch (e) {
          // Unknown field.
          builder.element(f,
              attributes: {'value': '', 'visible': 'true', 'status': 'nak'});
        }
      }
    });
    final response = builder.buildDocument().toXmlString(pretty: true);
    _log.info('response: $response');
    _controlStream.add(response);
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
          break;
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
            _log.severe(
                'Unable to parse volume delta: ${element.toXmlString()}');
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
          audioInput = 'HDMI ARC';
          source = audioInput;
          updatedFields.addAll(['audio_input', 'source']);
          break;
        case 'usb_stream':
          audioInput = 'USB Stream';
          source = audioInput;
          updatedFields.addAll(['audio_input', 'source']);
          break;
        case 'tuner':
          audioInput = 'Tuner';
          source = audioInput;
          updatedFields.addAll(['audio_input', 'source']);
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
          source = audioInput;
          updatedFields.addAll(['audio_input', 'source']);
          break;
        case 'source_1':
          audioInput = 'Balanced In';
          videoInput = 'HDMI 1';
          source = names['input_1']!;
          updatedFields.addAll(['audio_input', 'video_input', 'source']);
          break;
        case 'source_2':
          audioInput = 'Analog 1';
          source = names['input_2']!;
          updatedFields.addAll(['audio_input', 'source']);
          break;
        case 'source_3':
          audioInput = 'HDMI 3';
          videoInput = 'HDMI 3';
          source = 'HDMI 3';
          updatedFields.addAll(['audio_input', 'video_input', 'source']);
          break;
        case 'source_4':
          audioInput = 'HDMI 4';
          videoInput = 'HDMI 4';
          source = 'HDMI 4';
          updatedFields.addAll(['audio_input', 'video_input', 'source']);
          break;
        case 'source_5':
          audioInput = 'HDMI 5';
          videoInput = 'HDMI 5';
          source = 'HDMI 5';
          updatedFields.addAll(['audio_input', 'video_input', 'source']);
          break;
        case 'source_6':
          audioInput = 'HDMI 6';
          videoInput = 'HDMI 6';
          source = 'HDMI 6';
          updatedFields.addAll(['audio_input', 'video_input', 'source']);
          break;
        case 'source_7':
          audioInput = 'HDMI 7';
          videoInput = 'HDMI 7';
          source = 'HDMI 7';
          updatedFields.addAll(['audio_input', 'video_input', 'source']);
          break;
        case 'source_8':
          audioInput = 'HDMI 8';
          videoInput = 'HDMI 8';
          source = 'HDMI 8';
          updatedFields.addAll(['audio_input', 'video_input', 'source']);
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
        case 'treble_up':
          trebleTrim += 0.5;
          updatedFields.add('treble');
          break;
        case 'treble_down':
          trebleTrim -= 0.5;
          updatedFields.add('treble');
          break;
        case 'bass_up':
          bassTrim += 0.5;
          updatedFields.add('bass');
          break;
        case 'bass_down':
          bassTrim -= 0.5;
          updatedFields.add('bass');
          break;
        case 'menu':
          menuDisplayed = menuDisplayed ? false : true;
          updatedFields.add('menu');
          if (menuDisplayed) _notifyMenuSubscribers();
          break;
        case 'up':
          _notifyMenuSubscribers();
          break;
        case 'down':
          _notifyMenuSubscribers();
          break;
        case 'left':
          _notifyMenuSubscribers();
          break;
        case 'right':
          _notifyMenuSubscribers();
          break;
        case 'enter':
          _notifyMenuSubscribers();
          break;
        case 'zone2_power':
          zone2Power = zone2Power ? false : true;
          updatedFields.add('zone2_power');
          break;
        case 'zone2_volume':
          try {
            final delta = double.parse(_getValue(element));
            zone2Volume += delta;
            zone2Muted = false;
            updatedFields.add(field);
          } catch (e) {
            _log.severe(
                'Unable to parse zone 2 volume delta: ${element.toXmlString()}');
          }
          break;
        case 'zone2_mute':
          zone2Muted = zone2Muted ? false : true;
          // Emotiva uses the volume field to indicate whether the device is
          // muted.
          updatedFields.add('zone2_volume');
        case 'zone2_analog1':
          zone2Input = 'Analog 1';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_analog2':
          zone2Input = 'Analog 2';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_analog3':
          zone2Input = 'Analog 3';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_analog4':
          zone2Input = 'Analog 4';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_analog5':
          zone2Input = 'Balanced In';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_front_in':
          zone2Input = 'Front';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_follow_main':
          zone2Input = audioInput;
          updatedFields.add('zone2_input');
          break;
        case 'zone2_coax1':
          zone2Input = 'Coax 1';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_coax2':
          zone2Input = 'Coax 2';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_coax3':
          zone2Input = 'Coax 3';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_coax4':
          zone2Input = 'Coax 4';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_coax5':
          zone2Input = 'AES/EBU';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_optical1':
          zone2Input = 'Optical 1';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_optical2':
          zone2Input = 'Optical 2';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_optical3':
          zone2Input = 'Optical 3';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_optical4':
          zone2Input = 'Optical 4';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_usb_stream':
          zone2Input = 'USB Stream';
          updatedFields.add('zone2_input');
          break;
        case 'zone2_tuner':
          zone2Input = 'Tuner';
          updatedFields.add('zone2_input');
          break;
        case 'zone1_band':
          if (tunerBand == TunerBand.am) {
            tunerBand = TunerBand.fm;
            tunerChannel = 'FM 89.7';
            tunerProgram = 'Classical';
            tunerRds = 'WCPE: Mahler 5';
            tunerSignal = '45 dBuV';
          } else {
            tunerBand = TunerBand.am;
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
            'tuner_signal'
          ]);
          break;
        default:
          _log.warning('FakeDevice does not support: $field');
          break;
      }
    }
    _notifySubscribers(updatedFields);
  }

  void _notifyMenuSubscribers() {
    final builder = XmlBuilder()..processing('xml', 'version="1.0"');
    builder.element('emotivaMenuNotify',
        attributes: {'sequence': _sequence.toString()}, nest: () {
      for (final row in menuContents.rows) {
        builder.element('row', attributes: {'number': row.number.toString()},
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
              attributes['offset'] = '5'; // just making something up for now
            }
            if (column.checkbox ?? false) {
              attributes.remove('value');
              attributes['checkbox'] = 'on';
            }
            builder.element('col', attributes: attributes);
          }
        });
      }
    });
    final response = builder.buildDocument().toXmlString(pretty: true);
    _log.info('response: $response');
    _sequence++;
    _menuNotifyStream.add(response);
  }

  void _notifySubscribers(Set<String> updatedFields) {
    // Note that updatedFields has already been vetted by other methods before
    // this method is called.
    final builder = XmlBuilder()..processing('xml', 'version="1.0"');
    builder.element('emotivaNotify',
        attributes: {'sequence': _sequence.toString()}, nest: () {
      for (final field in updatedFields) {
        String value = _getValueForField(field);
        String visible = _getVisibilityForField(field);
        builder.element('property',
            attributes: {'name': field, 'value': value, 'visible': visible});
      }
    });
    final response = builder.buildDocument().toXmlString(pretty: true);
    _log.info('response: $response');
    _sequence++;
    _notifyStream.add(response);
  }

  String _getValueForField(String field) {
    switch (field) {
      case 'power':
        return power ? 'On' : 'False';
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
        return loudness ? 'On' : 'Off';
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
        if (!visibility[field]!) return 'None';
        return centerTrim.toString();
      case 'width':
        if (!visibility[field]!) return 'None';
        return widthTrim.toString();
      case 'subwoofer':
        if (!visibility[field]!) return 'None';
        return subwooferTrim.toString();
      case 'surround':
        if (!visibility[field]!) return 'None';
        return surroundTrim.toString();
      case 'back':
        if (!visibility[field]!) return 'None';
        return backTrim.toString();
      case 'height':
        if (!visibility[field]!) return 'None';
        return heightTrim.toString();
      case 'treble':
        return trebleTrim.toString();
      case 'bass':
        return bassTrim.toString();
      case 'selected_mode':
        return selectedMode;
      case 'selected_movie_music':
        return selectedMovieMusic;
      case 'input_1':
        return names['input_1']!;
      case 'input_2':
        return names['input_2']!;
      case 'input_3':
        return names['input_3']!;
      case 'input_4':
        return names['input_4']!;
      case 'input_5':
        return names['input_5']!;
      case 'input_6':
        return names['input_6']!;
      case 'input_7':
        return names['input_7']!;
      case 'input_8':
        return names['input_8']!;
      case 'mode_ref_stereo':
        return 'Reference Stereo';
      case 'mode_stereo':
        return 'Stereo';
      case 'mode_music':
        return 'Music';
      case 'mode_movie':
        return 'Movie';
      case 'mode_direct':
        return 'Direct';
      case 'mode_dolby':
        return 'Dolby Surround';
      case 'mode_dts':
        return 'dtsX';
      case 'mode_all_stereo':
        return 'All Stereo';
      case 'mode_auto':
        return 'Auto';
      case 'mode_surround':
        return 'Dolby Surround';
      case 'menu':
        return menuDisplayed ? 'On' : 'Off';
      case 'menu_update':
        return '';
      case 'zone2_power':
        return zone2Power ? 'On' : 'Off';
      case 'zone2_volume':
        if (zone2Muted) {
          return 'Mute';
        }
        return zone2Volume.toString();
      case 'zone2_input':
        return zone2Input;
      case 'tuner_band':
        return tunerBand.name.toUpperCase();
      case 'tuner_channel':
        return tunerChannel;
      case 'tuner_signal':
        return tunerSignal;
      case 'tuner_RDS':
        return tunerRds;
      case 'tuner_program':
        return tunerProgram;
      default:
        throw 'Unsupported field: $field';
    }
  }

  String _getVisibilityForField(String field) {
    bool visible = visibility[field] ?? true;
    return visible.toString().toLowerCase();
  }

  void _parseSubscriptionRequest(Iterable<String> fields) {
    final builder = XmlBuilder()..processing('xml', 'version="1.0"');
    builder.element('emotivaSubscription', attributes: {'protocol': '3.0'},
        nest: () {
      for (final field in fields) {
        if (Device._fields.contains(field)) {
          _subscribedFields.add(field);
          builder.element('property', attributes: {
            'name': field,
            'value': _getValueForField(field),
            'status': 'ack',
            'visible': _getVisibilityForField(field),
          });
        } else {
          // Return nak status for unknown fields.
          builder.element(field, attributes: {'status': 'nak'});
        }
      }
    });
    final response = builder.buildDocument().toXmlString(pretty: true);
    _log.info('response: $response');
    _controlStream.add(response);
  }

  void _parseUnsubscribeRequest(Iterable<String> fields) {
    String status = 'nak';
    final builder = XmlBuilder()..processing('xml', 'version="1.0"');
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
    _log.info('request: ${root.toXmlString(pretty: true)}');
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
  void _send(String request, int destinationPort) async {
    // destinationPort seems to always be controlPort.
    _parseRequest(request);
  }

  @override
  Future<void> bindListeningSockets() async {
    socketsBound = true;
  }

  @override
  void closeSockets() {
    _controlStream.close();
    _notifyStream.close();
    _menuNotifyStream.close();
    socketsBound = false;
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

  @override
  Stream<String> menuNotifyPortStream() async* {
    await for (final data in _menuNotifyStream.stream) {
      yield data;
    }
  }
}

/// This function is meant to be mostly a stand-in replacement for [discovery].
Future<FakeDevice> futureFakeDevice() async {
  return FakeDevice(InternetAddress('192.168.42.1'));
}

// These enums represet the UI elements of the on-screen display menu.
enum Arrow {
  no,
  up,
  down,
  right,
  left;
}

class Column {
  int number = 0;
  bool highlight = false;
  Arrow arrow = Arrow.no;
  bool fixedWidth = false;
  // The offset seems to be only informational. It's only used when fixedWidth
  // is true and the contents of "value" already includes the offset padding.
  int? offset;
  bool? checkbox;
  String value;

  Column(this.number, this.highlight, this.arrow, this.fixedWidth,
      {this.offset, this.checkbox, this.value = ''});
}

class Row {
  int number = 0;
  List<Column> columns = [];

  Row(this.number);
}

class Menu {
  List<Row> rows = [];
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
        break;
      case 'arrow':
        switch (value.toLowerCase()) {
          case 'no':
            column.arrow = Arrow.no;
            break;
          case 'up':
            column.arrow = Arrow.up;
            break;
          case 'down':
            column.arrow = Arrow.down;
            break;
          case 'right':
            column.arrow = Arrow.right;
            break;
          case 'left':
            column.arrow = Arrow.left;
            break;
          default:
            _log.severe('Unexpected value for "arrow": $value');
            break;
        }
      case 'fixedWidth':
        try {
          column.fixedWidth = bool.parse(value);
        } catch (e) {
          _log.severe('Unable to parse fixedWidth as bool: ${a.toXmlString()}');
        }
        break;
      case 'offset':
        try {
          column.offset = int.parse(value);
        } catch (e) {
          _log.severe('Unable to parse offset as int: ${a.toXmlString()}');
        }
        break;
      case 'checkbox':
        switch (value) {
          case 'on':
            column.checkbox = true;
            break;
          case 'off':
            column.checkbox = false;
            break;
          default:
            _log.severe('Unable to parse checkbox as bool: ${a.toXmlString()}');
            break;
        }
        break;
      case 'value':
        column.value = value;
        break;
      case 'number':
        try {
          column.number = int.parse(value);
        } catch (e) {
          _log.severe('Unable to parse number as int: ${a.toXmlString()}');
        }
        break;
      default:
        _log.severe('Unexpected attribute name in menu notify message: $name');
        break;
    }
  }
  return column;
}

/// Provide the column/row position for an [arrowType].
///
/// A value of -1 means that [arrowType] is not currently visible.  If the
/// [arrowType] is left or right, the returned value respresents which row
/// should display the arrow. If the [arrowType] is up or down, the returned
/// value represents which column should display the arrow.
int arrowPosition(Menu menu, Arrow arrowType) {
  for (final row in menu.rows) {
    for (final column in row.columns) {
      switch (arrowType) {
        case Arrow.up || Arrow.down:
          if (column.arrow == arrowType) return column.number;
          break;
        case Arrow.left || Arrow.right:
          if (column.arrow == arrowType) return row.number;
          break;
        default:
          break;
      }
    }
  }
  return -1;
}
