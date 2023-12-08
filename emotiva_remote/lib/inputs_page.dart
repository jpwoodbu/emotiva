import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;
import 'device_changes.dart';

class InputsPage extends StatelessWidget {
  const InputsPage({super.key});
  static const double sheetPadding = 15.0;

  void setSource(BuildContext context, emotiva.Device device, int input) async {
    HapticFeedback.lightImpact();
    device.setSource(input);
    Navigator.pop(context);
  }

  void setHdmi(BuildContext context, emotiva.Device device, int input) async {
    HapticFeedback.lightImpact();
    device.setHdmi(input);
    Navigator.pop(context);
  }

  void setCoax(BuildContext context, emotiva.Device device, int input) async {
    HapticFeedback.lightImpact();
    device.setCoax(input);
    Navigator.pop(context);
  }

  void setAesEbu(BuildContext context, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.setAesEbu();
    Navigator.pop(context);
  }

  void setOptical(
      BuildContext context, emotiva.Device device, int input) async {
    HapticFeedback.lightImpact();
    device.setOptical(input);
    Navigator.pop(context);
  }

  void setAnalog(BuildContext context, emotiva.Device device, int input) async {
    HapticFeedback.lightImpact();
    device.setAnalog(input);
    Navigator.pop(context);
  }

  void setBalancedInput(BuildContext context, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.setBalancedInput();
    Navigator.pop(context);
  }

  void setArc(BuildContext context, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.setArc();
    Navigator.pop(context);
  }

  void setUsb(BuildContext context, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.setUsb();
    Navigator.pop(context);
  }

  void setTuner(BuildContext context, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.setTuner();
    Navigator.pop(context);
  }

  void setFront(BuildContext context, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.setFront();
    Navigator.pop(context);
  }

  void setModeAuto(BuildContext context, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.modeAuto();
    Navigator.pop(context);
  }

  void setModeStereo(BuildContext context, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.modeStereo();
    Navigator.pop(context);
  }

  void setModeDirect(BuildContext context, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.modeDirect();
    Navigator.pop(context);
  }

  void setModeReferenceStereo(
      BuildContext context, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.modeReferenceStereo();
    Navigator.pop(context);
  }

  void setModeDolby(BuildContext context, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.modeDolby();
    Navigator.pop(context);
  }

  void setModeDts(BuildContext context, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.modeDts();
    Navigator.pop(context);
  }

  void setModeAllStereo(BuildContext context, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.modeAllStereo();
    Navigator.pop(context);
  }

  void setSpeakerPreset1(BuildContext context, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.speakerPreset1();
    Navigator.pop(context);
  }

  void setSpeakerPreset2(BuildContext context, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    device.speakerPreset2();
    Navigator.pop(context);
  }

  void bumpCenterTrim(double step, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    final trim = device.centerTrim += step;
    device.trimCenter(trim);
  }

  void bumpSubwooferTrim(double step, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    final trim = device.subwooferTrim += step;
    device.trimSubwoofer(trim);
  }

  void bumpSurroundTrim(double step, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    final trim = device.surroundTrim += step;
    device.trimSurround(trim);
  }

  void bumpBackTrim(double step, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    final trim = device.backTrim += step;
    device.trimBack(trim);
  }

  void bumpHeightTrim(double step, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    final trim = device.heightTrim += step;
    device.trimHeight(trim);
  }

  void bumpWidthTrim(double step, emotiva.Device device) async {
    HapticFeedback.lightImpact();
    final trim = device.widthTrim += step;
    device.trimWidth(trim);
  }

  List<Widget> _buildSourceList(BuildContext context, emotiva.Device device) {
    List<Widget> widgets = [];
    for (var i = 1; i < 9; i++) {
      final bool visible = device.visibility['input_$i'] ?? false;
      String name = device.names['input_$i'] ?? 'Source $i';
      if (name.isEmpty) {
        name = 'Source $i';
      }
      if (visible) {
        widgets.add(
          ElevatedButton.icon(
            onPressed: () => setSource(context, device, i),
            icon: Icon(Icons.person),
            label: Text(name),
          ),
        );
      }
    }
    return widgets;
  }

