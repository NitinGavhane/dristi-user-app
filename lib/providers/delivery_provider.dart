import 'package:flutter/foundation.dart';
import '../core/services/delivery_api_service.dart';
import '../models/delivery_settings.dart';

/// The store's delivery policy, loaded once at startup.
///
/// Every place that shows a delivery promise or charge reads it from here, so
/// the storefront can never advertise free delivery after the seller sets a
/// charge in the Admin app.
class DeliveryProvider extends ChangeNotifier {
  DeliverySettings _settings = const DeliverySettings();
  bool _loaded = false;

  DeliverySettings get settings => _settings;

  /// False until the policy has been fetched. Until then the app shows the
  /// default (free) policy, which is what a brand-new store has.
  bool get loaded => _loaded;

  double feeFor(double subtotal, {String? state}) =>
      _settings.feeFor(subtotal, state: state);

  Future<void> load() async {
    try {
      _settings = await DeliveryApiService.getSettings();
      _loaded = true;
      notifyListeners();
    } catch (_) {
      // Keep the default (free) policy — a failed fetch must not block the UI.
    }
  }
}
