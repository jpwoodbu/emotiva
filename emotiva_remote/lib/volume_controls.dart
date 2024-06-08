import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_android_volume_keydown/flutter_android_volume_keydown.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'device_changes.dart';
import 'page_index_change_notifier.dart';

final _log = Logger('VolumeControls');

class VolumeControls extends StatefulWidget {
  const VolumeControls({super.key});

  @override
  State<VolumeControls> createState() => _VolumeControlsState();
}

class _VolumeControlsState extends State<VolumeControls> {
  late final Function _mainVolumeFunction;
  late final Function _zone2VolumeFunction;
  bool _controlMainVolume = true;

  @override
  void initState() {
    super.initState();
    final device = context.read<DeviceChanges>().device;
    _mainVolumeFunction = device.volumeDelta;
    _zone2VolumeFunction = device.zone2VolumeDelta;

    if (Platform.isAndroid) {
      FlutterAndroidVolumeKeydown.stream.listen((event) async {
        if (event == HardwareButton.volume_down) {
          volumeDown();
        } else if (event == HardwareButton.volume_up) {
          volumeUp();
        } else {
          _log.warning('Unrecognized hardware button: $event');
        }
      });
    }
  }

  void volumeDown() {
    HapticFeedback.lightImpact();
    if (_controlMainVolume) {
      _mainVolumeFunction(-1.0);
    } else {
      _zone2VolumeFunction(-1.0);
    }
  }

  void volumeUp() {
    HapticFeedback.lightImpact();
    if (_controlMainVolume) {
      _mainVolumeFunction(1.0);
    } else {
      _zone2VolumeFunction(1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const iconSize = 30.0;
    // Page index 4 is the zone 2 controls page.
    _controlMainVolume =
        context.watch<PageIndexChangeNotifier>().pageIndex != 4;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            'Volume',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: volumeDown,
              child: const Icon(
                Icons.remove,
                size: iconSize,
                semanticLabel: 'Volume down',
              ),
            ),
            const SizedBox(width: 15.0),
            ElevatedButton(
              onPressed: volumeUp,
              child: const Icon(
                Icons.add,
                size: iconSize,
                semanticLabel: 'Volume up',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
