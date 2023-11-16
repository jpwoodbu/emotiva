import 'package:emotiva_remote/emotiva.dart' as emotiva;
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
        body: const Info(),
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

class Info extends StatefulWidget {
  const Info({super.key});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {

  emotiva.Device device = emotiva.Device();

  void discovery() async {
    try {
      device = await emotiva.discovery(1);
      await device.updateAll();
    } catch (e) {
      print('Error: $e');
    }
    setState(() {});
  }

  void updateAll() async {
    await device.updateAll();
    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(onPressed: discovery, child: Text('Discover')),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(onPressed: updateAll, child: Text('Update')),
          ),
          Text('Name: ${device.name}'),
          Text('Power: ${device.power}'),
          Text('Volume: ${device.volume}'),
          Text('Source: ${device.source}'),
          Text('Mode: ${device.mode}'),
          Text('Loudness: ${device.loudness}'),
          Text('Audio input: ${device.audioInput}'),
          Text('Audio bitstream: ${device.audioBitstream}'),
          Text('Audio bits: ${device.audioBits}'),
          Text('Video input: ${device.videoInput}'),
          Text('Video format: ${device.videoFormat}'),
          Text('Video space: ${device.videoSpace}'),
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