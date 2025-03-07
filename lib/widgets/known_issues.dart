import 'package:flutter/material.dart';

import '../util.dart';

class KnownIssues extends StatelessWidget {
  const KnownIssues({super.key});

  final String _issue1 =
      'Some setting changes on Emotiva processors take around 10 seconds before they\'re communicated to the app. E.g. changing inputs.';
  final String _issue2 =
      'Speaker trim levels are not updated in the app if the level is changed using another remote. E.g. another app or the IR remote.';
  final String _issue3 =
      'HDMI color space, chroma subsamping, and HDR state are missing.';
  final String _issue4 =
      'Zone 2 cannot explicitly set its input to Tuner. It can use Tuner as its input only if Tuner is selected for Main and Zone 2 has its input set to Following Main.';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Known issues')),
        body: Padding(
          padding: const EdgeInsets.all(kPadding),
          child: ListView.separated(
            itemBuilder: (_, index) {
              switch (index) {
                case 0:
                  return KnownIssueItem(
                      title: 'Slow updates', issueText: _issue1);
                case 1:
                  return KnownIssueItem(
                      title: 'Speaker trim', issueText: _issue2);
                case 2:
                  return KnownIssueItem(title: 'HDMI info', issueText: _issue3);
                case 3:
                  return KnownIssueItem(
                      title: 'Zone 2 and the Tuner', issueText: _issue4);
                default:
                  return const SizedBox();
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

class KnownIssueItem extends StatelessWidget {
  const KnownIssueItem(
      {super.key, required this.title, required this.issueText});

  final String title;
  final String issueText;

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
        Text(issueText),
      ],
    );
  }
}
