import 'package:flutter/material.dart';

import 'package:emotiva_remote/widgets/informatives.dart';

const List<InfoSection> _sections = [
  InfoSection('Same network',
      "This device must be connected to the same network as the Emotiva processor."),
  InfoSection('No VPN',
      "Make sure you don't have a VPN activated on this device while using this app."),
  InfoSection('Emotiva standby mode',
      "Try turning on the Emotiva processor before trying to connect to it with this app. If doing so gets things working, then you likely need to configure the Emotiva processor to have \"Video on Standby\" enabled so the app can connect to it when the Emotiva processor is in standby mode."),
  InfoSection('Dirac calibration off',
      "Make sure the Emotiva processor is not in Dirac calibration mode. To do this, unchceck the \"Dirac Live\" -> \"Enable\" check box in the active speaker preset. When the processor is in Dirac calibration mode, its normal network functions are disabled."),
  InfoSection('Network settings',
      "Check the network settings on the Emotiva Processor to make sure it has an IP address."),
  InfoSection('WiFi settings',
      "Check your WiFi router settings to ensure client isolation is disabled. This setting might be called something different on your WiFi router, but any setting that prevents the WiFi clients from talking to each other will break this app."),
];

class ConnectionHelp extends StatelessWidget {
  const ConnectionHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return const InformationPage(
        title: 'Troubleshooting tips', sections: _sections);
  }
}
