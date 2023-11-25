import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

import 'device_model.dart';
import 'info_page.dart';
import 'inputs_page.dart';
import 'menu_page.dart';

final Uri paypalUrl =
    Uri.parse('https://www.paypal.com/donate/?hosted_button_id=63AF88NNXDG5L');
final Uri venmoUrl = Uri.parse('https://venmo.com/u/Jonathan-Woodbury-2');

void showErrorSnackBar(BuildContext context, String error) {
  final snackBar = SnackBar(content: Text(error));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

const String helpText = '''
Tip 1: Click the power icon in the top right to turn On/Off your processor.

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

Future<void> showDonateDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      scrollable: true,
      title: Text('Your support is greatly appreciated!'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
              onPressed: () async {
                if (!await launchUrl(venmoUrl)) {
                  // TODO - add logging.
                }
              },
              child: Text('Venmo @Jonathan-Woodbury-2')),
          TextButton(
              onPressed: () async {
                if (!await launchUrl(paypalUrl)) {
                  // TODO - add logging.
                }
              },
              child: Text('Paypal - Jonathan Woodbury')),
        ],
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Thank you!')),
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
    // Explicitly not unsubscribing from fields since we cannot guarantee that
    // callers of this method block on it before creating new MainView instances
    // (e.g. when re-scanning for devices). That race could result in the latest
    // incarnation of MainView having an incomplete list of subscriptions.
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
        leading: IconButton(
          icon: Icon(Icons.help),
          onPressed: () => showHelp(context),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                child: Text('Search for Emotiva devices'),
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/discovery', (Route<dynamic> route) => false);
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
              PopupMenuItem(
                child: Text('Want to show your support?'),
                onTap: () => showDonateDialog(context),
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
          InfoPage(widget.device, deviceChanges),
          InputsPage(widget.device, deviceChanges),
          MenuPage(widget.device),
        ],
      ),
      persistentFooterButtons: [
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
