import 'package:flutter/material.dart';

import 'package:emotiva_remote/util.dart';

class InfoSection {
  final String title;
  final String body;

  const InfoSection(this.title, this.body);
}

class InformationPage extends StatelessWidget {
  final String title;
  final List<InfoSection> sections;

  const InformationPage(
      {super.key, required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        // Since we're using a scrollable widget, it's OK for the content to be
        // visible in the "unsafe" area at the bottom edge of the screen. And I
        // like the to-the-edge look.
        // TODO(jpwoodbu) This is not working as I would expect. The content
        // does not scroll to the bottom edge of the screen. Investigate.
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(padding),
          child: ListView.separated(
            itemBuilder: (context, index) =>
                _Item(title: sections[index].title, body: sections[index].body),
            separatorBuilder: (context, index) => const Divider(),
            itemCount: sections.length,
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
