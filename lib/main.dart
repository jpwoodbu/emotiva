import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:logging_flutter/logging_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'emotiva.dart' as emotiva;
import 'device_changes.dart';
import 'page_index_change_notifier.dart';
import 'util.dart';
import 'widgets/help.dart';
import 'widgets/info_page.dart';
import 'widgets/inputs_page.dart';
import 'widgets/known_issues.dart';
import 'widgets/menu_page.dart';
import 'widgets/tuner_page.dart';
import 'widgets/zone2_page.dart';
import 'widgets/volume_controls.dart';

final _log = Logger('main');
const String kSettingMultiDevice = 'multiDeviceEnabled';

void main() async {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Set up in-app log viewing.
  Flogger.init(
    config: const FloggerConfig(
      printClassName: true,
      printMethodName: true,
      showDateTime: true,
      showDebugLogs: true,
    ),
  );
  Flogger.registerListener(
    (record) => LogConsole.add(
      OutputEvent(record.level, [record.printable()]),
      bufferSize: 1000,
    ),
  );

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
      // Apple doesn't like me using "Emotiva" in the app.
      title: isApple(context) ? 'Remote Control' : 'Emotiva Remote',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        // This is necessary so that Cupertino widgets use our theme.
        cupertinoOverrideTheme: const CupertinoThemeData(
          applyThemeToAll: true,
        ),
      ),
      home: const DiscoverySwitch(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DiscoverySwitch extends StatefulWidget {
  const DiscoverySwitch({super.key});

  @override
  State<DiscoverySwitch> createState() => _DiscoverySwitchState();
}

class _DiscoverySwitchState extends State<DiscoverySwitch> {
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
            return const CircularProgressIndicator.adaptive();
          case ConnectionState.active:
          case ConnectionState.done:
            if (snapshot.hasError) {
              _log.severe(
                  'Error fetching multi-device setting: ${snapshot.error}');
              return const Text('Error fetching settings.');
            }
            final p = snapshot.data!;
            final multiDeviceEnable = p.getBool(kSettingMultiDevice) ?? false;
            return multiDeviceEnable
                ? const MultiDeviceDiscovery()
                : const Discovery();
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
            return const LinearProgressIndicator();
          case ConnectionState.active:
          case ConnectionState.done:
            if (snapshot.hasError) {
              _log.severe(
                  'Error fetching multi-device setting: ${snapshot.error}');
              return const Text('Error fetching settings.');
            } else {
              final p = snapshot.data!;
              final currentSetting = p.getBool(kSettingMultiDevice) ?? false;
              return TextButton.icon(
                icon: currentSetting
                    ? const Icon(Icons.check_box)
                    : const Icon(Icons.check_box_outline_blank),
                onPressed: () async {
                  await p.setBool(kSettingMultiDevice, !currentSetting);
                  _log.fine(
                      'multi-device mode -> ${p.getBool(kSettingMultiDevice)}');
                  setState(() {});
                },
                label: const Text('Multi-device mode'),
              );
            }
        }
      },
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  final _pageIndexModel = PageIndexChangeNotifier();

  @override
  void initState() {
    super.initState();
    context.read<DeviceChanges>().device.subscribeAll();
  }

  @override
  Widget build(BuildContext context) {
    const appIcon = Image(
      image: AssetImage('assets/hdpi_app_icon.png'),
      height: 72.0,
      width: 72.0,
    );
    return SafeArea(
      child: Scaffold(
        appBar: _pageIndexModel.pageIndex == 0
            ? AppBar(
                title: Center(
                  child: isApple(context)
                      ? const Text('Remote Control')
                      : const Text('Emotiva Remote'),
                ),
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
                  // https://api.flutter.dev/flutter/material/PopupMenuButton-class.html
                  // suggest migrating to MenuAnchor.
                  MenuAnchor(
                    builder:
                        (BuildContext context, MenuController controller, _) {
                      return IconButton(
                        onPressed: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        icon: const Icon(Icons.more_vert),
                      );
                    },
                    menuChildren: [
                      MenuItemButton(
                        child: const Text('Device discovery'),
                        onPressed: () {
                          final device = context.read<DeviceChanges>().device;
                          device.unsubscribeAll();
                          device.closeSockets();
                          navigateToDiscovery();
                        },
                      ),
                      MenuItemButton(
                        child: const Text('Known issues'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const KnownIssues()),
                        ),
                      ),
                      MenuItemButton(
                        child: const Text('Licenses'),
                        onPressed: () => showLicensePage(
                          context: context,
                          applicationName: 'Unofficial Emotiva Remote',
                          applicationIcon: isApple(context)
                              // The iOS icon was required by Apple to be
                              // different and I don't have an appropriate
                              // version of the iOS icon to use here.
                              ? null
                              : appIcon,
                        ),
                      ),
                      MenuItemButton(
                        child: const Text('Debug logs'),
                        onPressed: () => LogConsole.open(context),
                      ),
                      MenuItemButton(
                        child: const MultiDeviceSetting(),
                        // MuiltiDeviceSettings has its own gesture behavior.
                        // But onPressed needs to be non-null here to get the
                        // desired hover effect.
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              )
            : null,
        // Using IndexedStack is critical. It preserves the existance (I think) of
        // the widgets as the user navigates between them so that we don't try to
        // do something breaking like creating additional listeners for a stream
        // inside initState perhaps before the prior listeners have been GC'd.
        body: IndexedStack(
          index: _pageIndexModel.pageIndex,
          children: const [
            InfoPage(),
            InputsPage(),
            MenuPage(),
            TunerPage(),
            Zone2Page(),
          ],
        ),
        persistentFooterButtons: [
          ChangeNotifierProvider.value(
            value: _pageIndexModel,
            child: const VolumeControls(),
          )
        ],
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
          selectedIndex: _pageIndexModel.pageIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _pageIndexModel.setPageIndex(index);
            });
          },
        ),
      ),
    );
  }

  // This was extracted into its own method to avoid
  // https://dart.dev/tools/diagnostic-messages?utm_source=dartdev&utm_medium=redir&utm_id=diagcode&utm_content=use_build_context_synchronously#use_build_context_synchronously.
  /// TL;DR: Don't pass [context] inside an async callback. I believe the
  /// references to [context] inside this function will use a different getter
  /// than the async callback would use.
  void navigateToDiscovery() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const DiscoverySwitch(),
        ),
        (Route<dynamic> route) => false);
  }
}

