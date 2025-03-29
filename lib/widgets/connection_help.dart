import 'package:flutter/material.dart';

import 'package:emotiva_remote/util.dart';

class _Help {
  final String title;
  final String body;

  const _Help(this.title, this.body);
}

class ConnectionHelp extends StatelessWidget {
  const ConnectionHelp({super.key});

  static const List<_Help> _help = [
    _Help('Same network',
        "This device must be connected to the same network as the Emotiva processor."),
    _Help('No VPN',
        "Make sure you don't have a VPN activated on this device while using this app."),
    _Help('Emotiva standby mode',
        "Try turning on the Emotiva processor before trying to connect to it with this app. If doing so gets things working, then you likely need to configure the Emotiva processor to have \"Video on Standby\" enabled so the app can connect to it when the Emotiva processor is in standby mode."),
    _Help('Dirac calibration off',
        "Make sure the Emotiva processor is not in Dirac calibration mode. To do this, unchceck the \"Dirac Live\" -> \"Enable\" check box in the active speaker preset. When the processor is in Dirac calibration mode, its normal network functions are disabled."),
    _Help('Network settings',
        "Check the network settings on the Emotiva Processor to make sure it has an IP address."),
    _Help('WiFi settings',
        "Check your WiFi router settings to ensure client isolation is disabled. This setting might be called something different on your WiFi router, but any setting that prevents the WiFi clients from talking to each other will break this app."),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Troubleshooting tips'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(kPadding),
          child: ListView.separated(
            itemBuilder: (context, index) =>
                _Item(title: _help[index].title, body: _help[index].body),
            separatorBuilder: (context, index) => const Divider(),
            itemCount: _help.length,
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String title;
  final String body;

  const _Item({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Text(body),
      ],
    );
  }
}
