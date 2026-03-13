import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_android_volume_keydown/flutter_android_volume_keydown.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'package:emotiva_remote/device_changes.dart';
import 'package:emotiva_remote/page_index_change_notifier.dart';
import 'package:emotiva_remote/util.dart';

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
      FlutterAndroidVolumeKeydown.stream.listen((event) {
        if (event == .volume_down) {
          volumeDown();
        } else if (event == .volume_up) {
          volumeUp();
        } else {
          _log.warning('Unrecognized hardware button: $event');
        }
      });
    }
  }

  void volumeDelta(double delta) {
    if (_controlMainVolume) {
      _mainVolumeFunction(delta);
    } else {
      _zone2VolumeFunction(delta);
    }
  }

  void volumeDown() => volumeDelta(-1.0);
  void volumeUp() => volumeDelta(1.0);

  @override
  Widget build(BuildContext context) {
    const iconSize = 30.0;
    // Page index 4 is the zone 2 controls page.
    _controlMainVolume =
        context.watch<PageIndexChangeNotifier>().pageIndex != 4;
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Padding(
          padding: const .only(left: 10),
          child: TextButton.icon(
            label: Text(
              'Volume',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            icon: const Icon(Icons.tune),
            onPressed: () {
              showAdaptiveDialog(
                context: context,
                builder: (context) {
                  // DO NOT use the adaptive() constructor here. This control
                  // does not layout well using the Cupertino AlertDialog.
                  return AlertDialog(
                    title: const Text('Coarse volume'),
                    content: CorseVolumeButtons(
                      volumeFunction: (double delta) {
                        addHaptic(() => volumeDelta(delta));
                      },
                    ),
                    // Add vertical padding to reduce the chance of a touch
                    // miss; e.g. the close button. Eliminate horizontal padding
                    // to reduce the chance of an unnecessary wrap.
                    contentPadding: const .fromLTRB(0.0, 12.0, 0.0, 12.0),
                    actions: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => addHaptic(volumeDown),
              child: const Icon(
                Icons.remove,
                size: iconSize,
                semanticLabel: 'Volume down',
              ),
            ),
            const SizedBox(width: 15.0),
            ElevatedButton(
              onPressed: () => addHaptic(volumeUp),
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

class CorseVolumeButtons extends StatelessWidget {
  final Function(double) volumeFunction;
  const CorseVolumeButtons({required this.volumeFunction, super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: .center,
      children: [
        TextButton(
          onPressed: () => volumeFunction(-10.0),
          child: const Text('-10'),
        ),
        TextButton(
          onPressed: () => volumeFunction(-5.0),
          child: const Text('-5'),
        ),
        TextButton(
          onPressed: () => volumeFunction(5.0),
          child: const Text('+5'),
        ),
        TextButton(
          onPressed: () => volumeFunction(10.0),
          child: const Text('+10'),
        ),
      ],
    );
  }
}
