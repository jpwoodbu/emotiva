import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'emotiva.dart' as emotiva;
import 'device_changes.dart';
import 'info_page.dart';
import 'inputs_page.dart';
import 'menu_page.dart';
import 'tuner_page.dart';
import 'util.dart';
import 'zone2_page.dart';

final _log = Logger('main');

const String _helpText = '''
Tip 1: Click the power icon in the top right to turn On/Off your processor. Enable "Video on Standby" on your Emotiva processor so that it can be turned on using this app when in standby.

Tip 2: When changes happen on the Emotiva processor, data in the app should update automatically. But if you think the app is out-of-sync with the processor, click the refresh icon next to the power icon to refresh all data. Or swipe down on the info page to refresh.

Tip 3: Turn on "Touch feedback" in your phone/tablet system settings (under Vibration & haptics). Everytime the app sends a network packet to the Emotiva processor, it makes a slight vibration.

Tip 4: Data in the app are ONLY changed when updates are receieved from the Emotiva processor. If you see lag between clicking a button and seeing a field being updated, it's likely because it takes the Emotiva processor a moment to process the change and send the update.
''';

Future<void> _showHelp(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      scrollable: true,
      content: Text(_helpText.trim()),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss')),
      ],
    ),
  );
}

const String _knownIssues = '''
1) Some setting changes on Emotiva processors take around 10 seconds before they're communicated to the app. E.g. changing inputs.

2) Speaker trim levels are not updated in the app if the level is changed using another remote. E.g. another app or the IR remote.

3) HDMI color space, chroma subsamping, and HDR state are missing.

4) Zone 2 cannot explicitly set its input to Tuner. It can use Tuner as its input only if Tuner is selected for Main and Zone 2 has its input set to Following Main.
''';

Future<void> _showKnownIssus(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      scrollable: true,
      content: Text(_knownIssues.trim()),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss')),
      ],
    ),
  );
}

const String _roadMap = '''
1) Support choosing between multiple Emotiva processors on the same network. Does anyone have more than one?

2) If there's enough interest, making an iOS version of this app.
''';

Future<void> _showRoadMap(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      scrollable: true,
      content: Text(_roadMap.trim()),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss')),
      ],
    ),
  );
}

void main() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/LICENSE.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  // Disable the footer on the menu page to make more room.
  if (currentPageIndex == 2) {
    return null;
  }
  // Change the volume controls to actuate zone 2 when on the zone 2 page.
  final volumeFunction =
      currentPageIndex == 4 ? device.zone2VolumeDelta : device.volumeDelta;
  return [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Text('Volume', style: TextStyle(fontSize: 20.0)),
        ),
        Row(
          children: [
            ElevatedButton(
                onPressed: () => addHaptic(() => volumeFunction(-1.0)),
                child: const Icon(
                  Icons.remove,
                  size: 30.0,
                  semanticLabel: 'Volume down',
                )),
            const SizedBox(width: 15.0),
            ElevatedButton(
                onPressed: () => addHaptic(() => volumeFunction(1.0)),
                child: const Icon(
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

AppBar? _appBar(BuildContext context, int currentPageIndex) {
  if (currentPageIndex != 0) {
    return null;
  }
  return AppBar(
    title: const Center(child: Text('Emotiva Remote')),
    leading: IconButton(
      icon: const Icon(Icons.help),
      tooltip: 'Show help',
      onPressed: () => _showHelp(context),
    ),
    actions: [
      PopupMenuButton(
        itemBuilder: (BuildContext context) => [
          PopupMenuItem(
            child: const Text('Rediscover Emotiva device'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const Discovery(rediscover: true)),
                  (Route<dynamic> route) => false);
            },
          ),
          PopupMenuItem(
            child: const Text('Known issues'),
            onTap: () => _showKnownIssus(context),
          ),
          PopupMenuItem(
            child: const Text('Road map'),
            onTap: () => _showRoadMap(context),
          ),
          PopupMenuItem(
            child: const Text('Licenses'),
            onTap: () => showLicensePage(context: context),
          ),
        ],
      ),
    ],
  );
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
      builder: (context, deviceChanges, _) {
        return _build(context, deviceChanges.device);
      },
    );
  }

  Widget _build(BuildContext context, emotiva.Device device) {
    return SafeArea(
      child: Scaffold(
        appBar: _appBar(context, currentPageIndex),
        // Using IndexedStack is critical. It preserves the existance (I think) of
        // the widgets as the user navigates between them so that we don't try to
        // do something breaking like creating additional listeners for a stream
        // inside initState perhaps before the prior listeners have been GC'd.
        body: IndexedStack(
          index: currentPageIndex,
          children: const [
            InfoPage(),
            InputsPage(),
            MenuPage(),
            TunerPage(),
            Zone2Page(),
          ],
        ),
        persistentFooterButtons: _footer(device, currentPageIndex),
        bottomNavigationBar: NavigationBar(
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.info),
              label: 'Info',
            ),
            NavigationDestination(
              icon: Icon(Icons.route),
              label: 'Inputs',
            ),
            NavigationDestination(
              icon: Icon(Icons.gamepad),
              label: 'Menu',
            ),
            NavigationDestination(
              icon: Icon(Icons.radio),
              label: 'Tuner',
            ),
            NavigationDestination(
              icon: Icon(Icons.location_on),
              label: 'Zone 2',
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

class NoDevicesFoundPage extends StatelessWidget {
  const NoDevicesFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No Emotiva devices were found.'),
              const SizedBox(height: 25.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Discovery()),
                      (Route<dynamic> route) => false);
                },
                child: const Text('Try again'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Discovery(useFake: true)),
                      (Route<dynamic> route) => false);
                },
                child: const Text('Demo mode'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScanningPage extends StatelessWidget {
  const ScanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Scaffold(
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
  late final AppLifecycleListener _listener;
  emotiva.Device? device;

  @override
  initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onExitRequested: () async {
        if (device != null) {
          _log.info('Unsubscribing from all fields.');
          await device?.unsubscribeAll();
          _log.info('Closing sockets for device.');
          await device?.closeSockets();
        }
        return AppExitResponse.exit;
      },
    );
    if (widget.useFake) {
      _log.info('Using fake device.');
      _device = emotiva.futureFakeDevice();
    } else {
      // Discovery is usually very fast... O(ms). To avoid the scanning widget
      // being displayed for such a short time that they user can't read it
      // (which would be janky), delay discovery for a second.
      _device = Future<emotiva.Device>.delayed(
          const Duration(seconds: 1), () => emotiva.discovery(3));
    }
  }

  @override
  void dispose() async {
    super.dispose();
    _listener.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<emotiva.Device>(
      // TODO - Figure out a better way to protect against a new Device object
      // doing work before the old Device object has been disposed.  E.g. The
      // old Device might unsubscribe the new Device from notification.
      future: widget.rediscover
          ? Future.delayed(const Duration(seconds: 1), () => _device)
          : _device,
      builder: (BuildContext context, AsyncSnapshot<emotiva.Device> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const NoDevicesFoundPage();
          }
          return ChangeNotifierProvider(
            create: (_) {
              _log.info('Found Emotiva device.');
              device = snapshot.data;
              // Initializing DeviceChanges to set up the UDP port listeners
              // before calling subscribeAll(), which should result in
              // populating the attributes of device.
              final deviceChanges = DeviceChanges(device!);
              device?.subscribeAll();
              return deviceChanges;
            },
            child: const MainView(),
          );
        } else {
          return const ScanningPage();
        }
      },
    );
  }
}
