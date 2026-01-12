import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path_provider/path_provider.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key, required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8.0,
          children: <Widget>[
            icon,
            Text(text),
          ],
        ),
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return InfoPage(
      icon: const Icon(Symbols.error_rounded),
      text: text,
    );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return InfoPage(
      icon: const CircularProgressIndicator(),
      text: text,
    );
  }
}

/// Whether the phone is connected to a mobile network.
Future<bool> isOnCellular() async {
  final connectivity = await (Connectivity().checkConnectivity());
  return !connectivity.contains(ConnectivityResult.wifi) &&
      !connectivity.contains(ConnectivityResult.ethernet);
}

class Directories {
  Directories._();

  static late final Directory _tempDir;

  static late final Directory _appDocsDir;

  /// Get a temporary directory with the given [name].
  ///
  /// This does not check to make sure that the directory actually exists.
  static Directory temporaryDir(String name) =>
      Directory("${_tempDir.path}/$name/");

  /// Get a application documents directory with the given [name].
  ///
  /// This does not check to make sure that the directory actually exists.
  static Directory applicationDocumentsDir(String name) =>
      Directory("${_appDocsDir.path}/$name/");

  /// Resolve the paths to commonly used locations on the filesystem, which are
  /// used by the methods provided by this class.
  ///
  /// Should be called during app launch.
  static Future<void> initialize() async {
    _tempDir = await getTemporaryDirectory();
    try {
      _appDocsDir = await getApplicationDocumentsDirectory();
    } catch (e) {
      debugPrint(
        "[DIRECTORIES] Unable to get application documents; falling back to temporary directory. $e",
      );
      _appDocsDir = _tempDir;
    }

    debugPrint(
      "[DIRECTORIES] Initialized with temporary directory at ${_tempDir.path}, application documents at ${_appDocsDir.path}",
    );
  }
}

class ExpandedIcon extends StatelessWidget {
  const ExpandedIcon(this.icon, {super.key, this.color, this.fill});

  final IconData? icon;
  final Color? color;
  final double? fill;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) => Icon(
        icon,
        size: constraint.biggest.shortestSide,
        color: color,
        fill: fill,
      ),
    );
  }
}

class SliderPlaceholder extends StatelessWidget {
  const SliderPlaceholder({super.key, this.trackHeight = 4});

  final double trackHeight;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: (48 - trackHeight) / 2),
          child: Center(
            child: Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: SizedBox(
                height: trackHeight,
                width: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
