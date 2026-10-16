import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';

/// An icon above a line of text, centred in the space it is given.
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

/// An [InfoPage] reporting that something went wrong.
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

/// An [InfoPage] shown while something is still loading.
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

/// An icon sized to fill whatever space it is given.
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

/// A shimmering stand-in for a slider whose value is not known yet.
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

/// Show a snack bar with an optional [leading] icon before the [title].
void showAlertSnackBar(
  BuildContext context, {
  Key? key,
  Widget? leading,
  required Widget title,
}) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(
    SnackBar(
      key: key,
      showCloseIcon: true,
      content: Row(
        children: [
          if (leading != null) ...[
            IconTheme(
              data: IconThemeData(
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
              child: leading,
            ),
            SizedBox(width: 12),
          ],
          title,
        ],
      ),
    ),
  );
}
