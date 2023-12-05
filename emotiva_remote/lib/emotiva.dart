import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

const int pingPort = 7000;
const int transponderPort = 7001;
const String broadcastAddress = '255.255.255.255';
const String protocolVersion = '2.0';

void _log(String message) {
  developer.log(message, name: 'emotiva');
}

String _pingRequest() {
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0"');
  builder.element('emotivaPing', attributes: {'protocol': protocolVersion});
  return builder.buildDocument().toXmlString();
}

/// Discovers an Emotiva device on the network and returns a [Device].
///
/// A socket is opened to listen for a transponder packet from an Emotiva
/// device. While open, a ping packet is broadcast on the network. The listening
/// socket waits for [timeoutSec] before giving up and throwing an exception.
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
        final device = _parseTransponder(data);
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

Device _parseTransponder(String data) {
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

/// A model of an Emotiva device.
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
  double widthTrim = 0.0;
  double subwooferTrim = 0.0;
  double surroundTrim = 0.0;
  double backTrim = 0.0;
  double heightTrim = 0.0;
  String selectedMode = '';
  String selectedMovieMusic = '';
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
  };
  final List<RawDatagramSocket> _sockets = [];
  final Set<String> _subscribedFields = {};
  // Sequence numbers sent bn Emotiva are an unsigned int. -1 indicates we've
  // not yet gotten a real sequence number.
  int _sequenceNumber = -1;

  Stream<String> _socketStream(int port, InternetAddress address) async* {
    final stream = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    stream.writeEventsEnabled = false;
    _sockets.add(stream);
    await for (final event in stream) {
      switch (event) {
        case RawSocketEvent.read:
          final datagram = stream.receive();
          // Drop packets not from the address of the discovered Emotiva device.
          if (datagram!.address != address) {
            _log('Ignoring packet from ${datagram.address}');
            break;
          }
          yield String.fromCharCodes(datagram.data);
        case RawSocketEvent.closed:
          break;
        case RawSocketEvent.readClosed:
          break;
        default:
          throw 'Unexpected event $event';
      }
    }
  }

  /// Stream of messages arriving on the control port.
  Stream<String> controlPortStream(InternetAddress address) {
    return _socketStream(controlPort, address);
  }

  /// Stream of messages arriving on the notify port.
  Stream<String> notifyPortStream(InternetAddress address) {
    return _socketStream(notifyPort, address);
  }

  /// Close any sockets opened so far by this object.
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
          _log('sending: $request');
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
    builder.element(requestType, attributes: {'protocol': protocolVersion},
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
  Future<void> update(Iterable<String> fields) async {
    await _send(_updateRequest(fields), controlPort);
  }

  /// Sends a request to get the current value for all supported fields.
  ///
  /// Supported fields are a hardcoded list of fields understood by this
  /// library.
  Future<void> updateAll() async => await update(_fields);

  String _subscribeRequest(Iterable<String> fields) {
    return _requestWithFields('emotivaSubscription', fields);
  }

  /// Sends a request to get notified when any of [fields] change in value.
  Future<void> subscribe(Iterable<String> fields) async {
    // Since we're going to be looping over this, we should make a local copy to
    // avoid getting a ConcurrentModificationError.
    final localFields = Set<String>.from(fields);
    await _send(_subscribeRequest(localFields), controlPort);
    for (final f in localFields) {
      _subscribedFields.add(f);
    }
  }

  /// Sends a request to get notified when any of the supported fields change.
  ///
  /// Supported fields are a hardcoded list of fields understood by this
  /// library.
  Future<void> subscribeAll() async => await subscribe(_fields);

  String _unsubscribeRequest(Iterable<String> fields) {
    return _requestWithFields('emotivaUnsubscribe', fields);
  }

  /// Sends a request to stop being notified when [fields] change.
  ///
  /// Supported fields are a hardcoded list of fields understood by this
  /// library.
  Future<void> unsubscribe(Iterable<String> fields) async {
    // Since we're going to be looping over this, we should make a local copy to
    // avoid getting a ConcurrentModificationError.
    final localFields = Set<String>.from(fields);
    await _send(_unsubscribeRequest(localFields), controlPort);
    for (final f in localFields) {
      _subscribedFields.remove(f);
    }
  }

  /// Sends a request to stop being notified when supported fields change.
  Future<void> unsubscribeAll() async => await unsubscribe(_subscribedFields);

  String _controlRequest(String command, String value, bool ack) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('emotivaControl', attributes: {'protocol': protocolVersion},
        nest: () {
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
  Future<void> control(String command,
      {String value = '0', bool ack = false}) async {
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

  bool _visibleAttribute(List<XmlAttribute> attributes) {
    for (final a in attributes) {
      if (a.name.toString() == 'visible') {
        return bool.parse(a.value.trim(), caseSensitive: false);
      }
    }
    throw 'Element missing visible attribute';
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

  double _getSpeakerTrim(XmlElement element) {
    final trim = _valueAttribute(element.attributes);
    if (trim == 'None') {
      return 0.0;
    } else {
      try {
        // There could be a space after the sign, which would break
        // double.parse().
        return double.parse(trim.replaceAll(r' ', ''));
      } catch (e) {
        _log(
            'Casting trim value to double failed for ${element.toXmlString()}: $e');
      }
    }
    return 0.0;
  }

  /// Parses all messages types other than transponder messages.
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
      _log('Received an ack message: ${root.toXmlString()}');
      return;
    }
    if (packetType == 'emotivaUnsubscribe') {
      // If we get a response from an unsubscribe request before we tear down
      // the socket, catch it and do nothing.
      _log('Recieved an unsubscribe request: ${root.toXmlString()}');
      return;
    }
    if (packetType == 'emotivaNotify') {
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
          _log("It looks like we're behind one or more messages. "
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
            _log('Sequence rollover heuristic has kicked in.');
          }
          _log("Received a message with an old sequence number. "
              "Calling updateAll() in case we've missed something.");
          updateAll();
          return;
        }
      } catch (e) {
        // If we can't find a sequence number, just assume we should continue
        // processing this packet.
        _log('Sequence number missing: ${root.toXmlString()}');
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
            _log('Unable to parse message: $e');
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
        // "mode*" fields indicate whether these modes are selectable on the
        // device via the "visibility" atttribute.
        case 'mode_ref_stereo':
          break;
        case 'mode_stereo':
          break;
        case 'mode_music':
          break;
        case 'mode_movie':
          break;
        case 'mode_direct':
          break;
        case 'mode_dolby':
          break;
        case 'mode_dts':
          break;
        case 'mode_all_stereo':
          break;
        case 'mode_auto':
          break;
        case 'mode_surround':
          break;
        case 'selected_mode':
          selectedMode = _valueAttribute(element.attributes);
          break;
        case 'selected_movie_music':
          selectedMovieMusic = _valueAttribute(element.attributes);
          break;
        case 'treble':
          break;
        case 'bass':
          break;
        case 'zone2_power':
          break;
        case 'zone2_volume':
          break;
        case 'zone2_input':
          break;
        case 'tuner_band':
          break;
        case 'tuner_channel':
          break;
        case 'tuner_signal':
          break;
        case 'tuner_program':
          break;
        case 'tuner_RDS':
          break;
        case 'input_1':
          names['input_1'] = _valueAttribute(element.attributes);
          visibility['input_1'] = _visibleAttribute(element.attributes);
          break;
        case 'input_2':
          names['input_2'] = _valueAttribute(element.attributes);
          visibility['input_2'] = _visibleAttribute(element.attributes);
          break;
        case 'input_3':
          names['input_3'] = _valueAttribute(element.attributes);
          visibility['input_3'] = _visibleAttribute(element.attributes);
          break;
        case 'input_4':
          names['input_4'] = _valueAttribute(element.attributes);
          visibility['input_4'] = _visibleAttribute(element.attributes);
          break;
        case 'input_5':
          names['input_5'] = _valueAttribute(element.attributes);
          visibility['input_5'] = _visibleAttribute(element.attributes);
          break;
        case 'input_6':
          names['input_6'] = _valueAttribute(element.attributes);
          visibility['input_6'] = _visibleAttribute(element.attributes);
          break;
        case 'input_7':
          names['input_7'] = _valueAttribute(element.attributes);
          visibility['input_7'] = _visibleAttribute(element.attributes);
          break;
        case 'input_8':
          names['input_8'] = _valueAttribute(element.attributes);
          visibility['input_8'] = _visibleAttribute(element.attributes);
          break;
        case 'menu':
          break;
        case 'menu_update':
          break;
        case 'source_tuner':
          // I don't know what this one is. It's listed as a command in their
          // doc. But it seems to report the same value as "source".
          // TODO - remove this if Emotiva fixes the interface.
          break;
        default:
          _log('Could not parse ${element.toXmlString()}');
          break;
      }
    }
  }

  /// Changes the volume by [delta]dBs.
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

  /// Cycles the front display brightness.
  ///
  /// Brightness values cycle through 0%, 20%, 40%, 60%, 80%, and 100%.
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

  /// Displays the info table on OSD.
  void info() async {
    await control('info');
  }

  /// Sets the source to the user configurable inputs.
  void setSource(int input) async {
    await control('source_$input');
  }

  /// Sets the source to the HDMI input corresponding to [input].
  void setHdmi(int input) async {
    await control('hdmi$input');
  }

  /// Sets the audio source to the coax input corresponding to [input].
  void setCoax(int input) async {
    await control('coax$input');
  }

  /// Sets the audio source to the balanced digital input.
  void setAesEbu() async {
    // coax5 pulls up the AES/EBU input on the RMC-1.
    await control('coax5');
  }

  /// Sets the audio source to the optical input corresponding to [input].
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

  /// Sets the audio source to the analog input corresponding to [input].
  void setAnalog(int input) async {
    await control('analog$input');
  }

  /// Sets the audio source to the balanced analog input.
  void setBalancedInput() async {
    // analog5 bring up the balanced input on the RMC-1.
    await control('analog5');
  }

  /// Sets the audio source to the front analog input.
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

  /// Adjusts the center speaker trim.
  ///
  /// [trim] is a value between -24 and 24 representing 0.5dB steps between
  /// -12dB and +12dB.
  void trimCenter(double trim) async {
    trim = trim * 2;
    await control('center_trim_set', value: trim.toString());
  }

  /// Adjusts the subwoofer trim.
  ///
  /// [trim] is a value between -24 and 24 representing 0.5dB steps between
  /// -12dB and +12dB.
  void trimSubwoofer(double trim) async {
    trim = trim * 2;
    await control('subwoofer_trim_set', value: trim.toString());
  }

  /// Adjusts the trim for surround speakers.
  ///
  /// [trim] is a value between -24 and 24 representing 0.5dB steps between
  /// -12dB and +12dB.
  void trimSurround(double trim) async {
    trim = trim * 2;
    await control('surround_trim_set', value: trim.toString());
  }

  /// Adjusts the trim for back (i.e. rear) speakers.
  ///
  /// [trim] is a value between -24 and 24 representing 0.5dB steps between
  /// -12dB and +12dB.
  void trimBack(double trim) async {
    trim = trim * 2;
    await control('back_trim_set', value: trim.toString());
  }
}

