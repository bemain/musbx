import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
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
class PermissionService {
  PermissionService._(this._androidDeviceInfo);

  /// Create the service.
  ///
  /// Reads the Android version once, since it decides which platform permission
  /// [Permission.audioFiles] maps to.
  static Future<PermissionService> create() async {
    return PermissionService._(
      Platform.isAndroid ? await DeviceInfoPlugin().androidInfo : null,
    );
  }

  // TODO: Remove once we introduce `provider`.
  static late final PermissionService instance;
  static Future<void> initialize() async {
    instance = await create();
  }

  final AndroidDeviceInfo? _androidDeviceInfo;

  /// Whether the current platform has no permissions for the app to query.
  /// Access is ungated there, so every permission is [PermissionStatus.unavailable].
  bool get _isUnavailable => Platform.isLinux || Platform.isMacOS;

  /// The current status of [permission], without prompting the user.
  ///
  /// On Android this never returns [PermissionStatus.permanentlyDenied]; the
  /// platform only reveals that in the result of a [request]. Callers that need
  /// to tell the two apart have to remember whether they have requested before.
  Future<PermissionStatus> status(Permission permission) async {
    if (_isUnavailable) return PermissionStatus.unavailable;
    return _fromPluginStatus(await _fromAppPermission(permission).status);
  }

  /// Ask the user to grant [permission], showing the system prompt, and return
  /// the resulting status.
  ///
  /// No prompt is shown if the permission is already granted or permanently
  /// denied, in which case the current status is returned unchanged.
  Future<PermissionStatus> request(Permission permission) async {
    if (_isUnavailable) return PermissionStatus.unavailable;
    return _fromPluginStatus(await _fromAppPermission(permission).request());
  }

  /// Opens the app settings page.
  ///
  /// Returns whether the app settings page could be opened.
  Future<bool> openSettings() async {
    if (_isUnavailable) return false;
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
