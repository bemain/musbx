import 'package:flutter/material.dart';
import 'package:musbx/data/services/permission_service.dart';
import 'package:musbx/domain/models/permission.dart';
import 'package:musbx/widgets/widgets.dart';

/// Gates a feature behind a [Permission], showing the user what is missing and
/// how to grant it.
///
/// Calls [onPermissionGranted] once the permission is available — either
/// because the user granted it, or because the platform does not gate it at all.
/// Rechecks whenever the app is resumed, so granting from the system settings
/// takes effect without a restart.
class PermissionBuilder extends StatefulWidget {
  const PermissionBuilder({
    super.key,
    required this.permission,
    required this.onPermissionGranted,
    this.permissionName,
    this.permissionText,
    this.permissionDeniedIcon,
    this.permissionGrantedIcon,
    this.initialRequest = true,
  });

  /// The permission that needs to be granted before [onPermissionGranted] is called.
  final Permission permission;

  /// Called once [permission] becomes available, whether because the user
  /// granted it or because the current platform does not gate it.
  ///
  /// Called at most once per granting; rebuilds do not call it again.
  final void Function() onPermissionGranted;

  /// What to call this permission when addressing the user, interpolated into
  /// sentences such as "Access to the microphone denied."
  ///
  /// Defaults to the name of the [permission] itself, so pass something
  /// readable for any permission whose name is not already a noun phrase.
  final String? permissionName;

  /// Short text describing why this permission is required.
  final String? permissionText;

  /// The widget displayed above the text when the permission is unavailable.
  final Widget? permissionDeniedIcon;

  /// The widget displayed once the permission is available.
  final Widget? permissionGrantedIcon;

  /// Whether to request permission when this is initialized.
  /// Otherwise, the request is made when the user presses the request button.
  final bool initialRequest;

  @override
  State<StatefulWidget> createState() => PermissionBuilderState();
}

class PermissionBuilderState extends State<PermissionBuilder>
    with WidgetsBindingObserver {
  /// The user-facing name of the permission being requested.
  String get permissionName => widget.permissionName ?? widget.permission.name;

  /// The most recently observed status, or `null` before the first check.
  PermissionStatus? _status;

  /// The previous lifecycle state, used to detect that the app was resumed.
  AppLifecycleState _prevState = AppLifecycleState.resumed;

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
        _prevState != AppLifecycleState.resumed) {
      checkPermissionStatus();
    }
    _prevState = state;
  }

  @override
  Widget build(BuildContext context) {
    if (_status == null) return const LoadingPage(text: "");

    if (_status == PermissionStatus.granted) {
      return InfoPage(
        icon:
            widget.permissionGrantedIcon ?? const CircularProgressIndicator(),
        text: "Access to the $permissionName granted.",
      );
    }

    if (_status == PermissionStatus.unavailable) {
      return InfoPage(
        icon:
            widget.permissionGrantedIcon ?? const CircularProgressIndicator(),
        text:
            "Access to the $permissionName is always granted on this platform.",
      );
    }

    if (_status == PermissionStatus.restricted) {
      return buildPermissionDeniedPage(
        additionalInfoText:
            "Permission cannot be granted, for example due to parental controls.",
      );
    }

    if (_status == PermissionStatus.permanentlyDenied) {
      return buildPermissionDeniedPage(
        additionalInfoText:
            "You need to give this permission from the System Settings.",
        buttonText: "Open Settings",
        onButtonPressed: PermissionService.instance.openSettings,
      );
    }

    return buildPermissionDeniedPage(
      buttonText: "Request permission",
      onButtonPressed: requestPermission,
    );
  }

  /// Record [status] and notify the widget if the permission just became
  /// available.
  ///
  /// The notification is tied to the transition rather than to [build], so a
  /// rebuild while the permission is available does not call
  /// [PermissionBuilder.onPermissionGranted] a second time.
  void _setStatus(PermissionStatus status) {
    if (!mounted) return;
    final wasSatisfied = _isSatisfied(_status);
    setState(() => _status = status);
    if (!wasSatisfied && _isSatisfied(status)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onPermissionGranted(),
      );
    }
  }

  /// Whether [status] means the app may use the feature: either the user
  /// granted the permission, or the platform never gated it.
  static bool _isSatisfied(PermissionStatus? status) =>
      status == PermissionStatus.granted ||
      status == PermissionStatus.unavailable;

  /// Re-read the current status without prompting the user.
  Future<void> checkPermissionStatus() async {
    var status = await PermissionService.instance.status(widget.permission);

    // On Android, `PermissionService.status` cannot report permanentlyDenied;
    // only a request can (https://github.com/Baseflow/flutter-permission-handler/issues/568).
    // Without this guard, returning from the system settings would downgrade
    // the status to denied and replace the "Open Settings" button with a
    // "Request permission" button that the OS silently ignores.
    if (_status == PermissionStatus.permanentlyDenied &&
        status == PermissionStatus.denied) {
      return;
    }

    _setStatus(status);
  }

  /// Ask the user to grant the permission, showing the system prompt.
  Future<void> requestPermission() async {
    var status = await PermissionService.instance.request(widget.permission);
    _setStatus(status);
  }

  /// Build the page shown while the permission is unavailable.
  ///
  /// The button is omitted when [buttonText] is `null`, for the cases where the
  /// user has no way to grant the permission.
  Widget buildPermissionDeniedPage({
    String? additionalInfoText,
    String? buttonText,
    void Function()? onButtonPressed,
  }) {
    additionalInfoText = (additionalInfoText != null)
        ? "\n\n$additionalInfoText"
        : "";
    String permissionText = (widget.permissionText != null)
        ? "\n\n${widget.permissionText}"
        : "";
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
                "Access to the $permissionName denied. $permissionText $additionalInfoText",
                textAlign: TextAlign.center,
              ),
            ),
            if (buttonText != null)
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
