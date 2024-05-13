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
    this.initialRequest = true,
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

  /// Whether to request permission when this is initialized.
  /// Otherwise, the request is made when the user presses the request button.
  final bool initialRequest;

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

    if (widget.initialRequest) {
      requestPermission();
    } else {
      checkPermissionStatus();
    }
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
      checkPermissionStatus();
    }
    prevState = state;
  }

  @override
  Widget build(BuildContext context) {
    if (status == null) return const LoadingPage(text: "");

    if (status == PermissionStatus.granted) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.onPermissionGranted());
      return InfoPage(
        icon: widget.permissionGrantedIcon ?? const CircularProgressIndicator(),
        text: "Access to the ${widget.permissionName} granted.",
      );
    }

    if (status == PermissionStatus.permanentlyDenied) {
      return buildPermissionDeniedPage(
        additionalInfoText:
            "You need to give this permission from the System Settings.",
        buttonText: "Open Settings",
        onButtonPressed: openAppSettings,
      );
    }

    return buildPermissionDeniedPage(
      buttonText: "Request permission",
      onButtonPressed: requestPermission,
    );
  }

  Future<void> checkPermissionStatus() async {
    // [Permission.status] is unable to return [PermissionStatus.permanentlyDenied]
    // (see https://github.com/Baseflow/flutter-permission-handler/issues/568)
    // Therefore, this won't return status correctly, but it still works fine.
    var status = await widget.permission.status;
    if (mounted) {
      setState(() {
        this.status = status;
      });
    }
  }

  Future<void> requestPermission() async {
    var status = await widget.permission.request();
    if (mounted) {
      setState(() {
        this.status = status;
      });
    }
  }

  Widget buildPermissionDeniedPage({
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