/// A fake Device class that does not create or handle any network traffic.
///
/// This class is meant to be use for testing and demonstration.
/// This class only supports Emotiva protocol 2.0.
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
    names['input_1'] = 'Blu-Ray analog';
    names['input_2'] = 'Fancy pants DAC';
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

  void _parseUpdateRequest(Iterable<String> fields) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('emotivaUpdate', nest: () {
      for (final f in fields) {
        try {
          _updateBuilder(builder, f, _getValueForField(f));
        } catch (e) {
          // Unknown field.
          builder.element(f, attributes: {'value': '', 'status': 'nak'});
        }
      }
    });
    final response = builder.buildDocument().toXmlString();
    _log('response: $response');
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
      _log('Unable to get value from ${element.toXmlString()}: $e');
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
          power = 'On';
          updatedFields.add('power');
          break;
        case 'power_off':
          power = 'Off';
          updatedFields.add('power');
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
            _log('Unable to parse volume delta: ${element.toXmlString()}');
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
        String value = _getValueForField(field);
        String visible = _getVisibilityForField(field);
        builder
            .element(field, attributes: {'value': value, 'visible': visible});
      }
    });
    final response = builder.buildDocument().toXmlString();
    _log('response: $response');
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
      case 'width':
        return widthTrim.toString();
      case 'subwoofer':
        return subwooferTrim.toString();
      case 'surround':
        return surroundTrim.toString();
      case 'back':
        return backTrim.toString();
      case 'height':
        return heightTrim.toString();
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
      default:
        throw 'Unsupported field: $field';
    }
  }

  String _getVisibilityForField(String field) {
    if (field.startsWith('input_')) {
      bool visible = visibility[field] ?? false;
      return visible.toString().toLowerCase();
    } else {
      return 'true';
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
            'visible': _getVisibilityForField(field),
          });
        } else {
          // Return nak status for unknown fields.
          builder.element(field, attributes: {'status': 'nak'});
        }
      }
    });
    final response = builder.buildDocument().toXmlString();
    _log('response: $response');
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
    _log('request: $request');
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
  Future<void> _send(String request, int destinationPort) async {
    // destinationPort seems to always be controlPort.
    return _parseRequest(request);
  }

  @override
  Stream<String> controlPortStream(InternetAddress address) async* {
    await for (final data in _controlStream.stream) {
      yield data;
    }
  }

  @override
  Stream<String> notifyPortStream(InternetAddress address) async* {
    await for (final data in _notifyStream.stream) {
      yield data;
    }
  }
}

/// This function is meant to be mostly a stand-in replacement for [discovery].
Future<FakeDevice> futureFakeDevice() async {
  return FakeDevice();
}
