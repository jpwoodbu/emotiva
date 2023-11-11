import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emotiva Remote',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('Emotiva Remote')),
        ),
        body: const Remote(),
        bottomNavigationBar: const MyBottomNavigation(),
      ),
    );
  }
}

class MyBottomNavigation extends StatelessWidget {
  const MyBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.info),
          label: 'Info',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_remote),
          label: 'Remote',
        ),
      ],
    );
  }
}

class Info extends StatelessWidget {
  const Info({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: ListView(
        children: const [
          Text('Name: RMC-1'),
          Text('Power: Off'),
          Text('Volume: -31db'),
          Text('Source: HDMI 1'),
          Text('Mode: Dolby Surround'),
          Text('Loudness: Off'),
          Text('Audio input: HDMI 1'),
          Text('Audio bitstream: PCM 2.0'),
          Text('Audio bits: 48kHz 20bits'),
          Text('Video input: HDMI 1'),
          Text('Video format: 2160P/60'),
          Text('Video space: 10 bits'),
        ],
      ),
    );
  }
}

class Remote extends StatelessWidget {
  const Remote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          ElevatedButton(onPressed: (){}, child: Text('Power'))
        ],
      ),
    );
  }
}