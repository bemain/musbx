import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:musbx/data/services/ad_service.dart';
import 'package:provider/provider.dart';

/// A banner ad sized to the width it is given. Takes up no space until an ad has
/// loaded, and none at all if none can be.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

/// The banner ad to show. This is `null` until the ad is actually loaded.
class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd(MediaQuery.of(context).size.width.truncate());
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null) {
      return SizedBox(
        height: 60,
      );
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  /// Load a banner ad.
  Future<void> _loadAd(int width) async {
    final ad = await context.read<AdService>().loadBanner(width: width);
    if (!mounted) {
      await ad.dispose();
      return;
    }
    setState(() => _bannerAd = ad);
  }
}
