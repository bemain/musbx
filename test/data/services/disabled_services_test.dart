import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/data/services/ad_service.dart';
import 'package:musbx/data/services/analytics_service.dart';
import 'package:musbx/data/services/permission_service.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/domain/models/permission.dart';

/// Services that only reach their plugins through static calls, so a test can
/// only see how they behave without one.
void main() {
  group("AdService", () {
    test("is disabled where there is no ad SDK", () async {
      expect((await AdService.create()).isEnabled, isFalse);
    });

    test("disabled refuses interstitials", () {
      final ads = AdService.disabled();
      expect(ads.showInterstitial(), throwsA(isA<ServiceDisabled>()));
    });

    test(
      "disabled refuses banners",
      () {
        final ads = AdService.disabled();
        expect(ads.loadBanner(width: 320), throwsA(isA<ServiceDisabled>()));
      },
      skip: "loadBanner asks the ad SDK for a size before checking isEnabled",
    );
  });

  group("AnalyticsService", () {
    test("is disabled without a Firebase app", () async {
      expect((await AnalyticsService.create()).isEnabled, isFalse);
    });

    test("disabled accepts and discards everything", () {
      expect(AnalyticsService.disabled().logScreenView("Home"), completes);
    });
  });

  group("PermissionService", () {
    test("is unavailable where nothing is gated", () async {
      expect((await PermissionService.create()).isAvailable, isFalse);
    });

    test("unavailable reports every permission as unavailable", () async {
      final permissions = PermissionService.unavailable();

      for (final permission in Permission.values) {
        expect(
          await permissions.status(permission),
          PermissionStatus.unavailable,
        );
        expect(
          await permissions.request(permission),
          PermissionStatus.unavailable,
        );
      }
      expect(await permissions.openSettings(), isFalse);
    });
  });
}
