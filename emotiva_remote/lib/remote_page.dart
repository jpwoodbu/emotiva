import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

class Remote extends StatelessWidget {
  final emotiva.Device device;
  const Remote(this.device, {super.key});

  void addHaptic(Function function) {
    HapticFeedback.lightImpact();
    function();
  }

  void setHdmi(int? input) async {
    if (input == null || input == 0) {
      return;
    }
    HapticFeedback.lightImpact();
    device.setHdmi(input);
  }
  
  void setAudioInput(int? selection) async {
    switch (selection) {
      case null:
        // We are required to handle a null value.
        return;
      case 0:
        // Nothing was selected.
        return;
      case 1:
        device.setCoax(1);
        HapticFeedback.lightImpact();
        break;
      case 2:
        device.setCoax(2);
        HapticFeedback.lightImpact();
        break;
      case 3:
        device.setCoax(3);
        HapticFeedback.lightImpact();
        break;
      case 4:
        device.setCoax(4);
        HapticFeedback.lightImpact();
        break;
      case 5:
        device.setOptical(1);
        HapticFeedback.lightImpact();
        break;
      case 6:
        device.setOptical(2);
        HapticFeedback.lightImpact();
        break;
      case 7:
        device.setOptical(3);
        HapticFeedback.lightImpact();
        break;
      case 8:
        device.setOptical(4);
        HapticFeedback.lightImpact();
        break;
      case 9:
        device.setArc();
        HapticFeedback.lightImpact();
        break;
      case 10:
        device.setUsb();
        HapticFeedback.lightImpact();
        break;
      case 11:
        device.setTuner();
        HapticFeedback.lightImpact();
        break;
      case 12:
        device.setAnalog(1);
        HapticFeedback.lightImpact();
        break;
      case 13:
        device.setAnalog(2);
        HapticFeedback.lightImpact();
        break;
      case 14:
        device.setAnalog(3);
        HapticFeedback.lightImpact();
        break;
      case 15:
        device.setAnalog(4);
        HapticFeedback.lightImpact();
        break;
      case 16:
        device.setFront();
        HapticFeedback.lightImpact();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(15.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            DropdownMenu<int>(
              enableSearch: false,
              initialSelection: 0,
              leadingIcon: Icon(Icons.settings_input_hdmi),
              label: const Text('HDMI'),
              onSelected: (int? input) => setHdmi(input),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 0, label: 'Select'),
                DropdownMenuEntry(value: 1, label: '1'),
                DropdownMenuEntry(value: 2, label: '2'),
                DropdownMenuEntry(value: 3, label: '3'),
                DropdownMenuEntry(value: 4, label: '4'),
                DropdownMenuEntry(value: 5, label: '5'),
                DropdownMenuEntry(value: 6, label: '6'),
                DropdownMenuEntry(value: 7, label: '7'),
                DropdownMenuEntry(value: 8, label: '8'),
              ],
            ),
            // TODO - refactor to use an enum once I understand them better.
            DropdownMenu<int>(
              enableSearch: false,
              initialSelection: 0,
              leadingIcon: Icon(Icons.settings_input_composite),
              label: const Text('Audio source'),
              onSelected: (int? selection) => setAudioInput(selection),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 0, label: 'Select'),
                DropdownMenuEntry(value: 1, label: 'Coax 1'),
                DropdownMenuEntry(value: 2, label: 'Coax 2'),
                DropdownMenuEntry(value: 3, label: 'Coax 3'),
                DropdownMenuEntry(value: 4, label: 'Coax 4'),
                DropdownMenuEntry(value: 5, label: 'Optical 1'),
                DropdownMenuEntry(value: 6, label: 'Optical 2'),
                DropdownMenuEntry(value: 7, label: 'Optical 3'),
                DropdownMenuEntry(value: 8, label: 'Optical 4'),
                DropdownMenuEntry(value: 9, label: 'ARC'),
                DropdownMenuEntry(value: 10, label: 'USB'),
                DropdownMenuEntry(value: 11, label: 'Tuner'),
                DropdownMenuEntry(value: 12, label: 'Analog 1'),
                DropdownMenuEntry(value: 13, label: 'Analog 2'),
                DropdownMenuEntry(value: 14, label: 'Analog 3'),
                DropdownMenuEntry(value: 15, label: 'Analog 4'),
                DropdownMenuEntry(value: 16, label: 'Front'),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15),
            Text('Mode'),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.circle),
              label: Text('Auto'),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.circle),
              label: Text('Stereo'),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.circle),
              label: Text('Direct'),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.circle),
              label: Text('Reference Stereo'),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.circle),
              label: Text('Music'),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.circle),
              label: Text('Movie'),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.circle),
              label: Text('Dolby'),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.circle),
              label: Text('DTS'),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.circle),
              label: Text('All Stereo'),
            ),
          ],
        ),
      ],
    );
  }
}
