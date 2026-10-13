import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:musbx/data/repositories/metronome_repository.dart';
import 'package:musbx/data/repositories/notification/notification_repository.dart';
import 'package:musbx/data/repositories/settings_repository.dart';
import 'package:musbx/domain/models/notification.dart';
import 'package:musbx/routing/router.dart';
import 'package:musbx/routing/routes.dart';
import 'package:musbx/utils/result.dart';

class MetronomeNotificationAdapter {
  /// How long tempo changes have to settle before they are posted, since the
  /// system drops notification updates that arrive too quickly.
  static const Duration _postDelay = Duration(milliseconds: 300);

  MetronomeNotificationAdapter({
    required NotificationRepository notifications,
    required MetronomeRepository metronome,
    required SettingsRepository settings,
  }) : _notifications = notifications,
       _metronome = metronome,
       _settings = settings {
    // In case a notification is still present from the previous launch, kill it
    unawaited(notifications.cancel(NotificationChannel.metronomeControls));

    _lifecycleListener = AppLifecycleListener(
      onHide: () async {
        if (metronome.isPlaying) await _updateNotification();
      },
    );

    _actions = _notifications.actions
        .where(
          (action) => action.channel == NotificationChannel.metronomeControls,
        )
        .listen(_onAction);

    metronome.addListener(_onMetronomeChanged);
    settings.metronome.addListener(_onSettingsChanged);
    notifications.hasPermissionNotifier.addListener(_updateNotification);
  }

  final NotificationRepository _notifications;
  final MetronomeRepository _metronome;
  final SettingsRepository _settings;

  late final AppLifecycleListener _lifecycleListener;

  ({bool isPlaying, int bpm, int higher})? _postedState;
  ({bool isPlaying, int bpm, int higher}) get _currentState => (
    isPlaying: _metronome.isPlaying,
    bpm: _metronome.bpm,
    higher: _metronome.higher,
  );

  Timer? _postTimer;

  /// Post play and pause right away, and everything else once it settles.
  void _onMetronomeChanged() {
    _postTimer?.cancel();
    if (_currentState == _postedState) return;

    if (_currentState.isPlaying != _postedState?.isPlaying) {
      _updateNotification();
      return;
    }
    _postTimer = Timer(_postDelay, _updateNotification);
  }

  Future<void> _updateNotification() async {
    if (!_settings.metronome.showNotification) return;
    final state = _currentState;
    if (state == _postedState) return;

    // Shown only while playing, since on Android the notification keeps a
    // foreground service running, which a paused metronome has no use for.
    final result = state.isPlaying
        ? await _notifications.post(
            AppNotification(
              channel: NotificationChannel.metronomeControls,
              title: "Metronome",
              summary: "Playing",
              body:
                  "${state.higher} ${state.higher == 1 ? "beat" : "beats"} • ${state.bpm} bpm",
              actionSet: NotificationActionSet.metronomePlaying,
            ),
          )
        : await _notifications.cancel(NotificationChannel.metronomeControls);

    if (result is Ok) _postedState = state;
  }

  Future<void> _onSettingsChanged() async {
    if (_settings.metronome.showNotification) {
      await _updateNotification();
      return;
    }

    _postTimer?.cancel();
    _postedState = null;
    await _notifications.cancel(NotificationChannel.metronomeControls);
  }

  late final StreamSubscription<NotificationActionTapped> _actions;
  void _onAction(NotificationActionTapped tapped) {
    navigationShell.goBranch(Routes.branches.indexOf(Routes.metronome));
    switch (tapped.action) {
      case NotificationAction.pause:
        _metronome.pause();
      case null:
        break;
    }
  }

  Future<void> dispose() async {
    await _actions.cancel();
    _postTimer?.cancel();
    _metronome.removeListener(_onMetronomeChanged);
    _settings.metronome.removeListener(_onSettingsChanged);
    _notifications.hasPermissionNotifier.removeListener(_updateNotification);
    _lifecycleListener.dispose();
  }
}
