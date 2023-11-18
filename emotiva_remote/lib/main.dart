import 'package:emotiva_remote/emotiva.dart' as emotiva;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class DeviceModel with ChangeNotifier {
  emotiva.Device device;
  late Stream<String> stream;

  DeviceModel(this.device) {
    stream = device.controlPortStream();
  }

  Future<void> listen() async {
    await for (final packet in stream) {
      device.parseControlPortPacket(packet);
      notifyListeners();
    }
  }
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

class MainView extends StatefulWidget {
  final emotiva.Device device;
  const MainView(this.device, {super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int currentPageIndex = 0;
  _MainViewState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('Emotiva Remote')),
        ),
        body: <Widget>[
          Info(widget.device),
          Remote(widget.device)
        ][currentPageIndex],
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
  late DeviceModel _deviceNotifier;

  void updateAll() async {
    await widget.device.updateAll();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _deviceNotifier = DeviceModel(widget.device);
    _deviceNotifier.listen();
    updateAll();
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
          ListenableBuilder(
            listenable: _deviceNotifier,
            builder: (BuildContext context, Widget? child) {
              return Column(
                children: [
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
              );
            },
          ),
        ],
      ),
    );
  }
}

class Remote extends StatelessWidget {
  final emotiva.Device device;
  const Remote(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              await device.control('power_on');
            },
            child: Text('Power'),
          )
        ],
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

  Widget _futureBuilder(
      BuildContext context, AsyncSnapshot<emotiva.Device> snapshot) {
    if (snapshot.hasData) {
      return MainView(snapshot.data!);
    } else if (snapshot.hasError) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('No Emotiva devices were found.'),
          SizedBox(height: 25.0),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => Discovery()));
            },
            child: Text('Try again'),
          ),
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
  }

  @override
  Widget build(BuildContext context) {
    // Since this widget uses the entire surface, we need to wrap it in
    // MaterialApp() to get the right colors.
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FutureBuilder<emotiva.Device>(
            future: emotiva.discovery(3),
            builder: _futureBuilder,
          ),
        ),
      ),
    );
  }
}
