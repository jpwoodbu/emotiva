import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'emotiva.dart' as emotiva;
import 'device_changes.dart';
import 'info_page.dart';
import 'inputs_page.dart';
import 'menu_page.dart';

void _log(String message) {
  developer.log(message, name: 'main');
}

void showErrorSnackBar(BuildContext context, String error) {
  final snackBar = SnackBar(content: Text(error));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

const String helpText = '''
Tip 1: Click the power icon in the top right to turn On/Off your processor. Enable "Video on Standby" on your Emotiva processor so that it can be turned on using this app when in standby.

Tip 2: When changes happen on the Emotiva processor, data in the app should update automatically. But if you think the app is out-of-sync with the processor, click the refresh icon next to the power icon to refresh all data. Or swipe down on the info page to refresh.

Tip 3: Turn on "Touch feedback" in your system settings (under Vibration & haptics). Everytime the app sends a network packet to the Emotiva processor, it makes a slight vibration.

Tip 4: Data in the app are ONLY changed when updates are receieved from the Emotiva processor. If you see lag between clicking a button and seeing a field being updated, it's likely because it takes the Emotiva processor a moment to process the change and send the update.
''';

Future<void> showHelp(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      scrollable: true,
      content: Text(helpText.trim()),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Dismiss')),
      ],
    ),
  );
}

const String knownIssues = '''
1) Changing inputs does not properly update all the fields on the Info page. Workaround: Click the refresh icon after changing inputs.

2) Speaker trim fields are not updated if the speaker trim is changed using another remote (e.g. another app or the IR remote).

3) HDMI color space, chroma subsamping, and HDR state are missing.
''';

Future<void> showKnownIssus(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      scrollable: true,
      content: Text(knownIssues.trim()),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Dismiss')),
      ],
    ),
  );
}

const String roadMap = '''
1) Make the app customize itself based on the Emotiva processor configuration. E.g. use custom input labels, display trim only for speakers which are enabled.

2) Add tuner controls.

3) Test on hardware other than the RMC-1L.

4) Support choosing between multiple Emotiva processors on the same network. Does anyone have more than one?
''';

Future<void> showRoadMap(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      scrollable: true,
      content: Text(roadMap.trim()),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Dismiss')),
      ],
    ),
  );
}

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
      debugShowCheckedModeBanner: false,
    );
  }
}

List<Widget>? _footer(emotiva.Device device, int currentPageIndex) {
  if (currentPageIndex == 2) {
    return null;
  }
  return [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text('Volume',
              style: TextStyle(
                fontSize: 20.0,
              )),
        ),
        Row(
          children: [
            ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  device.volumeDelta(-1.0);
                },
                child: Icon(
                  Icons.remove,
                  size: 30.0,
                  semanticLabel: 'Volume down',
                )),
            SizedBox(width: 15.0),
            ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  device.volumeDelta(1.0);
                },
                child: Icon(
                  Icons.add,
                  size: 30.0,
                  semanticLabel: 'Volume up',
                )),
          ],
        ),
      ],
    )
  ];
}

class MainView extends StatefulWidget {
  MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
      builder: (context, deviceChanges, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Center(child: Text('Emotiva Remote')),
            leading: IconButton(
              icon: Icon(Icons.help),
              tooltip: 'Show help',
              onPressed: () => showHelp(context),
            ),
            actions: [
              PopupMenuButton(
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    child: Text('Rediscover Emotiva device'),
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Discovery(
                                    rediscover: true,
                                  )),
                          (Route<dynamic> route) => false);
                    },
                  ),
                  PopupMenuItem(
                    child: Text('Known issues'),
                    onTap: () => showKnownIssus(context),
                  ),
                  PopupMenuItem(
                    child: Text('Road map'),
                    onTap: () => showRoadMap(context),
                  ),
                ],
              ),
            ],
          ),
          // Using IndexedStack is critical. It preserves the existance (I think) of
          // the widgets as the user navigates between them so that we don't try to
          // do something breaking like creating additional listeners for a stream
          // inside initState perhaps before the prior listeners have been GC'd.
          body: IndexedStack(
            index: currentPageIndex,
            children: [
              InfoPage(),
              InputsPage(),
              MenuPage(),
            ],
          ),
          persistentFooterButtons:
              _footer(deviceChanges.device, currentPageIndex),
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
      },
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
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Discovery()),
                    (Route<dynamic> route) => false);
              },
              child: Text('Try again'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Discovery(useFake: true)),
                    (Route<dynamic> route) => false);
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
  final bool useFake;
  final bool rediscover;
  const Discovery({super.key, this.useFake = false, this.rediscover = false});

  @override
  State<Discovery> createState() => _DiscoveryState();
}

class _DiscoveryState extends State<Discovery> {
  late Future<emotiva.Device> _device;
  emotiva.Device? device;

  @override
  initState() {
    super.initState();
    if (widget.useFake) {
      _log('Using fake device.');
      _device = emotiva.futureFakeDevice();
    } else {
      _device = emotiva.discovery(3);
    }
  }

  @override
  void dispose() async {
    super.dispose();
    if (device != null) {
      _log('Unsubscribing from all fields.');
      await device!.unsubscribeAll();
      _log('Closing sockets for device.');
      await device!.closeSockets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<emotiva.Device>(
      // TODO - Figure out a better way to protect against a new Device object
      // doing work before the old Device object has been disposed.  E.g. The
      // old Device might unsubscribe the new Device from notification.
      future: widget.rediscover
          ? Future.delayed(Duration(seconds: 1), () => _device)
          : _device,
      builder: (BuildContext context, AsyncSnapshot<emotiva.Device> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return NoDevicesFoundPage();
          }
          return ChangeNotifierProvider(
            create: (context) {
              _log('Found Emotiva device.');
              device = snapshot.data!;
              // Initialing DeviceChanges to set up the UDP port listeners
              // before calling subscribeAll(), which should result in
              // populating the attributes of device.
              final deviceChanges = DeviceChanges(device!);
              device!.subscribeAll();
              return deviceChanges;
            },
            child: MainView(),
          );
        } else {
          return ScanningPage();
        }
      },
    );
  }
}
