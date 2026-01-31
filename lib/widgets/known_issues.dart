import 'package:flutter/material.dart';

import 'package:emotiva_remote/widgets/informatives.dart';

const List<InfoSection> _sections = [
  InfoSection('Slow updates',
      'Some setting changes on Emotiva processors take around 10 seconds before they\'re communicated to the app. E.g. changing inputs.'),
  InfoSection('Speaker trim',
      'Speaker trim levels are not updated in the app if the level is changed using another remote. E.g. another app or the IR remote.'),
  InfoSection('HDMI info',
      'HDMI color space, chroma subsampling, and HDR state are missing.'),
  InfoSection('Zone 2 and the Tuner',
      'Zone 2 cannot explicitly set its input to Tuner. It can use Tuner as its input only if Tuner is selected for Main and Zone 2 has its input set to Following Main.'),
  InfoSection('Speaker preset names',
      'Custom speaker preset names are not displayed. The generic name (e.g. Preset 1 or Preset 2) is shown instead.'),
];

class KnownIssues extends StatelessWidget {
  const KnownIssues({super.key});

  @override
  Widget build(BuildContext context) {
    return const InformationPage(title: 'Known issues', sections: _sections);
  }
}
