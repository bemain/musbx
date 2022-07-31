import 'dart:async';

import 'package:flutter/material.dart';

class ContinuousButton extends StatelessWidget {
  /// Button that can be held down to yield continuous presses.
  const ContinuousButton({
    super.key,
    required this.onPressed,
    this.interval = const Duration(milliseconds: 100),
    required this.child,
  });

  /// Callback for when this button is pressed.
  final void Function() onPressed;

  /// Interval between callbacks if the button is held pressed.
  final Duration interval;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    Timer timer = Timer(const Duration(), () {});
    return GestureDetector(
      onTap: onPressed,
      onLongPressStart: (LongPressStartDetails details) {
        timer = Timer.periodic(interval, (timer) => onPressed());
      },
      onLongPressUp: () {
        timer.cancel();
      },
      onLongPressCancel: () {
        timer.cancel();
      },
      child: child,
    );
  }
}

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key, required this.icon, required this.text})
      : super(key: key);

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[icon, Text(text)]));
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({Key? key, required this.text}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return InfoScreen(
      icon: const Icon(Icons.error),
      text: text,
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key, required this.text}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return InfoScreen(
      icon: const CircularProgressIndicator(),
      text: text,
    );
  }
}