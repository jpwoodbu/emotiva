import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

import 'info_page.dart';
import 'remote_page.dart';
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
  void dispose() async {
    super.dispose();
    await widget.device.unsubscribeAll();
    await widget.device.closeSockets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Emotiva Remote')),
      ),
      // Using IndexedStack is critical. It preserves the existance (I think) of
      // the widgets as the user navigates between them so that we don't try to
      // do something breaking like creating additional listeners for a stream
      // inside initState perhaps before the prior listeners have been GC'd.
      body: IndexedStack(
        index: currentPageIndex,
        children: [
          InfoPage(widget.device),
          Remote(widget.device),
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
    // TODO - Consider, instead of pushing to the navigation below onPressed,
    // pushing to the "no devices found" widget and then popping onPressed for
    // trying again. I think that depends on the discovery process actually
    // getting retried on popping to the previous widget, but I think
    // initState will get run again on pop. That might involve not using
    // FutureBuilder, which be an overall simplicifaction.
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No Emotiva devices were found.'),
            SizedBox(height: 25.0),
            ElevatedButton(
              // TODO - consider calling an async function instead as using the
              // Navigator makes the page flash with a short animation on loading
              // a "new" page.
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Discovery()));
              },
              child: Text('Try again'),
              // TODO - consider adding a button to demo the app that passes
              // FakeDevice MainView.
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
            Text('Scanning for Emotiva devices...'),
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