class DiscoveryError extends StatelessWidget {
  final Object error;
  const DiscoveryError({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    // This is the default message when error is not a String. It was likely a
    // TimeoutException.
    String message = isApple(context)
        ? 'No device was found.'
        : 'No Emotiva device was found.';
    if (error is String) message = error.toString();
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(kPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(message),
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
      ),
    );
  }
}

class ScanningPage extends StatelessWidget {
  const ScanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isApple(context)
                  ? const Text('Searching for a device...')
                  : const Text('Searching for an Emotiva device...'),
              const SizedBox(height: 25.0),
              const CircularProgressIndicator.adaptive(),
            ],
          ),
        ),
      ),
    );
  }
}

class Discovery extends StatefulWidget {
  final bool useFake;
  // providedDevice allows an external discovery process to provide an already
  // discovered device. E.g. the multi-device discovery feature.
  final emotiva.Device? providedDevice;

  const Discovery({super.key, this.useFake = false, this.providedDevice});

  @override
  State<Discovery> createState() => _DiscoveryState();
}

class _DiscoveryState extends State<Discovery> {
  late Future<emotiva.Device> _device;
  late final AppLifecycleListener _listener;
  emotiva.Device? device;

  Future<emotiva.Device> _futureProvidedDevice() async =>
      widget.providedDevice!;

  @override
  initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onExitRequested: () async {
        if (device != null) {
          _log.info('Unsubscribing from all fields.');
          device?.unsubscribeAll();
          _log.info('Closing sockets for device.');
          device?.closeSockets();
        }
        return AppExitResponse.exit;
      },
    );
    if (widget.useFake) {
      _log.info('Using fake device.');
      _device = emotiva.futureFakeDevice();
    } else if (widget.providedDevice != null) {
      _device = _futureProvidedDevice().then(_setupDevice);
    } else {
      // Discovery is usually very fast... O(ms). To avoid the scanning widget
      // being displayed for such a short time that the user can't read it
      // (which would be janky), show it for at least 750ms.
      _device = waitAtLeast<emotiva.Device>(
          future: emotiva.discover(3).then(_setupDevice),
          duration: const Duration(milliseconds: 750));
    }
  }

  @override
  void dispose() {
    super.dispose();
    _listener.dispose();
  }

  Future<emotiva.Device> _setupDevice(emotiva.Device device) async {
    _log.info('Found Emotiva device.');
    await device.bindSockets();
    return device;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<emotiva.Device>(
      future: _device,
      builder: (BuildContext context, AsyncSnapshot<emotiva.Device> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            _log.severe('Error on device discovery: ${snapshot.error}');
            return DiscoveryError(error: snapshot.error!);
          }
          return ChangeNotifierProvider(
            create: (BuildContext _) => DeviceChanges(snapshot.data!),
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
      create: (BuildContext _) => MultiDeviceDiscoveryChanges(_discover),
      builder: (context, _) => SafeArea(
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
                _devices(context.watch<MultiDeviceDiscoveryChanges>().devices),
          ),
        ),
      ),
    );
  }

  List<Widget> _devices(Set<emotiva.Device> devices) {
    if (devices.isEmpty) {
      return const [Text('No devices found so far...')];
    } else {
      return devices
          .map((device) => Card(
                child: SizedBox(
                  width: 300,
                  height: 75,
                  child: ListTile(
                    leading: const Icon(Icons.album),
                    title: Text(device.name),
                    subtitle: Text(device.address.address),
                    onTap: () {
                      _discover.close();
                      _connect(device);
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
