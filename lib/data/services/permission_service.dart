import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/domain/models/permission.dart';
import 'package:permission_handler/permission_handler.dart' as plugin;

/// Queries and requests the permissions the app needs from the operating system.
///
/// Translates between the platform's permission model and the app's:
/// [Permission] names a capability rather than a platform permission, and
/// [PermissionStatus] carries the same meaning everywhere, which the underlying
/// plugin's own status does not.
///
/// This is stateless. Whether a permission has ever been requested is app
/// history rather than platform state, and belongs to the layer above.
class PermissionService extends OptionalService {
  PermissionService._(this._androidDeviceInfo, {required this.isEnabled});

  /// Whether the current platform gates access behind permissions at all.
  ///
  /// When `false`, nothing is gated and every permission reports as
  /// [PermissionStatus.unavailable].
  @override
  final bool isEnabled;

  /// Information about the device, or `null` off Android and when this service
  /// is [disabled].
  final AndroidDeviceInfo? _androidDeviceInfo;

  /// Create the service.
  ///
  /// Returns a [disabled] service on platforms that have no permission model.
  /// Reads the Android version once, since it decides which platform permission
  /// [Permission.audioFiles] maps to.
  static Future<PermissionService> create() async {
    if (Platform.isLinux || Platform.isMacOS) return disabled();

    return PermissionService._(
      Platform.isAndroid ? await DeviceInfoPlugin().androidInfo : null,
      isEnabled: true,
    );
  }

  /// A service for platforms that gate nothing, where every permission reports
  /// as [PermissionStatus.unavailable].
  static PermissionService disabled() =>
      PermissionService._(null, isEnabled: false);

  // TODO: Remove once we introduce `provider`.
  static late final PermissionService instance;
  static Future<void> initialize() async {
    instance = await create();
  }

  /// The current status of [permission], without prompting the user.
  ///
  /// On Android this never returns [PermissionStatus.permanentlyDenied]; the
  /// platform only reveals that in the result of a [request]. Callers that need
  /// to tell the two apart have to remember whether they have requested before.
  ///
  /// Always [PermissionStatus.unavailable] when this service is [disabled].
  Future<PermissionStatus> status(Permission permission) async {
    if (!isEnabled) return PermissionStatus.unavailable;
    return _fromPluginStatus(await _fromAppPermission(permission).status);
  }

  /// Ask the user to grant [permission], showing the system prompt, and return
  /// the resulting status.
  ///
  /// No prompt is shown if the permission is already granted or permanently
  /// denied, in which case the current status is returned unchanged.
  ///
  /// Always [PermissionStatus.unavailable] when this service is [disabled].
  Future<PermissionStatus> request(Permission permission) async {
    if (!isEnabled) return PermissionStatus.unavailable;
    return _fromPluginStatus(await _fromAppPermission(permission).request());
  }

  /// Opens the app settings page, where the user can grant a permission the
  /// system will no longer prompt for.
  ///
  /// Returns whether the page could be opened, which is always `false` when
  /// this service is [disabled].
  Future<bool> openSettings() async {
    if (!isEnabled) return false;
    return plugin.openAppSettings();
  }

  /// Normalize a status reported by the plugin, whose values mean different
  /// things on different platforms.
  ///
  /// iOS reports a permission that has never been requested as `denied` and one
  /// the user actually refused as `permanentlyDenied`. Android reports both as
  /// `denied` and cannot distinguish them here at all.
  PermissionStatus _fromPluginStatus(plugin.PermissionStatus status) =>
      switch (status) {
        plugin.PermissionStatus.granted => PermissionStatus.granted,
        plugin.PermissionStatus.denied =>
          Platform.isIOS
              ? PermissionStatus.notDetermined
              : PermissionStatus.denied,
        plugin.PermissionStatus.permanentlyDenied =>
          PermissionStatus.permanentlyDenied,
        plugin.PermissionStatus.provisional => PermissionStatus.provisional,
        plugin.PermissionStatus.restricted => PermissionStatus.restricted,
        plugin.PermissionStatus.limited =>
          PermissionStatus.granted, // Only relevant for Photo Library picker.
      };

  /// The platform permission that [permission] requires.
  ///
  /// Android 13 replaced the single storage permission with granular media
  /// permissions, so reading audio needs a different one either side of that.
  plugin.Permission _fromAppPermission(Permission permission) =>
      switch (permission) {
        Permission.microphone => plugin.Permission.microphone,
        Permission.audioFiles =>
          Platform.isAndroid && _androidDeviceInfo!.version.sdkInt >= 33
              ? plugin.Permission.audio
              : plugin.Permission.storage,
        Permission.notifications => plugin.Permission.notification,
      };
}
