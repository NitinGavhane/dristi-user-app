class DeliverySettings {
  final bool enabled;
  final double fee;
  final Map<String, double>? stateFees;
  final double? freeAbove;

  const DeliverySettings({
    this.enabled = false,
    this.fee = 0.0,
    this.stateFees,
    this.freeAbove,
  });

  factory DeliverySettings.fromJson(Map<String, dynamic> json) {
    final rawFees = json['state_fees'];
    Map<String, double>? fees;
    if (rawFees is Map<String, dynamic>) {
      fees = rawFees.map(
          (k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0.0));
    }
    return DeliverySettings(
      enabled: json['enabled'] as bool? ?? false,
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      stateFees: fees,
      freeAbove: (json['free_above'] as num?)?.toDouble(),
    );
  }

  /// Fee for a parcel going to [state]. A state-specific entry wins; otherwise
  /// (or when the state is blank/unknown) the default [fee] applies. Mirrors
  /// the backend's `delivery_service.fee_for_state` so the checkout total
  /// matches what the order is charged — same name normalisation, same fallback.
  double feeForState(String? state) {
    if (state == null || state.trim().isEmpty) return fee;
    final normalized = _normalise(state);
    final fees = stateFees ?? const {};
    for (final entry in fees.entries) {
      if (_normalise(entry.key) == normalized) return entry.value;
    }
    return fee;
  }

  /// Delivery charge for an order with this [subtotal] going to [state].
  /// Mirrors the backend rule so the checkout total matches what is charged.
  double feeFor(double subtotal, {String? state}) {
    if (!enabled || fee <= 0) return 0.0;
    if (freeAbove != null && subtotal >= freeAbove!) return 0.0;
    return feeForState(state);
  }

  /// True when delivery is free for every order (no charge configured).
  bool get isAlwaysFree => !enabled || fee <= 0;

  /// The lowest delivery charge a shopper could pay, for "starts from" labels.
  double get minimumFee {
    var min = fee;
    for (final value in (stateFees ?? const {}).values) {
      if (value < min) min = value;
    }
    return min;
  }

  /// Whether the store prices delivery by state rather than one flat rate.
  bool get hasStateFees =>
      stateFees != null && stateFees!.isNotEmpty;

  /// Short label for a product-page chip.
  String get chipLabel {
    if (isAlwaysFree) return 'Free Delivery';
    if (freeAbove != null) return 'Free Delivery over ₹${_amount(freeAbove!)}';
    if (hasStateFees) return 'Delivery from ₹${_amount(minimumFee)}';
    return 'Delivery ₹${_amount(fee)}';
  }

  /// Headline for the site announcement bar and assurance strips.
  String get promoLine {
    if (isAlwaysFree) return 'FREE SHIPPING ON ALL ORDERS';
    if (freeAbove != null) {
      return 'FREE SHIPPING ON ORDERS OVER ₹${_amount(freeAbove!)}';
    }
    if (hasStateFees) {
      return 'STATE-WISE DELIVERY FROM ₹${_amount(minimumFee)}';
    }
    return 'FLAT ₹${_amount(fee)} DELIVERY ON ALL ORDERS';
  }

  /// Sentence form of [promoLine], for trust badges that read as prose.
  String get promoSentence {
    if (isAlwaysFree) return 'Free shipping on every order';
    if (freeAbove != null) {
      return 'Free shipping on orders over ₹${_amount(freeAbove!)}';
    }
    if (hasStateFees) {
      return 'Delivery charged by state, from ₹${_amount(minimumFee)}';
    }
    return 'Flat ₹${_amount(fee)} delivery charge';
  }

  /// "West Bengal", "west bengal", "  WEST   BENGAL ", or "Jammu & Kashmir"
  /// all map to their canonical key, so an address typed by hand still finds
  /// its state fee. Identical logic to the backend's lookup.
  static String _normalise(String value) =>
      value
          .trim()
          .replaceAll(' & ', ' and ')
          .split(RegExp(r'\s+'))
          .map((w) {
            if (w.isEmpty) return w;
            return w[0].toUpperCase() + w.substring(1).toLowerCase();
          })
          .join(' ');

  /// Drops the decimals on whole amounts — "₹200", not "₹200.00".
  static String _amount(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}