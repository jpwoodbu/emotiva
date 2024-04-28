import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'emotiva.dart' as emotiva;
import 'device_changes.dart';
import 'help.dart';
import 'info_page.dart';
import 'inputs_page.dart';
import 'known_issues.dart';
import 'menu_page.dart';
import 'tuner_page.dart';
import 'util.dart';
import 'zone2_page.dart';

final _log = Logger('main');
const String settingMultiDevice = 'multiDeviceEnabled';

void main() async {
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
      home: const DiscoverySwitch(),
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

AppBar? _appBar(BuildContext context, emotiva.Device device) {
  return AppBar(
    title: const Center(child: Text('Emotiva Remote')),
    leading: IconButton(
      icon: const Icon(
        Icons.help,
        semanticLabel: 'show help',
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Help()),
      ),
    ),
    actions: [
      PopupMenuButton(
        itemBuilder: (BuildContext context) => [
          PopupMenuItem(
            child: const Text('Device discovery'),
            onTap: () {
              // The analyzer throws warnings if we await for unsubscribeAll()
              // while then passing context in the next call. Unsubscribing is
              // kind, but not imperitive. It's OK to do it optimistically.
              device.unsubscribeAll();
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DiscoverySwitch(rediscover: true),
                  ),
                  (Route<dynamic> route) => false);
            },
          ),
          PopupMenuItem(
            child: const Text('Known issues'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KnownIssues()),
            ),
          ),
          PopupMenuItem(
            child: const Text('Licenses'),
            onTap: () => showLicensePage(context: context),
          ),
          const PopupMenuItem(child: MultiDeviceSetting()),
        ],
      ),
    ],
  );
}

class DiscoverySwitch extends StatefulWidget {
  final bool rediscover;
  const DiscoverySwitch({super.key, this.rediscover = false});

  @override
  State<DiscoverySwitch> createState() => _RediscoverState();
}

class _RediscoverState extends State<DiscoverySwitch> {
  late Future<SharedPreferences> _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _preferences,
      builder:
          (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return const CircularProgressIndicator();
          case ConnectionState.active:
          case ConnectionState.done:
            if (snapshot.hasError) {
              _log.severe(
                  'Error fetching multi-device setting: ${snapshot.error}');
              return const Text('Error fetching settings.');
            } else {
              final p = snapshot.data!;
              final multiDeviceEnable = p.getBool(settingMultiDevice) ?? false;
              return multiDeviceEnable
                  ? const MultiDeviceDiscovery()
                  : Discovery(rediscover: widget.rediscover);
            }
        }
      },
    );
  }
}

class MultiDeviceSetting extends StatefulWidget {
  const MultiDeviceSetting({super.key});

  @override
  State<MultiDeviceSetting> createState() => _MultiDeviceSettingState();
}

