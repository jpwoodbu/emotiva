import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:emotiva_remote/emotiva.dart' as emotiva;

class Remote extends StatelessWidget {
  final emotiva.Device device;
  const Remote(this.device, {super.key});
  static const double sheetPadding = 15.0;

  void addHapticForTrim(Function function, int trim) {
    HapticFeedback.lightImpact();
    function(trim);
  }

  void setHdmi(BuildContext context, int input) async {
    HapticFeedback.lightImpact();
    device.setHdmi(input);
    Navigator.pop(context);
  }

  void setCoax(BuildContext context, int input) async {
    HapticFeedback.lightImpact();
    device.setCoax(input);
    Navigator.pop(context);
  }

  void setOptical(BuildContext context, int input) async {
    HapticFeedback.lightImpact();
    device.setOptical(input);
    Navigator.pop(context);
  }

  void setAnalog(BuildContext context, int input) async {
    HapticFeedback.lightImpact();
    device.setAnalog(input);
    Navigator.pop(context);
  }

  void setArc(BuildContext context) async {
    HapticFeedback.lightImpact();
    device.setArc();
    Navigator.pop(context);
  }

  void setUsb(BuildContext context) async {
    HapticFeedback.lightImpact();
    device.setUsb();
    Navigator.pop(context);
  }

  void setTuner(BuildContext context) async {
    HapticFeedback.lightImpact();
    device.setTuner();
    Navigator.pop(context);
  }

  void setFront(BuildContext context) async {
    HapticFeedback.lightImpact();
    device.setFront();
    Navigator.pop(context);
  }

  void setModeAuto(BuildContext context) async {
    HapticFeedback.lightImpact();
    device.modeAuto();
    Navigator.pop(context);
  }

  void setModeStereo(BuildContext context) async {
    HapticFeedback.lightImpact();
    device.modeStereo();
    Navigator.pop(context);
  }

  void setModeDirect(BuildContext context) async {
    HapticFeedback.lightImpact();
    device.modeDirect();
    Navigator.pop(context);
  }

  void setModeReferenceStereo(BuildContext context) async {
    HapticFeedback.lightImpact();
    device.modeReferenceStereo();
    Navigator.pop(context);
  }

  void setModeDolby(BuildContext context) async {
    HapticFeedback.lightImpact();
    device.modeDolby();
    Navigator.pop(context);
  }

  void setModeDts(BuildContext context) async {
    HapticFeedback.lightImpact();
    device.modeDts();
    Navigator.pop(context);
  }

  void setModeAllStereo(BuildContext context) async {
    HapticFeedback.lightImpact();
    device.modeAllStereo();
    Navigator.pop(context);
  }

  void setSpeakerPreset1(BuildContext context) async {
    HapticFeedback.lightImpact();
    device.speakerPreset1();
    Navigator.pop(context);
  }

  void setSpeakerPreset2(BuildContext context) async {
    HapticFeedback.lightImpact();
    device.speakerPreset2();
    Navigator.pop(context);
  }

