import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'inputs_page.dart';

import '../emotiva.dart' as emotiva;
import '../device_changes.dart';
import '../util.dart';

void _otherInputsSelector(BuildContext context, emotiva.Device device) {
  if (isApple(context)) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () => setUsbZone2(context, device),
            child: const Text('USB'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => setFrontZone2(context, device),
            child: const Text('Front'),
          ),
        ],
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      scrollControlDisabledMaxHeightRatio: 1.0,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: () => setUsbZone2(context, device),
                  icon: const Icon(Icons.usb),
                  label: const Text('USB')),
              ElevatedButton.icon(
                  onPressed: () => setFrontZone2(context, device),
                  icon: const Icon(Icons.smartphone),
                  label: const Text('Front')),
            ],
          ),
        );
      },
    );
  }
}

Widget _powerRow(emotiva.Device device) {
  return Row(
    mainAxisSize: MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Zone 2',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      Row(
        children: [
          IconButton(
            onPressed: () => addHaptic(device.updateAll),
            icon: const Icon(
              Icons.refresh,
              size: 30,
              semanticLabel: 'Refresh data',
            ),
          ),
          IconButton(
            onPressed: () => addHaptic(device.zone2TogglePower),
            icon: Icon(
              Icons.power_settings_new,
              color: device.zone2Power ? Colors.blue : Colors.amber,
              size: 30,
              semanticLabel: 'Toggle zone 2 power',
            ),
          ),
        ],
      )
    ],
  );
}

Widget _volumeRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Volume',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      Text('${device.zone2Volume.toString()}dB',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _inputRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Input',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      Text(device.zone2Input,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _inputSelection(BuildContext context, emotiva.Device device) {
  const double tableCellPadding = 8.0;
  return Table(
    children: [
      TableRow(children: [
        Padding(
          padding: const EdgeInsets.all(tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => opticalSelector(context, device, zone2: true),
            icon: const Icon(Icons.lightbulb),
            label: const Text('Optical'),
            style: const ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => coaxSelector(context, device, zone2: true),
            icon: const Icon(Icons.settings_input_composite),
            label: const Text('Coax'),
            style: const ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
      ]),
      TableRow(children: [
        Padding(
          padding: const EdgeInsets.all(tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => analogSelector(context, device, zone2: true),
            icon: const Icon(Icons.settings_input_component),
            label: const Text('Analog'),
            style: const ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => xlrSelector(context, device, zone2: true),
            icon: const Icon(Icons.donut_large),
            label: const Text('XLR'),
            style: const ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
      ]),
      TableRow(children: [
        Padding(
          padding: const EdgeInsets.all(tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => _otherInputsSelector(context, device),
            icon: const Icon(Icons.more),
            label: const Text('Other'),
            style: const ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => setFollowMain(device),
            icon: const Icon(Icons.sync_alt),
            label: const Text('Follow Main'),
            style: const ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
      ]),
    ],
  );
}

class Zone2Page extends StatelessWidget {
  const Zone2Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
        builder: (BuildContext context, DeviceChanges deviceChanges, _) {
      return _build(context, deviceChanges.device);
    });
  }

  Widget _build(BuildContext context, emotiva.Device device) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (device.menuDisplayed) menuWarning(context),
              _powerRow(device),
              const SizedBox(height: 10),
              _volumeRow(device),
              const SizedBox(height: 10),
              _inputRow(device),
              const SizedBox(height: 20),
              _inputSelection(context, device),
            ],
          ),
        ],
      ),
    );
  }
}