class _MultiDeviceSettingState extends State<MultiDeviceSetting> {
  late Future<SharedPreferences> _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _preferences,
      builder:
          (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return const CircularProgressIndicator();
          case ConnectionState.active:
          case ConnectionState.done:
            if (snapshot.hasError) {
              _log.severe(
                  'Error fetching multi-device setting: ${snapshot.error}');
              return const Text('Error fetching settings.');
            } else {
              final p = snapshot.data!;
              final multiDeviceEnable = p.getBool(settingMultiDevice) ?? false;
              return multiDeviceEnable ? _disable(p) : _enable(p);
            }
        }
      },
    );
  }

  void setSetting(SharedPreferences p, bool value) async {
    await p.setBool(settingMultiDevice, value);
    _log.fine('multi-device mode -> ${p.getBool(settingMultiDevice)}');
    setState(() {});
  }

  Widget _disable(SharedPreferences p) {
    return TextButton.icon(
      onPressed: () => setSetting(p, false),
      icon: const Icon(Icons.check_box),
      label: const Text('Multi-device mode'),
    );
  }

  Widget _enable(SharedPreferences p) {
    return TextButton.icon(
      onPressed: () => setSetting(p, true),
      icon: const Icon(Icons.check_box_outline_blank),
      label: const Text('Multi-device mode'),
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int _currentPageIndex = 0;

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
        appBar: _currentPageIndex == 0 ? _appBar(context, device) : null,
        // Using IndexedStack is critical. It preserves the existance (I think) of
        // the widgets as the user navigates between them so that we don't try to
        // do something breaking like creating additional listeners for a stream
        // inside initState perhaps before the prior listeners have been GC'd.
        body: IndexedStack(
          index: _currentPageIndex,
          children: const [
            InfoPage(),
            InputsPage(),
            MenuPage(),
            TunerPage(),
            Zone2Page(),
          ],
        ),
        persistentFooterButtons: _footer(device, _currentPageIndex),
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
          selectedIndex: _currentPageIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentPageIndex = index;
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
              const Text('No Emotiva device was found.'),
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
              Text('Searching for an Emotiva device...'),
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
  // provideDevice allows an external discovery process to provide an already
  // discovered device. E.g. the multi-device discovery feature.
  final emotiva.Device? providedDevice;
  const Discovery(
      {super.key,
      this.useFake = false,
      this.rediscover = false,
      this.providedDevice});

  @override
  State<Discovery> createState() => _DiscoveryState();
}

class _DiscoveryState extends State<Discovery> {
  late Future<emotiva.Device> _device;
  late final AppLifecycleListener _listener;
  emotiva.Device? device;

  Future<emotiva.Device> _futureProvidedDevice() async {
    return widget.providedDevice!;
  }

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
    } else if (widget.providedDevice != null) {
      _device = _futureProvidedDevice();
    } else {
      // Discovery is usually very fast... O(ms). To avoid the scanning widget
      // being displayed for such a short time that they user can't read it
      // (which would be janky), delay discovery for a second.
      _device = Future<emotiva.Device>.delayed(
          const Duration(milliseconds: 750), () => emotiva.discover(3));
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

class MultiDeviceDiscoveryChanges with ChangeNotifier {
  final emotiva.MultiDeviceDiscover _discover;
  late Stream<emotiva.Device> _stream;
  final Set<emotiva.Device> devices = {};

  MultiDeviceDiscoveryChanges(this._discover) {
    _stream = _discover.listen();
    _handleDevices();
  }

  Future<void> _handleDevices() async {
    await for (final device in _stream) {
      devices.add(device);
      notifyListeners();
    }
  }
}

class MultiDeviceDiscovery extends StatefulWidget {
  const MultiDeviceDiscovery({super.key});

  @override
  State<MultiDeviceDiscovery> createState() => _MultiDeviceDiscoveryState();
}

class _MultiDeviceDiscoveryState extends State<MultiDeviceDiscovery> {
  late emotiva.MultiDeviceDiscover _discover;

  @override
  void initState() {
    super.initState();
    _discover = emotiva.MultiDeviceDiscover();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MultiDeviceDiscoveryChanges(_discover),
      child: _consumer(),
    );
  }

  Widget _consumer() {
    return Consumer<MultiDeviceDiscoveryChanges>(
      builder: (context, changes, _) => _page(changes.devices),
    );
  }

  Widget _page(Set<emotiva.Device> devices) {
    return SafeArea(
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(25.0),
          children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Device selection',
                        style: Theme.of(context).textTheme.titleMedium),
                    ElevatedButton(
                      onPressed: () {
                        _discover.close();
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const Discovery(useFake: true)),
                            (Route<dynamic> route) => false);
                      },
                      child: const Text('Demo mode'),
                    ),
                  ],
                ),
                const SizedBox(height: 15.0),
                const LinearProgressIndicator(),
                const SizedBox(height: 15.0),
              ] +
              _devices(devices),
        ),
      ),
    );
  }

  List<Widget> _devices(Set<emotiva.Device> devices) {
    if (devices.isEmpty) {
      return const [Text('No devices found so far...')];
    } else {
      return devices
          .map((e) => Card(
                child: SizedBox(
                  width: 300,
                  height: 75,
                  child: ListTile(
                    leading: const Icon(Icons.album),
                    title: Text(e.name),
                    subtitle: Text(e.address.address),
                    onTap: () {
                      _discover.close();
                      _connect(e);
                    },
                  ),
                ),
              ))
          .toList();
    }
  }

  void _connect(emotiva.Device device) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => Discovery(providedDevice: device)),
      (Route<dynamic> route) => false,
    );
  }
}
