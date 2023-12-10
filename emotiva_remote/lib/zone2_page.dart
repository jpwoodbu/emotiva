import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'emotiva.dart' as emotiva;
import 'device_changes.dart';
import 'util.dart';

const double _sheetPadding = 15.0;

// This is a workaround for not getting notify messages when changing inputs for
// zone 2.
void _delayedUpdateAll(emotiva.Device device) {
  Future.delayed(Duration(seconds: 2), device.updateAll);
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
                icon: Icon(Icons.lightbulb),
                label: Text('Optical 1')),
            ElevatedButton.icon(
                onPressed: () => _setOptical(context, device, 2),
                icon: Icon(Icons.lightbulb),
                label: Text('Optical 2')),
            ElevatedButton.icon(
                onPressed: () => _setOptical(context, device, 3),
                icon: Icon(Icons.lightbulb),
                label: Text('Optical 3')),
            ElevatedButton.icon(
                onPressed: () => _setOptical(context, device, 4),
                icon: Icon(Icons.lightbulb),
                label: Text('Optical 4')),
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
                icon: Icon(Icons.settings_input_composite),
                label: Text('Coax 1')),
            ElevatedButton.icon(
                onPressed: () => _setCoax(context, device, 2),
                icon: Icon(Icons.settings_input_composite),
                label: Text('Coax 2')),
            ElevatedButton.icon(
                onPressed: () => _setCoax(context, device, 3),
                icon: Icon(Icons.settings_input_composite),
                label: Text('Coax 3')),
            ElevatedButton.icon(
                onPressed: () => _setCoax(context, device, 4),
                icon: Icon(Icons.settings_input_composite),
                label: Text('Coax 4')),
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
                icon: Icon(Icons.settings_input_component),
                label: Text('Analog 1')),
            ElevatedButton.icon(
                onPressed: () => _setAnalog(context, device, 2),
                icon: Icon(Icons.settings_input_component),
                label: Text('Analog 2')),
            ElevatedButton.icon(
                onPressed: () => _setAnalog(context, device, 3),
                icon: Icon(Icons.settings_input_component),
                label: Text('Analog 3')),
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
                icon: Icon(Icons.developer_board),
                label: Text('AES/EBU')),
            ElevatedButton.icon(
                onPressed: () => _setBalancedInput(context, device),
                icon: Icon(Icons.album),
                label: Text('Balanced Input')),
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
                icon: Icon(Icons.usb),
                label: Text('USB')),
            ElevatedButton.icon(
                onPressed: () => _setFront(context, device),
                icon: Icon(Icons.smartphone),
                label: Text('Front')),
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
      Text(
        'Zone 2',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      Row(
        children: [
          IconButton(
            onPressed: () => addHaptic(device.updateAll),
            icon: Icon(
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
      Text(
        'Volume',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      Text('${device.zone2Volume.toString()}dB',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _inputRow(emotiva.Device device) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        'Input',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      Text(device.zone2Input,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
            icon: Icon(Icons.lightbulb),
            label: Text('Optical'),
            style: ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => _coaxBottomSheet(context, device),
            icon: Icon(Icons.settings_input_composite),
            label: Text('Coax'),
            style: ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
      ]),
      TableRow(children: [
        Padding(
          padding: const EdgeInsets.all(tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => _analogBottomSheet(context, device),
            icon: Icon(Icons.settings_input_component),
            label: Text('Analog'),
            style: ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => _xlrBottomSheet(context, device),
            icon: Icon(Icons.donut_large),
            label: Text('XLR'),
            style: ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
      ]),
      TableRow(children: [
        Padding(
          padding: const EdgeInsets.all(tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => _otherBottomSheet(context, device),
            icon: Icon(Icons.more),
            label: Text('Other'),
            style: ButtonStyle(alignment: Alignment.centerLeft),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(tableCellPadding),
          child: ElevatedButton.icon(
            onPressed: () => _setFollowMain(device),
            icon: Icon(Icons.sync_alt),
            label: Text('Follow Main'),
            style: ButtonStyle(alignment: Alignment.centerLeft),
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
              SizedBox(height: 10),
              _volumeRow(device),
              SizedBox(height: 10),
              _inputRow(device),
              SizedBox(height: 20),
              _inputSelection(context, device),
            ],
          ),
        ],
      ),
    );
  }
}
