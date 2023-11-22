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
    device.setHdmi(input);
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
              initialSelection: 1,
              leadingIcon: Icon(Icons.settings_input_composite),
              label: const Text('Audio source'),
              dropdownMenuEntries: [
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
                DropdownMenuEntry(value: 18, label: 'Front'),
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
