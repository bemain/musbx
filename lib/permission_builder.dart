import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionBuilder extends StatefulWidget {
  /// Allow the user to grant or deny a [permission].
  /// If [permission] is granted, [onPermissionGranted] is called.
  const PermissionBuilder({
    super.key,
    required this.permission,
    required this.onPermissionGranted,
    this.permissionName,
    this.permissionText,
  });

  /// The permission that needs to be granted before [onPermissionGranted] is called.
  final Permission permission;

  /// Called when [permission] has been granted.
  final void Function() onPermissionGranted;

  /// The name of this permission.
  final String? permissionName;

  /// Short text describing why this permission is required.
  final String? permissionText;

  @override
  State<StatefulWidget> createState() => PermissionBuilderState();
}

class PermissionBuilderState extends State<PermissionBuilder>
    with WidgetsBindingObserver {
  PermissionStatus status = PermissionStatus.denied;

  AppLifecycleState prevState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    requestPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed &&
        prevState == AppLifecycleState.paused) {
      requestPermission();
    }
    prevState = state;
  }

  @override
  Widget build(BuildContext context) {
    if (status == PermissionStatus.granted) {
      widget.onPermissionGranted();
    }

    if (status == PermissionStatus.permanentlyDenied) {
      return buildPermissionDeniedScreen(
        additionalInfoText:
            "You need to give this permission from the System Settings.",
        buttonText: "Open Settings",
        onButtonPressed: openAppSettings,
      );
    }

    return buildPermissionDeniedScreen(
      buttonText: "Request permission",
      onButtonPressed: requestPermission,
    );
  }

  Future<void> requestPermission() async {
    widget.permission.request().then((newStatus) {
      if (mounted) {
        setState(() {
          status = newStatus;
        });
      }
    });
  }

  Widget buildPermissionDeniedScreen({
    String? additionalInfoText,
    required String buttonText,
    required void Function() onButtonPressed,
  }) {
    additionalInfoText =
        (additionalInfoText != null) ? "\n\n$additionalInfoText" : "";
    String permissionText =
        (widget.permissionText != null) ? "\n\n${widget.permissionText}" : "";
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.mic_off_rounded, size: 128),
            Text(
              "Access to the ${widget.permissionName ?? widget.permission} denied. $permissionText $additionalInfoText",
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: OutlinedButton(
                onPressed: onButtonPressed,
                child: Text(buttonText),
              ),
            )
          ],
        ),
      ),
    );
  }
}
