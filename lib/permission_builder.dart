import 'package:flutter/material.dart';
import 'package:musbx/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionBuilder extends StatefulWidget {
  /// Allow the user to grant or deny a [permission].
  /// If [permission] is granted, [onPermissionGranted] is called.
  const PermissionBuilder({
    super.key,
    required this.permission,
    required this.onPermissionGranted,
    String? permissionName,
    this.permissionText,
    this.permissionDeniedIcon,
    this.permissionGrantedIcon,
  }) : permissionName = permissionName ?? "$permission";

  /// The permission that needs to be granted before [onPermissionGranted] is called.
  final Permission permission;

  /// Called when [permission] has been granted.
  final void Function() onPermissionGranted;

  /// The name of this permission.
  final String permissionName;

  /// Short text describing why this permission is required.
  final String? permissionText;

  /// The widget displayed together with text and a request button when permission has been denied.
  final Widget? permissionDeniedIcon;

  /// The widget displayed when permission has been granted.
  final Widget? permissionGrantedIcon;

  @override
  State<StatefulWidget> createState() => PermissionBuilderState();
}

class PermissionBuilderState extends State<PermissionBuilder>
    with WidgetsBindingObserver {
  PermissionStatus? status;

  AppLifecycleState prevState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // [Permission.status] method is unable to return [PermissionStatus.permanentlyDenied]
    // (see https://github.com/Baseflow/flutter-permission-handler/issues/568)
    // Therefore, we can't just use [Permission.status] to check status, but need to make a full request.
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
    if (status == null) return const LoadingScreen(text: "");

    if (status == PermissionStatus.granted) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.onPermissionGranted());
      return InfoScreen(
        icon: widget.permissionGrantedIcon ?? const CircularProgressIndicator(),
        text: "Access to the ${widget.permissionName} granted.",
      );
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
            if (widget.permissionDeniedIcon != null)
              widget.permissionDeniedIcon!,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                "Access to the ${widget.permissionName} denied. $permissionText $additionalInfoText",
                textAlign: TextAlign.center,
              ),
            ),
            OutlinedButton(
              onPressed: onButtonPressed,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
