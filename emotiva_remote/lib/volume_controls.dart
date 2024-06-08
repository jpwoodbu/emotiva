import 'package:emotiva_remote/device_changes.dart';
import 'package:emotiva_remote/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_android_volume_keydown/flutter_android_volume_keydown.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';

final _log = Logger('VolumeControls');

class VolumeControls extends StatelessWidget {
  const VolumeControls({super.key});

  @override
  Widget build(BuildContext context) {
    _log.info('Building footer widget.');
    // Change the volume controls to actuate zone 2 when on the zone 2 page.
    // final volumeFunction =
    //     currentPageIndex == 4 ? device.zone2VolumeDelta : device.volumeDelta;
    final volumeFunction = context.read<DeviceChanges>().device.volumeDelta;
    final throttledVolumeFunction =
        volumeFunction.throttled(const Duration(seconds: 1));
    // TODO - Find some way to manage the lifecycle of this subscription.
    // TODO - I think this widget and this subscription are being rebuilt everyday
    // a new device update comes back when the volume changes. The symptom is that
    // a single volume key press makes massive changes to the volume.
    FlutterAndroidVolumeKeydown.stream.listen((event) async {
      if (event == HardwareButton.volume_down) {
        volumeFunction(-1.0);
      } else if (event == HardwareButton.volume_up) {
        volumeFunction(1.0);
      } else {
        _log.warning('Unrecognized hardware button: $event');
      }
    });
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Text('Volume', style: TextStyle(fontSize: 20.0)),
        ),
        Row(
          children: [
            ElevatedButton(
                onPressed: () => addHaptic(() => volumeFunction(-1.0)),
                child: const Icon(
                  Icons.remove,
                  size: 30.0,
                  semanticLabel: 'Volume down',
                )),
            const SizedBox(width: 15.0),
            ElevatedButton(
                onPressed: () => addHaptic(() => volumeFunction(1.0)),
                child: const Icon(
                  Icons.add,
                  size: 30.0,
                  semanticLabel: 'Volume up',
                )),
          ],
        ),
      ],
    );
  }
}
