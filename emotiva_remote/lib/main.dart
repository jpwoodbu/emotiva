import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

import 'device_model.dart';
import 'info_page.dart';
import 'inputs_page.dart';
import 'menu_page.dart';

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
        brightness: Brightness.dark,
      ),
      home: const Discovery(),
      initialRoute: '/discovery',
      routes: <String, WidgetBuilder>{
        '/discovery': (BuildContext context) => const Discovery(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainView extends StatefulWidget {
  final emotiva.Device device;
  MainView(this.device, {super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int currentPageIndex = 0;
  late DeviceChanges deviceChanges;
  _MainViewState();

  @override
  void initState() {
    super.initState();
    deviceChanges = DeviceChanges(widget.device);
    deviceChanges.handleControlPackets();
    deviceChanges.handleNotifyPackets();
    subscribeAll();
  }

  @override
  void dispose() async {
    super.dispose();
    await widget.device.unsubscribeAll();
    await widget.device.closeSockets();
  }

  void subscribeAll() async {
    await widget.device.subscribeAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Emotiva Remote')),
        leading: IconButton(icon: Icon(Icons.help), onPressed: () {}),
        actions: [
          PopupMenuButton(
              itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                        child: Text('Search for Emotiva devices'),
                        onTap: () {
                          Navigator.pushNamedAndRemoveUntil(context,
                              '/discovery', (Route<dynamic> route) => false);
                        }),
                    PopupMenuItem(child: Text('Known issues')),
                    PopupMenuItem(child: Text('Donate')),
                  ]),
        ],
      ),
      // Using IndexedStack is critical. It preserves the existance (I think) of
      // the widgets as the user navigates between them so that we don't try to
      // do something breaking like creating additional listeners for a stream
      // inside initState perhaps before the prior listeners have been GC'd.
      body: IndexedStack(
        index: currentPageIndex,
        children: [
          InfoPage(widget.device, deviceChanges),
          InputsPage(widget.device, deviceChanges),
          MenuPage(widget.device),
        ],
      ),
      persistentFooterButtons: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Volume', style: TextStyle(fontSize: 20.0)),
            Row(
              children: [
                ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.device.volumeDelta(-1.0);
                    },
                    child: Icon(Icons.remove, size: 30.0)),
                SizedBox(width: 15.0),
                ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.device.volumeDelta(1.0);
                    },
                    child: Icon(Icons.add, size: 30.0)),
              ],
            ),
          ],
        )
      ],
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.info),
            label: 'Info',
          ),
          NavigationDestination(
            // icon: Icon(Icons.settings_remote),
            icon: Icon(Icons.route),
            label: 'Inputs',
          ),
          NavigationDestination(
            icon: Icon(Icons.gamepad),
            label: 'Menu',
          ),
        ],
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
      ),
    );
  }
}

class NoDevicesFoundPage extends StatelessWidget {
  const NoDevicesFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No Emotiva devices were found.'),
            SizedBox(height: 25.0),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/discovery', (Route<dynamic> route) => false);
              },
              child: Text('Try again'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MainView(emotiva.FakeDevice())));
              },
              child: Text('Demo mode'),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanningPage extends StatelessWidget {
  const ScanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Searching for Emotiva devices...'),
            SizedBox(height: 25.0),
            CircularProgressIndicator(),
          ],
        ),
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
      return NoDevicesFoundPage();
    } else {
      return ScanningPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<emotiva.Device>(
      // Use the fake instead if an Emotiva device is not available.
      // future: emotiva.futureFakeDevice(),
      future: emotiva.discovery(3),
      builder: _futureBuilder,
    );
  }
}