  void sourceBottomSheet(BuildContext context, emotiva.Device device) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildSourceList(context, device),
          ),
        );
      },
    );
  }

  void hdmiBottomSheet(BuildContext context, emotiva.Device device) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, device, 1),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 1')),
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, device, 2),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 2')),
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, device, 3),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 3')),
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, device, 4),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 4')),
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, device, 5),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 5')),
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, device, 6),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 6')),
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, device, 7),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 7')),
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, device, 8),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 8')),
            ],
          ),
        );
      },
    );
  }

  void coaxBottomSheet(BuildContext context, emotiva.Device device) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: () => setCoax(context, device, 1),
                  icon: Icon(Icons.settings_input_composite),
                  label: Text('Coax 1')),
              ElevatedButton.icon(
                  onPressed: () => setCoax(context, device, 2),
                  icon: Icon(Icons.settings_input_composite),
                  label: Text('Coax 2')),
              ElevatedButton.icon(
                  onPressed: () => setCoax(context, device, 3),
                  icon: Icon(Icons.settings_input_composite),
                  label: Text('Coax 3')),
              ElevatedButton.icon(
                  onPressed: () => setCoax(context, device, 4),
                  icon: Icon(Icons.settings_input_composite),
                  label: Text('Coax 4')),
            ],
          ),
        );
      },
    );
  }

  void opticalBottomSheet(BuildContext context, emotiva.Device device) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: () => setOptical(context, device, 1),
                  icon: Icon(Icons.lightbulb),
                  label: Text('Optical 1')),
              ElevatedButton.icon(
                  onPressed: () => setOptical(context, device, 2),
                  icon: Icon(Icons.lightbulb),
                  label: Text('Optical 2')),
              ElevatedButton.icon(
                  onPressed: () => setOptical(context, device, 3),
                  icon: Icon(Icons.lightbulb),
                  label: Text('Optical 3')),
              ElevatedButton.icon(
                  onPressed: () => setOptical(context, device, 4),
                  icon: Icon(Icons.lightbulb),
                  label: Text('Optical 4')),
            ],
          ),
        );
      },
    );
  }

  void xlrBottomSheet(BuildContext context, emotiva.Device device) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: () => setAesEbu(context, device),
                  icon: Icon(Icons.developer_board),
                  label: Text('AES/EBU')),
              ElevatedButton.icon(
                  onPressed: () => setBalancedInput(context, device),
                  icon: Icon(Icons.album),
                  label: Text('Balanced Input')),
            ],
          ),
        );
      },
    );
  }

  void analogBottomSheet(BuildContext context, emotiva.Device device) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: () => setAnalog(context, device, 1),
                  icon: Icon(Icons.settings_input_component),
                  label: Text('Analog 1')),
              ElevatedButton.icon(
                  onPressed: () => setAnalog(context, device, 2),
                  icon: Icon(Icons.settings_input_component),
                  label: Text('Analog 2')),
              ElevatedButton.icon(
                  onPressed: () => setAnalog(context, device, 3),
                  icon: Icon(Icons.settings_input_component),
                  label: Text('Analog 3')),
            ],
          ),
        );
      },
    );
  }

  void otherBottomSheet(BuildContext context, emotiva.Device device) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: () => setArc(context, device),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('ARC')),
              ElevatedButton.icon(
                  onPressed: () => setUsb(context, device),
                  icon: Icon(Icons.usb),
                  label: Text('USB')),
              ElevatedButton.icon(
                  onPressed: () => setTuner(context, device),
                  icon: Icon(Icons.radio),
                  label: Text('Tuner')),
              ElevatedButton.icon(
                  onPressed: () => setFront(context, device),
                  icon: Icon(Icons.smartphone),
                  label: Text('Front')),
            ],
          ),
        );
      },
    );
  }

  void modeBottomSheet(BuildContext context, emotiva.Device device) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: () => setModeAuto(context, device),
                  icon: Icon(Icons.surround_sound),
                  label: Text('Auto')),
              ElevatedButton.icon(
                  onPressed: () => setModeStereo(context, device),
                  icon: Icon(Icons.speaker_group),
                  label: Text('Stereo')),
              ElevatedButton.icon(
                  onPressed: () => setModeDirect(context, device),
                  icon: Icon(Icons.arrow_forward),
                  label: Text('Direct')),
              ElevatedButton.icon(
                  onPressed: () => setModeReferenceStereo(context, device),
                  icon: Icon(Icons.hearing),
                  label: Text('Reference Stereo')),
              ElevatedButton.icon(
                  onPressed: () => setModeDolby(context, device),
                  icon: Icon(Icons.surround_sound),
                  label: Text('Dolby')),
              ElevatedButton.icon(
                  onPressed: () => setModeDts(context, device),
                  icon: Icon(Icons.surround_sound),
                  label: Text('DTS')),
              ElevatedButton.icon(
                  onPressed: () => setModeAllStereo(context, device),
                  icon: Icon(Icons.hub),
                  label: Text('All Stereo')),
            ],
          ),
        );
      },
    );
  }

  void speakerPresetBottomSheet(BuildContext context, emotiva.Device device) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: () => setSpeakerPreset1(context, device),
                  icon: Icon(Icons.speaker),
                  label: Text('Preset 1')),
              ElevatedButton.icon(
                  onPressed: () => setSpeakerPreset2(context, device),
                  icon: Icon(Icons.speaker),
                  label: Text('Preset 2')),
            ],
          ),
        );
      },
    );
  }

  Widget _build(BuildContext context, emotiva.Device device) {
    const double tableCellPadding = 8.0;
    const double arrowSize = 50.0;

    return Padding(
      padding: const EdgeInsets.all(15),
      child: ListView(
        children: [
          Table(
            children: [
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.all(tableCellPadding),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      sourceBottomSheet(context, device);
                    },
                    icon: Icon(Icons.person),
                    label: Text('Source'),
                    style: ButtonStyle(alignment: Alignment.centerLeft),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(tableCellPadding),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      hdmiBottomSheet(context, device);
                    },
                    icon: Icon(Icons.settings_input_hdmi),
                    label: Text('HDMI'),
                    style: ButtonStyle(alignment: Alignment.centerLeft),
                  ),
                ),
              ]),
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.all(tableCellPadding),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      opticalBottomSheet(context, device);
                    },
                    icon: Icon(Icons.lightbulb),
                    label: Text('Optical'),
                    style: ButtonStyle(alignment: Alignment.centerLeft),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(tableCellPadding),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      coaxBottomSheet(context, device);
                    },
                    icon: Icon(Icons.settings_input_composite),
                    label: Text('Coax'),
                    style: ButtonStyle(alignment: Alignment.centerLeft),
                  ),
                ),
              ]),
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.all(tableCellPadding),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      analogBottomSheet(context, device);
                    },
                    icon: Icon(Icons.settings_input_component),
                    label: Text('Analog'),
                    style: ButtonStyle(alignment: Alignment.centerLeft),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(tableCellPadding),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      xlrBottomSheet(context, device);
                    },
                    icon: Icon(Icons.donut_large),
                    label: Text('XLR'),
                    style: ButtonStyle(alignment: Alignment.centerLeft),
                  ),
                ),
              ]),
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.all(tableCellPadding),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      otherBottomSheet(context, device);
                    },
                    icon: Icon(Icons.more),
                    label: Text('Other'),
                    style: ButtonStyle(alignment: Alignment.centerLeft),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(tableCellPadding),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      modeBottomSheet(context, device);
                    },
                    icon: Icon(Icons.surround_sound),
                    label: Text('Mode'),
                    style: ButtonStyle(alignment: Alignment.centerLeft),
                  ),
                ),
              ]),
            ],
          ),
          SizedBox(height: 25),
          // TODO - Fix there being a table error if the system is configured
          // only with L and R speakers. Perhaps wrap the whole table in a
          // conditinoal that at least one of the speaker trims is visible.
          Table(
            children: [
              TableRow(
                children: [
                  if (device.visibility['center']!)
                    Text('${device.centerTrim}dB', textAlign: TextAlign.center),
                  if (device.visibility['subwoofer']!)
                    Text('${device.subwooferTrim}dB',
                        textAlign: TextAlign.center),
                  if (device.visibility['surround']!)
                    Text('${device.surroundTrim}dB',
                        textAlign: TextAlign.center),
                  if (device.visibility['back']!)
                    Text('${device.backTrim}dB', textAlign: TextAlign.center),
                  if (device.visibility['height']!)
                    Text('${device.heightTrim}dB', textAlign: TextAlign.center),
                  if (device.visibility['width']!)
                    Text('${device.widthTrim}dB', textAlign: TextAlign.center),
                ],
              ),
              TableRow(children: [
                if (device.visibility['center']!)
                  IconButton(
                      onPressed: () => bumpCenterTrim(0.5, device),
                      tooltip: 'Center trim up',
                      icon: Icon(Icons.keyboard_arrow_up, size: arrowSize)),
                if (device.visibility['subwoofer']!)
                  IconButton(
                      onPressed: () => bumpSubwooferTrim(0.5, device),
                      tooltip: 'Subwoofer trim up',
                      icon: Icon(Icons.keyboard_arrow_up, size: arrowSize)),
                if (device.visibility['surround']!)
                  IconButton(
                      onPressed: () => bumpSurroundTrim(0.5, device),
                      tooltip: 'Surround trim up',
                      icon: Icon(Icons.keyboard_arrow_up, size: arrowSize)),
                if (device.visibility['back']!)
                  IconButton(
                      onPressed: () => bumpBackTrim(0.5, device),
                      tooltip: 'Back trim up',
                      icon: Icon(Icons.keyboard_arrow_up, size: arrowSize)),
                if (device.visibility['height']!)
                  IconButton(
                      onPressed: () => bumpHeightTrim(0.5, device),
                      tooltip: 'Height trim up',
                      icon: Icon(Icons.keyboard_arrow_up, size: arrowSize)),
                if (device.visibility['width']!)
                  IconButton(
                      onPressed: () => bumpWidthTrim(0.5, device),
                      tooltip: 'Width trim up',
                      icon: Icon(Icons.keyboard_arrow_up, size: arrowSize)),
              ]),
              TableRow(children: [
                if (device.visibility['center']!) Center(child: Text('Center')),
                if (device.visibility['subwoofer']!) Center(child: Text('Sub')),
                if (device.visibility['surround']!) Center(child: Text('Surr')),
                if (device.visibility['back']!) Center(child: Text('Back')),
                if (device.visibility['height']!) Center(child: Text('Height')),
                if (device.visibility['width']!) Center(child: Text('Width')),
              ]),
              TableRow(children: [
                if (device.visibility['center']!)
                  IconButton(
                      onPressed: () => bumpCenterTrim(-0.5, device),
                      tooltip: 'Center trim down',
                      icon: Icon(Icons.keyboard_arrow_down, size: arrowSize)),
                if (device.visibility['subwoofer']!)
                  IconButton(
                      onPressed: () => bumpSubwooferTrim(-0.5, device),
                      tooltip: 'Subwoofer trim down',
                      icon: Icon(Icons.keyboard_arrow_down, size: arrowSize)),
                if (device.visibility['surround']!)
                  IconButton(
                      onPressed: () => bumpSurroundTrim(-0.5, device),
                      tooltip: 'Surround trim down',
                      icon: Icon(Icons.keyboard_arrow_down, size: arrowSize)),
                if (device.visibility['back']!)
                  IconButton(
                      onPressed: () => bumpBackTrim(-0.5, device),
                      tooltip: 'Back trim down',
                      icon: Icon(Icons.keyboard_arrow_down, size: arrowSize)),
                if (device.visibility['height']!)
                  IconButton(
                      onPressed: () => bumpHeightTrim(-0.5, device),
                      tooltip: 'Height trim down',
                      icon: Icon(Icons.keyboard_arrow_down, size: arrowSize)),
                if (device.visibility['width']!)
                  IconButton(
                      onPressed: () => bumpWidthTrim(-0.5, device),
                      tooltip: 'Width trim down',
                      icon: Icon(Icons.keyboard_arrow_down, size: arrowSize)),
              ]),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
        builder: (BuildContext context, DeviceChanges deviceChanges, child) {
      return _build(context, deviceChanges.device);
    });
  }
}
