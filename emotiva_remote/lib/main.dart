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
      home: const Discovery(),
    );
  }
}

class HomePage extends StatefulWidget {
  final emotiva.Device device;
  const HomePage(this.device, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 0;
  emotiva.Device device = emotiva.Device();

  _HomePageState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('Emotiva Remote')),
        ),
        body: <Widget>[Info(widget.device), Remote()][currentPageIndex],
        bottomNavigationBar: NavigationBar(
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.info),
              label: 'Info',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_remote),
              label: 'Remote',
            ),
          ],
          selectedIndex: currentPageIndex,
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
        ),
      ),
    );
  }
}

class Info extends StatefulWidget {
  final emotiva.Device device;
  Info(this.device, {super.key});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {

  void updateAll() async {
    await widget.device.updateAll();
    setState(() {});
  }

  @override
  void initState() {
    updateAll();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(onPressed: updateAll, child: Text('Update')),
          ),
          Text('Name: ${widget.device.name}'),
          Text('Power: ${widget.device.power}'),
          Text('Volume: ${widget.device.volume}'),
          Text('Source: ${widget.device.source}'),
          Text('Mode: ${widget.device.mode}'),
          Text('Loudness: ${widget.device.loudness}'),
          Text('Audio input: ${widget.device.audioInput}'),
          Text('Audio bitstream: ${widget.device.audioBitstream}'),
          Text('Audio bits: ${widget.device.audioBits}'),
          Text('Video input: ${widget.device.videoInput}'),
          Text('Video format: ${widget.device.videoFormat}'),
          Text('Video space: ${widget.device.videoSpace}'),
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
        children: [ElevatedButton(onPressed: () {}, child: Text('Power'))],
      ),
    );
  }
}

class Discovery extends StatefulWidget {
  const Discovery({super.key});

  @override
  State<Discovery> createState() => _DiscoveryState();
}

class _DiscoveryState extends State<Discovery> {
  Future<emotiva.Device> discovery() {
    try {
      return emotiva.discovery(3);
    } catch (e) {
      throw 'Error $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FutureBuilder<emotiva.Device>(
            future: discovery(),
            builder:
                (BuildContext context, AsyncSnapshot<emotiva.Device> snapshot) {
              if (snapshot.hasData) {
                return HomePage(snapshot.data!);
              } else if (snapshot.hasError) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('No Emotiva devices were found.'),
                    SizedBox(height: 25.0),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Discovery()),);
                        },
                        child: Text('Try again')),
                  ],
                );
              } else {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Scanning for Emotiva devices...'),
                    SizedBox(height: 25.0),
                    CircularProgressIndicator(),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
