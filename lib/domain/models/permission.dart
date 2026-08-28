/// The state of an [Permission], with the same meaning on every platform.
enum PermissionStatus {
  /// The permission has never been requested, so the system prompt has not been
  /// shown yet.
  ///
  /// Only reported on iOS. Android cannot tell this apart from [denied].
  notDetermined,

  /// The permission is not applicable on the current platform.
  unavailable,

  /// The user granted access to the requested feature.
  granted,

  /// The app may post non-interruptive notifications without having been
  /// granted permission. iOS only.
  provisional,

  /// The user denied access to the requested feature, but the system prompt can
  /// be shown again.
  denied,

  /// The user denied access to the requested feature and the system prompt will
  /// no longer be shown. Only the system settings can change this.
  permanentlyDenied,

  /// The operating system denied access to the requested feature and the user
  /// cannot grant it, for example due to parental controls. iOS only.
  restricted,
}

/// A capability the app needs to request permission to use.
enum Permission {
  /// Record audio, for the tuner.
  microphone,

  /// Read audio files from the device, for uploading songs.
  audioFiles,

  /// Post notifications, for controlling the metronome from the drawer.
  notifications,
}
