import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:musbx/data/services/service.dart';

/// Identifies a single ad placement registered with AdMob.
typedef _AdUnitId = String;

/// The ad units that ads are loaded from.
///
/// Debug builds use Google's dedicated test units, because requesting
/// production ads during development counts as invalid traffic and can get the
/// AdMob account suspended.
class _AdUnits {
  final _AdUnitId interstitial;

  final _AdUnitId banner;

  _AdUnits.debugAndroid()
    : interstitial = "ca-app-pub-3940256099942544/1033173712",
      banner = "ca-app-pub-3940256099942544/9214589741";

  _AdUnits.debugIOS()
    : interstitial = "ca-app-pub-3940256099942544/4411468910",
      banner = "ca-app-pub-3940256099942544/2435281174";

  _AdUnits.productionAndroid()
    : interstitial = "ca-app-pub-5107868608906815/5388751299",
      banner = "ca-app-pub-5107868608906815/7921762904";

  _AdUnits.productionIOS()
    : interstitial = "ca-app-pub-5107868608906815/3177520920",
      banner = "ca-app-pub-5107868608906815/5487171252";

  factory _AdUnits.forPlatform(String platform) => switch (platform) {
    "android" =>
      kDebugMode ? _AdUnits.debugAndroid() : _AdUnits.productionAndroid(),
    "ios" => kDebugMode ? _AdUnits.debugIOS() : _AdUnits.productionIOS(),
    _ => throw UnsupportedError("Ads are not supported for this platform."),
  };
}

/// Loads the ads shown to users without premium.
///
/// Ads are optional. [disabled] returns a service that loads nothing, so a
/// platform without an ad SDK behaves like a user who has paid to remove ads.
class AdService extends OptionalService {
  AdService._(this._adUnits);

  @override
  bool get isEnabled => _adUnits != null;

  /// The ad units to load from, or `null` when this service is disabled.
  final _AdUnits? _adUnits;

  /// Create the service, initializing the ad SDK.
  ///
  /// Returns a [disabled] service on platforms that have no ad SDK. Throws if
  /// the SDK is available but fails to initialize; since ads are optional,
  /// callers should fall back to [disabled] rather than propagate that.
  static Future<AdService> create() async {
    if (!Platform.isAndroid && !Platform.isIOS) return disabled();

    await MobileAds.instance.initialize();

    return AdService._(_AdUnits.forPlatform(Platform.operatingSystem));
  }

  /// A service that loads no ads, for when ads are unavailable or switched off.
  static AdService disabled() => AdService._(null);

  // TODO: Remove once we introduce `provider`.
  static late final AdService instance;
  static Future<void> initialize() async {
    try {
      instance = await create();
    } catch (error) {
      debugPrint("[ADS] Disabled, initialization failed: $error");
      instance = disabled();
    }
  }

  /// Show a full-screen ad, and wait until the user dismisses it.
  ///
  /// Returns whether an ad was shown. This is `false` when the service is
  /// disabled, when no ad could be loaded, and when the ad failed to appear —
  /// all of which are routine, so callers should carry on rather than retry.
  Future<bool> showInterstitial() async {
    final ad = await _loadInterstitial();
    if (ad == null) return false;

    final dismissed = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {},
      onAdImpression: (ad) {},
      onAdClicked: (ad) {},
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint("[ADS] InterstitialAd failed to show: $error");
        ad.dispose();
        dismissed.complete(false);
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        dismissed.complete(true);
      },
    );

    try {
      await ad.show();
    } catch (error) {
      debugPrint("[ADS] InterstitialAd failed to show: $error");
      await ad.dispose();
      return false;
    }

    return dismissed.future;
  }

  /// Load an interstitial ad, ready to be shown.
  ///
  /// Returns `null` when this service is disabled or no ad could be loaded,
  /// which happens whenever AdMob has nothing to fill the request with.
  ///
  /// The returned ad holds native resources and nothing disposes it, so the
  /// caller has to, whether or not it ends up being shown.
  Future<InterstitialAd?> _loadInterstitial() async {
    if (_adUnits == null) return null;

    Completer<InterstitialAd?> completer = Completer();

    try {
      await InterstitialAd.load(
        adUnitId: _adUnits.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => completer.complete(ad),
          onAdFailedToLoad: (error) {
            debugPrint("[ADS] InterstitialAd failed to load: $error");
            completer.complete(null);
          },
        ),
      );
    } catch (error) {
      debugPrint("[ADS] Unable to request an InterstitialAd: $error");
      return null;
    }

    return await completer.future;
  }

  /// Load a banner ad sized for a slot [width] pixels wide.
  ///
  /// Returns `null` when this service is disabled, when the size cannot be
  /// resolved for the current screen, or when no ad could be loaded.
  ///
  /// The returned ad holds native resources for as long as it is displayed, so
  /// the caller must dispose it once it stops being shown.
  Future<BannerAd?> loadBanner({required int width}) async {
    if (_adUnits == null) return null;

    final AdSize? size;
    try {
      size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    } catch (error) {
      debugPrint("[ADS] Unable to size anchored banner: $error");
      return null;
    }
    if (size == null) return null;

    final completer = Completer<BannerAd?>();
    final ad = BannerAd(
      size: size,
      adUnitId: _adUnits.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => completer.complete(ad as BannerAd),
        onAdFailedToLoad: (ad, error) {
          debugPrint("[ADS] BannerAd failed to load: $error");
          ad.dispose();
          completer.complete(null);
        },
      ),
    );
    try {
      await ad.load();
    } catch (error) {
      debugPrint("[ADS] Unable to request a BannerAd: $error");
      await ad.dispose();
      return null;
    }

    return completer.future;
  }
}
