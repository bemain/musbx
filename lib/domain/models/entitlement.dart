/// Something the user can unlock by paying for it.
enum Entitlement {
  /// Unlocks the premium features of the app.
  premium,
}

/// Whether the user has access to an [Entitlement].
enum EntitlementStatus {
  /// The user has not paid for this and has no access.
  notPurchased,

  /// Payment has been submitted but the store has not confirmed it yet. Access
  /// is not granted until it does.
  pending,

  /// The user has paid for this and has access.
  purchased,
}

/// How an [Entitlement] is presented to the user, as described by the store the
/// app was installed from.
///
/// The store owns this text so that it arrives translated, and priced in the
/// currency of the user's region.
class EntitlementDetails {
  EntitlementDetails({
    required this.entitlement,
    required this.title,
    required this.description,
    required this.price,
  });

  /// The entitlement this describes.
  final Entitlement entitlement;

  /// The name of the entitlement, as it appears in the store.
  final String title;

  /// The store's description of what the entitlement unlocks.
  final String description;

  /// The cost, formatted for the user's region.
  final String price;
}
