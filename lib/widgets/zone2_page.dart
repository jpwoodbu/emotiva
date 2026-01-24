import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;
import 'package:emotiva_remote/device_changes.dart';
import 'package:emotiva_remote/util.dart';
import 'package:emotiva_remote/widgets/inputs_page.dart';
import 'package:emotiva_remote/widgets/volume_row.dart';

enum Zone2OtherSelection { usb, front }

/// Displays an adaptive modal to select an input which doesn't fit into another
/// category. Note that this list of inputs is different from the "other" inputs
/// list for the main zone.
void _otherInputsSelector(BuildContext context, emotiva.Device device) async {
  Zone2OtherSelection? selection;
  if (isApple(context)) {
    selection = await showCupertinoModalPopup<Zone2OtherSelection>(
      context: context,
      builder: (BuildContext context) => const CupertinoActionSheet(
        actions: <CupertinoSelectionButton<Zone2OtherSelection>>[
          CupertinoSelectionButton(label: 'USB', selection: .usb),
          CupertinoSelectionButton(label: 'Front', selection: .front),
        ],
      ),
    );
  } else {
    selection = await showCustomBottomSheet<Zone2OtherSelection>(
      context: context,
      children: const <SelectionButton<Zone2OtherSelection>>[
        SelectionButton(label: 'USB', icon: Icons.usb, selection: .usb),
        SelectionButton(
          label: 'Front',
          icon: Icons.smartphone,
          selection: .front,
        ),
      ],
    );
  }
  switch (selection) {
    case .front:
      addHaptic(() => device.zone2SetFront());
      delayedUpdateAll(device);
    case .usb:
      addHaptic(() => device.zone2SetUsb());
      delayedUpdateAll(device);
    case null: // do nothing
  }
}

class _PowerRow extends StatelessWidget {
  const _PowerRow();

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
    return Row(
      mainAxisSize: .max,
      mainAxisAlignment: .spaceBetween,
      children: [
        const Text('Zone 2', style: TextStyle(fontSize: 25, fontWeight: .bold)),
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
        ),
      ],
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow();

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        const Text('Input', style: TextStyle(fontSize: 15, fontWeight: .bold)),
        Text(
          device.zone2Input,
          style: const TextStyle(fontSize: 15, fontWeight: .bold),
        ),
      ],
    );
  }
}

class _InputSelection extends StatelessWidget {
  const _InputSelection();

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
    const double tableCellPadding = 8.0;
    return Table(
      children: [
        TableRow(
          children: [
            Padding(
              padding: const .all(tableCellPadding),
              child: ElevatedButton.icon(
                onPressed: () => opticalSelector(context, device, zone2: true),
                icon: const Icon(Icons.lightbulb),
                label: const Text('Optical'),
                style: const ButtonStyle(alignment: .centerLeft),
              ),
            ),
            Padding(
              padding: const .all(tableCellPadding),
              child: ElevatedButton.icon(
                onPressed: () => coaxSelector(context, device, zone2: true),
                icon: const Icon(Icons.settings_input_composite),
                label: const Text('Coax'),
                style: const ButtonStyle(alignment: .centerLeft),
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const .all(tableCellPadding),
              child: ElevatedButton.icon(
                onPressed: () => analogSelector(context, device, zone2: true),
                icon: const Icon(Icons.settings_input_component),
                label: const Text('Analog'),
                style: const ButtonStyle(alignment: .centerLeft),
              ),
            ),
            Padding(
              padding: const .all(tableCellPadding),
              child: ElevatedButton.icon(
                onPressed: () => xlrSelector(context, device, zone2: true),
                icon: const Icon(Icons.donut_large),
                label: const Text('XLR'),
                style: const ButtonStyle(alignment: .centerLeft),
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const .all(tableCellPadding),
              child: ElevatedButton.icon(
                onPressed: () => _otherInputsSelector(context, device),
                icon: const Icon(Icons.more),
                label: const Text('Other'),
                style: const ButtonStyle(alignment: .centerLeft),
              ),
            ),
            Padding(
              padding: const .all(tableCellPadding),
              child: ElevatedButton.icon(
                onPressed: () {
                  addHaptic(device.zone2FollowMain);
                  delayedUpdateAll(device);
                },
                icon: const Icon(Icons.sync_alt),
                label: const Text('Follow Main'),
                style: const ButtonStyle(alignment: .centerLeft),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class Zone2Page extends StatelessWidget {
  const Zone2Page({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
    return Padding(
      padding: const .all(padding),
      child: ListView(
        children: [
          if (device.menuDisplayed) menuWarning(context),
          const _PowerRow(),
          const SizedBox(height: 10),
          const VolumeRow(zone2: true),
          const SizedBox(height: 10),
          const _InputRow(),
          const SizedBox(height: 20),
          const _InputSelection(),
        ],
      ),
    );
  }
}
