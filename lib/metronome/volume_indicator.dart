import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

class VolumeIndicator extends StatefulWidget {
  const VolumeIndicator({super.key});

  @override
  State<VolumeIndicator> createState() => _VolumeIndicatorState();
}

class _VolumeIndicatorState extends State<VolumeIndicator> {
  bool isMute = false;

  @override
  void initState() {
    FlutterVolumeController.addListener((value) {
      setState(() {
        isMute = value == 0;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    FlutterVolumeController.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        await FlutterVolumeController.toggleMute();
        isMute = await FlutterVolumeController.getMute() ?? false;
        setState(() {});
      },
      icon: Icon(isMute ? Icons.vibration : Icons.volume_up),
    );
  }
}