  void hdmiBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, 1),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 1')),
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, 2),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 2')),
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, 3),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 3')),
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, 4),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 4')),
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, 5),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 5')),
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, 6),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 6')),
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, 7),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 7')),
              ElevatedButton.icon(
                  onPressed: () => setHdmi(context, 8),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('HDMI 8')),
            ],
          ),
        );
      },
    );
  }

  void coaxBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: () => setCoax(context, 1),
                  icon: Icon(Icons.settings_input_composite),
                  label: Text('Coax 1')),
              ElevatedButton.icon(
                  onPressed: () => setCoax(context, 2),
                  icon: Icon(Icons.settings_input_composite),
                  label: Text('Coax 2')),
              ElevatedButton.icon(
                  onPressed: () => setCoax(context, 3),
                  icon: Icon(Icons.settings_input_composite),
                  label: Text('Coax 3')),
              ElevatedButton.icon(
                  onPressed: () => setCoax(context, 4),
                  icon: Icon(Icons.settings_input_composite),
                  label: Text('Coax 4')),
            ],
          ),
        );
      },
    );
  }

  void opticalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: () => setOptical(context, 1),
                  icon: Icon(Icons.lightbulb),
                  label: Text('Optical 1')),
              ElevatedButton.icon(
                  onPressed: () => setOptical(context, 2),
                  icon: Icon(Icons.lightbulb),
                  label: Text('Optical 2')),
              ElevatedButton.icon(
                  onPressed: () => setOptical(context, 3),
                  icon: Icon(Icons.lightbulb),
                  label: Text('Optical 3')),
              ElevatedButton.icon(
                  onPressed: () => setOptical(context, 4),
                  icon: Icon(Icons.lightbulb),
                  label: Text('Optical 4')),
            ],
          ),
        );
      },
    );
  }

  void analogBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton.icon(
                  onPressed: () => setAnalog(context, 1),
                  icon: Icon(Icons.settings_input_component),
                  label: Text('Analog 1')),
              ElevatedButton.icon(
                  onPressed: () => setAnalog(context, 2),
                  icon: Icon(Icons.settings_input_component),
                  label: Text('Analog 2')),
              ElevatedButton.icon(
                  onPressed: () => setAnalog(context, 3),
                  icon: Icon(Icons.settings_input_component),
                  label: Text('Analog 3')),
              ElevatedButton.icon(
                  onPressed: () => setAnalog(context, 4),
                  icon: Icon(Icons.settings_input_component),
                  label: Text('Analog 4')),
            ],
          ),
        );
      },
    );
  }

  void otherBottomSheet(BuildContext context) {
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
                  onPressed: () => setArc(context),
                  icon: Icon(Icons.settings_input_hdmi),
                  label: Text('ARC')),
              ElevatedButton.icon(
                  onPressed: () => setUsb(context),
                  icon: Icon(Icons.usb),
                  label: Text('USB')),
              ElevatedButton.icon(
                  onPressed: () => setTuner(context),
                  icon: Icon(Icons.radio),
                  label: Text('Tuner')),
              ElevatedButton.icon(
                  onPressed: () => setFront(context),
                  icon: Icon(Icons.smartphone),
                  label: Text('Front')),
            ],
          ),
        );
      },
    );
  }

  void modeBottomSheet(BuildContext context) {
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
                  onPressed: () => setModeAuto(context),
                  icon: Icon(Icons.surround_sound),
                  label: Text('Auto')),
              ElevatedButton.icon(
                  onPressed: () => setModeStereo(context),
                  icon: Icon(Icons.speaker_group),
                  label: Text('Stereo')),
              ElevatedButton.icon(
                  onPressed: () => setModeDirect(context),
                  icon: Icon(Icons.arrow_forward),
                  label: Text('Direct')),
              ElevatedButton.icon(
                  onPressed: () => setModeReferenceStereo(context),
                  icon: Icon(Icons.hearing),
                  label: Text('Reference Stereo')),
              ElevatedButton.icon(
                  onPressed: () => setModeDolby(context),
                  icon: Icon(Icons.surround_sound),
                  label: Text('Dolby')),
              ElevatedButton.icon(
                  onPressed: () => setModeDts(context),
                  icon: Icon(Icons.surround_sound),
                  label: Text('DTS')),
              ElevatedButton.icon(
                  onPressed: () => setModeAllStereo(context),
                  icon: Icon(Icons.hub),
                  label: Text('All Stereo')),
            ],
          ),
        );
      },
    );
  }

  void speakerPresetBottomSheet(BuildContext context) {
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
                  onPressed: () => setSpeakerPreset1(context),
                  icon: Icon(Icons.speaker),
                  label: Text('Preset 1')),
              ElevatedButton.icon(
                  onPressed: () => setSpeakerPreset2(context),
                  icon: Icon(Icons.speaker),
                  label: Text('Preset 2')),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      hdmiBottomSheet(context);
                    },
                    icon: Icon(Icons.settings_input_hdmi),
                    label: Text('HDMI inputs'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(tableCellPadding),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      coaxBottomSheet(context);
                    },
                    icon: Icon(Icons.settings_input_composite),
                    label: Text('Coax inputs'),
                  ),
                ),
              ]),
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.all(tableCellPadding),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      opticalBottomSheet(context);
                    },
                    icon: Icon(Icons.lightbulb),
                    label: Text('Optical inputs'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(tableCellPadding),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      analogBottomSheet(context);
                    },
                    icon: Icon(Icons.settings_input_component),
                    label: Text('Analog inputs'),
                  ),
                ),
              ]),
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.all(tableCellPadding),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      otherBottomSheet(context);
                    },
                    icon: Icon(Icons.more),
                    label: Text('Other inputs'),
                  ),
                ),
                Text(''),
              ]),
              TableRow(children: [SizedBox(height: 20), Text('')]),
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.all(tableCellPadding),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      modeBottomSheet(context);
                    },
                    icon: Icon(Icons.surround_sound),
                    label: Text('Mode'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(tableCellPadding),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      speakerPresetBottomSheet(context);
                    },
                    icon: Icon(Icons.speaker),
                    label: Text('Speaker preset'),
                  ),
                ),
              ]),
            ],
          ),
          SizedBox(height: 25),
          Table(
            children: [
              TableRow(children: [
                IconButton(
                    onPressed: () => addHapticForTrim(device.trimCenter, 1),
                    icon: Icon(Icons.keyboard_arrow_up, size: arrowSize)),
                IconButton(
                    onPressed: () => addHapticForTrim(device.trimSubwoofer, 1),
                    icon: Icon(Icons.keyboard_arrow_up, size: arrowSize)),
                IconButton(
                    onPressed: () => addHapticForTrim(device.trimSurround, 1),
                    icon: Icon(Icons.keyboard_arrow_up, size: arrowSize)),
                IconButton(
                    onPressed: () => addHapticForTrim(device.trimBack, 1),
                    icon: Icon(Icons.keyboard_arrow_up, size: arrowSize)),
              ]),
              TableRow(children: [
                Center(child: Text('Center')),
                Center(child: Text('Sub')),
                Center(child: Text('Surround')),
                Center(child: Text('Back')),
              ]),
              TableRow(children: [
                IconButton(
                    onPressed: () => addHapticForTrim(device.trimCenter, -1),
                    icon: Icon(Icons.keyboard_arrow_down, size: arrowSize)),
                IconButton(
                    onPressed: () => addHapticForTrim(device.trimSubwoofer, -1),
                    icon: Icon(Icons.keyboard_arrow_down, size: arrowSize)),
                IconButton(
                    onPressed: () => addHapticForTrim(device.trimSurround, -1),
                    icon: Icon(Icons.keyboard_arrow_down, size: arrowSize)),
                IconButton(
                    onPressed: () => addHapticForTrim(device.trimBack, -1),
                    icon: Icon(Icons.keyboard_arrow_down, size: arrowSize)),
              ]),
            ],
          )
        ],
      ),
    );
  }
}
