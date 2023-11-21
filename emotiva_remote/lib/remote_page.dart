import 'package:flutter/material.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

class Remote extends StatelessWidget {
  final emotiva.Device device;
  const Remote(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(15.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            DropdownMenu<int>(
              initialSelection: 1,
              label: const Text('HDMI'),
              dropdownMenuEntries: [
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
            DropdownMenu<int>(
              initialSelection: 1,
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
                DropdownMenuEntry(value: 16, label: 'Analog 5'),
                DropdownMenuEntry(value: 17, label: 'Analog 7.1'),
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
