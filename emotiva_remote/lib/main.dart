import 'package:emotiva_remote/emotiva.dart' as emotiva;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class DeviceModel with ChangeNotifier {
  final emotiva.Device device;
  late Stream<String> controlPortStream;
  late Stream<String> notifyPortStream;

  DeviceModel(this.device) {
    controlPortStream = device.controlPortStream();
    notifyPortStream = device.notifyPortStream();
  }

  Future<void> handleControlPackets() async {
    await for (final packet in controlPortStream) {
      device.parsePacket(packet);
      notifyListeners();
    }
  }

  Future<void> handleNotifyPackets() async {
    await for (final packet in notifyPortStream) {
      device.parsePacket(packet);
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
          Info(widget.device),
          Remote(widget.device),
        ],
      ),
      persistentFooterButtons: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Volume', style: TextStyle(fontSize: 25.0)),
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
    HapticFeedback.vibrate();
    await widget.device.updateAll();
    setState(() {});
  }

  void togglePower() async {
    HapticFeedback.lightImpact();
    widget.device.togglePower();
  }

  void subscribeAll() async {
    await widget.device.subscribeAll();
  }

  @override
  void initState() {
    super.initState();
    _deviceNotifier = DeviceModel(widget.device);
    _deviceNotifier.handleControlPackets();
    _deviceNotifier.handleNotifyPackets();
    subscribeAll();
  }

  void _toggleLoudness() async {
    setState(() {
      widget.device.toggleLoudness();
    });
  }

  void _toggleMute() async {
    widget.device.toggleMute();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: RefreshIndicator(
        onRefresh: () {
          return Future(updateAll);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ListenableBuilder(
              listenable: _deviceNotifier,
              builder: (BuildContext context, Widget? child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.device.name,
                          style: TextStyle(fontSize: 25),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: updateAll,
                              icon: Icon(
                                Icons.refresh,
                                size: 30,
                              ),
                            ),
                            IconButton(
                              onPressed: togglePower,
                              icon: Icon(
                                Icons.power_settings_new,
                                color: widget.device.power == 'On'
                                    ? Colors.blue
                                    : Colors.amber,
                                size: 30,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    Text(
                      'Volume: ${widget.device.volume}dB',
                      style: TextStyle(fontSize: 18),
                    ),
                    Table(
                      children: <TableRow>[
                        TableRow(children: [
                          SizedBox(height: 25),
                          SizedBox(height: 25),
                          SizedBox(height: 25),
                        ]),
                        TableRow(children: [
                          Text(widget.device.source),
                          Text(widget.device.mode,
                              overflow: TextOverflow.visible, softWrap: false),
                          Text(''),
                        ]),
                        TableRow(children: [
                          Text('A: ${widget.device.audioInput}'),
                          Text(widget.device.audioBitstream),
                          Text(widget.device.audioBits),
                        ]),
                        TableRow(children: [
                          Text('V: ${widget.device.videoInput}'),
                          Text(widget.device.videoFormat),
                          Text(widget.device.videoSpace),
                        ])
                      ],
                    ),
                    SizedBox(height: 25),
                    ElevatedButton.icon(
                      onPressed: _toggleLoudness,
                      icon: Icon(Icons.hearing,
                          color: widget.device.loudness == 'On'
                              ? Colors.green
                              : Colors.grey),
                      label: Text('Loudness'),
                    ),
                    ElevatedButton(
                      onPressed: _toggleMute,
                      child: Text('Mute'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Remote extends StatelessWidget {
  final emotiva.Device device;
  const Remote(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return Placeholder();
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
      // TODO - Consider, instead of pushing to the navigation below onPressed,
      // pushing to the "no devices found" widget and then popping onPressed for
      // trying again. I think that depends on the discovery process actually
      // getting retried on popping to the previous widget, but I think
      // initState will get run again on pop. That might involve not using
      // FutureBuilder, which be an overall simplicifaction.
      return Column(
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
    return Scaffold(
      body: Center(
        child: FutureBuilder<emotiva.Device>(
          // Use the fake instead if an Emotiva device is not available.
          // future: emotiva.futureFakeDevice(),
          future: emotiva.discovery(3),
          builder: _futureBuilder,
        ),
      ),
    );
  }
}
