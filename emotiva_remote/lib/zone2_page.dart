import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

import 'device_changes.dart';

const double sheetPadding = 15.0;

Future<void> futureUpdateAll(emotiva.Device device) async {
  HapticFeedback.lightImpact();
  await device.updateAll();
}

void updateAll(emotiva.Device device) async {
  await futureUpdateAll(device);
}


// This is a workaround for not getting notify messages when changing inputs for
// zone 2.
void delayedUpdateAll(emotiva.Device device) {
  Future.delayed(Duration(seconds: 2), () => updateAll(device));
}

togglePower(emotiva.Device device) async {
  HapticFeedback.lightImpact();
  device.zone2TogglePower();
}

void setFollowMain(emotiva.Device device) async {
  HapticFeedback.lightImpact();
  device.zone2FollowMain();
  delayedUpdateAll(device);
}

void setCoax(BuildContext context, emotiva.Device device, int input) async {
  HapticFeedback.lightImpact();
  device.zone2SetCoax(input);
  Navigator.pop(context);
  delayedUpdateAll(device);
}

void setAesEbu(BuildContext context, emotiva.Device device) async {
  HapticFeedback.lightImpact();
  device.zone2SetAesEbu();
  Navigator.pop(context);
  delayedUpdateAll(device);
}

void setOptical(BuildContext context, emotiva.Device device, int input) async {
  HapticFeedback.lightImpact();
  device.zone2SetOptical(input);
  Navigator.pop(context);
  delayedUpdateAll(device);
}

void setAnalog(BuildContext context, emotiva.Device device, int input) async {
  HapticFeedback.lightImpact();
  device.zone2SetAnalog(input);
  Navigator.pop(context);
  delayedUpdateAll(device);
}

void setBalancedInput(BuildContext context, emotiva.Device device) async {
  HapticFeedback.lightImpact();
  device.zone2SetBalancedInput();
  Navigator.pop(context);
  delayedUpdateAll(device);
}

void setUsb(BuildContext context, emotiva.Device device) async {
  HapticFeedback.lightImpact();
  device.zone2SetUsb();
  Navigator.pop(context);
  delayedUpdateAll(device);
}

void setFront(BuildContext context, emotiva.Device device) async {
  HapticFeedback.lightImpact();
  device.zone2SetFront();
  Navigator.pop(context);
  delayedUpdateAll(device);
}

void opticalBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton.icon(
                onPressed: () => setOptical(context, device, 1),
                icon: Icon(Icons.lightbulb),
                label: Text('Optical 1')),
            ElevatedButton.icon(
                onPressed: () => setOptical(context, device, 2),
                icon: Icon(Icons.lightbulb),
                label: Text('Optical 2')),
            ElevatedButton.icon(
                onPressed: () => setOptical(context, device, 3),
                icon: Icon(Icons.lightbulb),
                label: Text('Optical 3')),
            ElevatedButton.icon(
                onPressed: () => setOptical(context, device, 4),
                icon: Icon(Icons.lightbulb),
                label: Text('Optical 4')),
          ],
        ),
      );
    },
  );
}

void coaxBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton.icon(
                onPressed: () => setCoax(context, device, 1),
                icon: Icon(Icons.settings_input_composite),
                label: Text('Coax 1')),
            ElevatedButton.icon(
                onPressed: () => setCoax(context, device, 2),
                icon: Icon(Icons.settings_input_composite),
                label: Text('Coax 2')),
            ElevatedButton.icon(
                onPressed: () => setCoax(context, device, 3),
                icon: Icon(Icons.settings_input_composite),
                label: Text('Coax 3')),
            ElevatedButton.icon(
                onPressed: () => setCoax(context, device, 4),
                icon: Icon(Icons.settings_input_composite),
                label: Text('Coax 4')),
          ],
        ),
      );
    },
  );
}

void analogBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton.icon(
                onPressed: () => setAnalog(context, device, 1),
                icon: Icon(Icons.settings_input_component),
                label: Text('Analog 1')),
            ElevatedButton.icon(
                onPressed: () => setAnalog(context, device, 2),
                icon: Icon(Icons.settings_input_component),
                label: Text('Analog 2')),
            ElevatedButton.icon(
                onPressed: () => setAnalog(context, device, 3),
                icon: Icon(Icons.settings_input_component),
                label: Text('Analog 3')),
          ],
        ),
      );
    },
  );
}

void xlrBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton.icon(
                onPressed: () => setAesEbu(context, device),
                icon: Icon(Icons.developer_board),
                label: Text('AES/EBU')),
            ElevatedButton.icon(
                onPressed: () => setBalancedInput(context, device),
                icon: Icon(Icons.album),
                label: Text('Balanced Input')),
          ],
        ),
      );
    },
  );
}

void otherBottomSheet(BuildContext context, emotiva.Device device) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ElevatedButton.icon(
                onPressed: () => setUsb(context, device),
                icon: Icon(Icons.usb),
                label: Text('USB')),
            ElevatedButton.icon(
                onPressed: () => setFront(context, device),
                icon: Icon(Icons.smartphone),
                label: Text('Front')),
          ],
        ),
      );
    },
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
              onPressed: () {
                updateAll(device);
              },
              icon: Icon(
                Icons.refresh,
                size: 30,
                semanticLabel: 'Refresh data',
              ),
            ),
            IconButton(
              onPressed: () => togglePower(device),
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
              onPressed: () => opticalBottomSheet(context, device),
              icon: Icon(Icons.lightbulb),
              label: Text('Optical'),
              style: ButtonStyle(alignment: Alignment.centerLeft),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(tableCellPadding),
            child: ElevatedButton.icon(
              onPressed: () => coaxBottomSheet(context, device),
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
              onPressed: () => analogBottomSheet(context, device),
              icon: Icon(Icons.settings_input_component),
              label: Text('Analog'),
              style: ButtonStyle(alignment: Alignment.centerLeft),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(tableCellPadding),
            child: ElevatedButton.icon(
              onPressed: () => xlrBottomSheet(context, device),
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
              onPressed: () => otherBottomSheet(context, device),
              icon: Icon(Icons.more),
              label: Text('Other'),
              style: ButtonStyle(alignment: Alignment.centerLeft),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(tableCellPadding),
            child: ElevatedButton.icon(
              onPressed: () => setFollowMain(device),
              icon: Icon(Icons.sync_alt),
              label: Text('Follow Main'),
              style: ButtonStyle(alignment: Alignment.centerLeft),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _build(BuildContext context, emotiva.Device device) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
