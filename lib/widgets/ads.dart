import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  /// The AdMob ad unit to show.
  final String adUnitId = kDebugMode
      // Test banner ad units, provided by Google
      ? Platform.isAndroid
          ? "ca-app-pub-3940256099942544/6300978111"
          : "ca-app-pub-3940256099942544/2934735716"
      // Real ad units
      : Platform.isAndroid
          ? "ca-app-pub-5107868608906815/7921762904"
          : "ca-app-pub-5107868608906815/5487171252";

  AdSize? _adSize;

  /// The banner ad to show. This is `null` until the ad is actually loaded.
  BannerAd? _bannerAd;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
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
        width: _adSize?.width.toDouble(),
        height: _adSize?.height.toDouble() ?? 60,
      );
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  /// Load a banner ad.
  Future<void> _loadAd() async {
    try {
      _adSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          MediaQuery.of(context).size.width.truncate());
    } catch (e) {
      debugPrint("[ADS] Unable to get height of anchored banner: $e");
      return;
    }

    if (_adSize == null) {
      debugPrint("[ADS] Unable to get height of anchored banner.");
      return;
    }

    final bannerAd = BannerAd(
      size: _adSize!,
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[ADS] BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );

    // Start loading.
    await bannerAd.load();
  }
}

/// Load an interstitial ad.
Future<InterstitialAd?> loadInterstitialAd() async {
  /// The AdMob ad unit to show.
  final String adUnitId = kDebugMode
      // Test interstitial ad units, provided by Google
      ? Platform.isAndroid
          ? "ca-app-pub-3940256099942544/1033173712"
          : "ca-app-pub-3940256099942544/4411468910"
      // Real ad units
      : Platform.isAndroid
          ? "ca-app-pub-5107868608906815/5388751299"
          : "ca-app-pub-5107868608906815/3177520920";

  Completer<InterstitialAd?> completer = Completer();

  await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {},
            onAdImpression: (ad) {},
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint("[ADS] InterstitialAd failed to show: $error");
              ad.dispose();
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdClicked: (ad) {},
          );

          completer.complete(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint("[ADS] InterstitialAd failed to load: $error");
          completer.completeError(error);
        },
      ));

  return await completer.future;
}
