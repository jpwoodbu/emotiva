import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_android_volume_keydown/flutter_android_volume_keydown.dart';

class VolumeKeyDown extends ChangeNotifier {
  late StreamSubscription<HardwareButton> _subscription;
  HardwareButton? buttonPressed;

  VolumeKeyDown() {
    _subscription = FlutterAndroidVolumeKeydown.stream.listen((event) {
      buttonPressed = event;
      notifyListeners();
     });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
