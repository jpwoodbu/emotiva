import 'package:flutter/material.dart';

import 'package:emotiva_remote/widgets/informatives.dart';

const List<InfoSection> _sections = [
  InfoSection('Turning on your processor',
      'Click the power icon in the top right to turn On/Off your processor. Enable "Video on Standby" on your Emotiva processor so that it can be turned on using this app when in standby.'),
  InfoSection('Refreshing data',
      'When changes happen on the Emotiva processor, data in the app should update automatically. But if you think the app is out-of-sync with the processor, click the refresh icon next to the power icon to refresh all data. Or swipe down on the info page to refresh.'),
  InfoSection('Touch feedback',
      'Turn on "Touch feedback" in your phone/tablet system settings (under Vibration & haptics). Everytime the app sends a network packet to the Emotiva processor, it makes a slight vibration.'),
  InfoSection('Data updates',
      'Data in the app are ONLY changed when updates are receieved from the Emotiva processor. If you see lag between clicking a button and seeing a field being updated, it\'s likely because it takes the Emotiva processor a moment to process the change and send the update.'),
];

class Help extends StatelessWidget {
  const Help({super.key});

  @override
  Widget build(BuildContext context) {
    return const InformationPage(title: 'Help', sections: _sections);
  }
}
