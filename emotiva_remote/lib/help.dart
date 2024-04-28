import 'package:flutter/material.dart';

class Help extends StatelessWidget {
  const Help({super.key});

  final String _helpHeader1 = 'Turning on your processor';
  final String _help1 =
      'Click the power icon in the top right to turn On/Off your processor. Enable "Video on Standby" on your Emotiva processor so that it can be turned on using this app when in standby.';
  final String _helpHeader2 = 'Refreshing data';
  final String _help2 =
      'When changes happen on the Emotiva processor, data in the app should update automatically. But if you think the app is out-of-sync with the processor, click the refresh icon next to the power icon to refresh all data. Or swipe down on the info page to refresh.';
  final String _helpHeader3 = 'Touch feedback';
  final String _help3 =
      'Turn on "Touch feedback" in your phone/tablet system settings (under Vibration & haptics). Everytime the app sends a network packet to the Emotiva processor, it makes a slight vibration.';
  final String _helpHeader4 = 'Data updates';
  final String _help4 =
      'Data in the app are ONLY changed when updates are receieved from the Emotiva processor. If you see lag between clicking a button and seeing a field being updated, it\'s likely because it takes the Emotiva processor a moment to process the change and send the update.';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Help'),
        ),
        body: Padding(
          // TODO - centralize this padding value. It was pulled from the info
          // page.
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: ListView.separated(
            itemBuilder: (_, index) {
              switch (index) {
                case 0:
                  return HelpItem(title: _helpHeader1, helpText: _help1);
                case 1:
                  return HelpItem(title: _helpHeader2, helpText: _help2);
                case 2:
                  return HelpItem(title: _helpHeader3, helpText: _help3);
                case 3:
                  return HelpItem(title: _helpHeader4, helpText: _help4);
              }
            },
            separatorBuilder: (_, __) => const Divider(),
            itemCount: 4,
          ),
        ),
      ),
    );
  }
}

class HelpItem extends StatelessWidget {
  const HelpItem({super.key, required this.title, required this.helpText});

  final String title;
  final String helpText;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.titleLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(title, style: headerStyle),
        ),
        Text(helpText),
      ],
    );
  }
}
