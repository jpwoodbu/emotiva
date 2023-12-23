import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'emotiva.dart' as emotiva;
import 'device_changes.dart';
import 'util.dart';

const double _sheetPadding = 15.0;

// This is a workaround for not getting notify messages when changing inputs for
// zone 2.
void _delayedUpdateAll(emotiva.Device device) {
  Future.delayed(const Duration(seconds: 2), device.updateAll);
}

void _setFollowMain(emotiva.Device device) {
  addHaptic(device.zone2FollowMain);
  _delayedUpdateAll(device);
}

void _setCoax(BuildContext context, emotiva.Device device, int input) {
  addHaptic(() => device.zone2SetCoax(input));
  Navigator.pop(context);
  _delayedUpdateAll(device);
}

void _setAesEbu(BuildContext context, emotiva.Device device) {
  addHaptic(device.zone2SetAesEbu);
  Navigator.pop(context);
  _delayedUpdateAll(device);
}

void _setOptical(BuildContext context, emotiva.Device device, int input) {
  addHaptic(() => device.zone2SetOptical(input));
  Navigator.pop(context);
  _delayedUpdateAll(device);
}

void _setAnalog(BuildContext context, emotiva.Device device, int input) {
  addHaptic(() => device.zone2SetAnalog(input));
  Navigator.pop(context);
  _delayedUpdateAll(device);
}

void _setBalancedInput(BuildContext context, emotiva.Device device) {
  addHaptic(device.zone2SetBalancedInput);
  Navigator.pop(context);
  _delayedUpdateAll(device);
}

void _setUsb(BuildContext context, emotiva.Device device) {
  addHaptic(device.zone2SetUsb);
  Navigator.pop(context);
  _delayedUpdateAll(device);
}

void _setFront(BuildContext context, emotiva.Device device) {
  addHaptic(device.zone2SetFront);
  Navigator.pop(context);
  _delayedUpdateAll(device);
}

void _opticalBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(_sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton.icon(
                onPressed: () => _setOptical(context, device, 1),
                icon: const Icon(Icons.lightbulb),
                label: const Text('Optical 1')),
            ElevatedButton.icon(
                onPressed: () => _setOptical(context, device, 2),
                icon: const Icon(Icons.lightbulb),
                label: const Text('Optical 2')),
            ElevatedButton.icon(
                onPressed: () => _setOptical(context, device, 3),
                icon: const Icon(Icons.lightbulb),
                label: const Text('Optical 3')),
            ElevatedButton.icon(
                onPressed: () => _setOptical(context, device, 4),
                icon: const Icon(Icons.lightbulb),
                label: const Text('Optical 4')),
          ],
        ),
      );
    },
  );
}

void _coaxBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(_sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton.icon(
                onPressed: () => _setCoax(context, device, 1),
                icon: const Icon(Icons.settings_input_composite),
                label: const Text('Coax 1')),
            ElevatedButton.icon(
                onPressed: () => _setCoax(context, device, 2),
                icon: const Icon(Icons.settings_input_composite),
                label: const Text('Coax 2')),
            ElevatedButton.icon(
                onPressed: () => _setCoax(context, device, 3),
                icon: const Icon(Icons.settings_input_composite),
                label: const Text('Coax 3')),
            ElevatedButton.icon(
                onPressed: () => _setCoax(context, device, 4),
                icon: const Icon(Icons.settings_input_composite),
                label: const Text('Coax 4')),
          ],
        ),
      );
    },
  );
}

void _analogBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(_sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton.icon(
                onPressed: () => _setAnalog(context, device, 1),
                icon: const Icon(Icons.settings_input_component),
                label: const Text('Analog 1')),
            ElevatedButton.icon(
                onPressed: () => _setAnalog(context, device, 2),
                icon: const Icon(Icons.settings_input_component),
                label: const Text('Analog 2')),
            ElevatedButton.icon(
                onPressed: () => _setAnalog(context, device, 3),
                icon: const Icon(Icons.settings_input_component),
                label: const Text('Analog 3')),
          ],
        ),
      );
    },
  );
}

void _xlrBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(_sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton.icon(
                onPressed: () => _setAesEbu(context, device),
                icon: const Icon(Icons.developer_board),
                label: const Text('AES/EBU')),
            ElevatedButton.icon(
                onPressed: () => _setBalancedInput(context, device),
                icon: const Icon(Icons.album),
                label: const Text('Balanced Input')),
          ],
        ),
      );
    },
  );
}

void _otherBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(_sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ElevatedButton.icon(
                onPressed: () => _setUsb(context, device),
                icon: const Icon(Icons.usb),
                label: const Text('USB')),
            ElevatedButton.icon(
                onPressed: () => _setFront(context, device),
                icon: const Icon(Icons.smartphone),
                label: const Text('Front')),
          ],
        ),
      );
    },
  );
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
            onPressed: () => _opticalBottomSheet(context, device),
            icon: const Icon(Icons.lightbulb),
            label: const Text('Optical'),
            style: const ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => _coaxBottomSheet(context, device),
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
            onPressed: () => _analogBottomSheet(context, device),
            icon: const Icon(Icons.settings_input_component),
            label: const Text('Analog'),
            style: const ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => _xlrBottomSheet(context, device),
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
            onPressed: () => _otherBottomSheet(context, device),
            icon: const Icon(Icons.more),
            label: const Text('Other'),
            style: const ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => _setFollowMain(device),
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
        builder: (BuildContext context, DeviceChanges deviceChanges, child) {
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
