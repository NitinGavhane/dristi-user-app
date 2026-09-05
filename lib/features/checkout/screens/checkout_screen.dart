import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/web_content_frame.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/services/order_api_service.dart';
import '../../../core/services/payment_api_service.dart';
import '../../../core/services/payment_methods_api_service.dart';
import '../../../core/services/delivery_api_service.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/cashfree/cashfree_checkout.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/address_provider.dart';
import '../../../models/address.dart';
import '../../../models/payment_method.dart';
import '../../../models/delivery_settings.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Address? _selectedAddress;
  bool _isPlacing = false;
  bool _isProcessing = false;
  String? _error;
  final CashfreeCheckout _cashfree = CashfreeCheckout();

  List<PaymentMethod> _methods = [];
  PaymentMethod? _selectedMethod;
  bool _loadingMethods = true;
  String? _methodsError;

  DeliverySettings _delivery = const DeliverySettings();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _cashfree.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final addrProvider = context.read<AddressProvider>();
    await addrProvider.fetchAddresses();
    if (!mounted) return;
    setState(() {
      _selectedAddress = addrProvider.defaultAddress;
    });
    await _loadDeliverySettings();
    await _loadPaymentMethods();
  }

  Future<void> _loadDeliverySettings() async {
    try {
      final settings = await DeliveryApiService.getSettings();
      if (mounted) setState(() => _delivery = settings);
    } catch (_) {
      // Fall back to free delivery if the policy can't be loaded; the backend
      // stays authoritative for the amount actually charged.
    }
  }

  /// Payment methods depend on where the order is going, so they are reloaded
  /// whenever the delivery address changes.
  Future<void> _loadPaymentMethods() async {
    setState(() {
      _loadingMethods = true;
      _methodsError = null;
    });
    try {
      // The payment-methods endpoint requires a signed-in session, so retry the
      // request if the token is stale rather than blocking checkout forever.
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn) {
        await auth.checkAuth();
      }
      final region = _selectedAddress?.country ?? 'IN';
      final methods = await PaymentMethodsApiService.listPaymentMethods(region: region);
      if (!mounted) return;
      // Keep the buyer's choice if it is still offered here, else fall back to
      // the first (the Admin app's sort_order decides what that is).
      PaymentMethod? stillOffered;
      for (final m in methods) {
        if (m.code == _selectedMethod?.code) {
          stillOffered = m;
          break;
        }
      }
      setState(() {
        _methods = methods;
        _selectedMethod = stillOffered ?? (methods.isNotEmpty ? methods.first : null);
        _loadingMethods = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _methods = [];
        _selectedMethod = null;
        _loadingMethods = false;
        _methodsError = e.statusCode == 401
            ? 'Please sign in again to choose a payment method.'
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _methods = [];
        _selectedMethod = null;
        _loadingMethods = false;
        _methodsError = 'Could not load payment methods. Please retry.';
      });
    }
  }

  void _onAddressChanged(Address address) {
    final regionChanged = address.country != _selectedAddress?.country;
    setState(() => _selectedAddress = address);
    if (regionChanged) _loadPaymentMethods();
  }

  // Create the order, open a gateway order on the backend, then launch the
  // gateway checkout on the method the buyer picked. Verification happens in
  // _onPaymentSuccess; there is no client-generated transaction id.
  Future<void> _placeOrder() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (_selectedAddress == null) {
      setState(() => _error = 'Please set up a delivery address to continue.');
      return;
    }

    final method = _selectedMethod;
    if (method == null) {
      setState(() => _error = 'Please choose a payment method.');
      return;
    }

    setState(() {
      _isPlacing = true;
      _error = null;
    });

    try {
      final cart = context.read<CartProvider>();
      final items = cart.items.map((ci) => {
        'product_id': ci.product.id,
        'variant_id': null,
        'quantity': ci.quantity,
      }).toList();

      final orderResult = await OrderApiService.createOrder(
        shippingAddress: _selectedAddress?.toString() ?? '',
        shippingState: _selectedAddress?.state,
        items: items,
      );

      final orderId = orderResult['id'] as String;
      final amount = (orderResult['final_amount'] as num).toDouble();

      final payment = await PaymentApiService.createPayment(
        orderId: orderId,
        paymentMethod: method.code,
      );

      // Cash on Delivery: no gateway order is opened and nothing needs to be
      // verified, so the order is confirmed the moment it is created.
      if (payment['cod'] == true) {
        if (!mounted) return;
        setState(() {
          _isPlacing = false;
          _isProcessing = true;
        });
        _showSuccessDialog(
          orderId: orderId,
          amount: amount,
          methodLabel: 'Cash on Delivery',
        );
        return;
      }

      final paymentSessionId = payment['payment_session_id'] as String?;
      final cashfreeOrderId = payment['cashfree_order_id'] as String?;
      final cashfreeEnvironment = payment['cashfree_environment'] as String?;
      final returnUrl = payment['return_url'] as String?;

      if (!mounted) return;

      if (paymentSessionId == null ||
          paymentSessionId.isEmpty ||
          cashfreeOrderId == null ||
          cashfreeOrderId.isEmpty ||
          cashfreeEnvironment == null) {
        setState(() {
          _error = 'Payment gateway is not available right now. Please try again later.';
          _isPlacing = false;
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _isPlacing = false;
        _isProcessing = true;
      });

      _cashfree.open(
        CashfreeOptions(
          paymentSessionId: paymentSessionId,
          cashfreeOrderId: cashfreeOrderId,
          cashfreeEnvironment: cashfreeEnvironment,
          returnUrl: returnUrl,
        ),
        onSuccess: (result) => _onPaymentSuccess(orderId, amount, result),
        onError: _onPaymentError,
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isPlacing = false;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not start payment. Please try again.';
          _isPlacing = false;
          _isProcessing = false;
        });
      }
    }
  }

  /// Display name for a method code, using the configured names we already
  /// fetched. Falls back to the raw code so a method the buyer switched to
  /// inside the gateway sheet still reads sensibly.
  String _methodLabel(String? code) {
    if (code == null || code.isEmpty) return 'your payment method';
    for (final m in _methods) {
      if (m.code == code) return m.name;
    }
    return code.toUpperCase();
  }

  Future<void> _onPaymentSuccess(
      String orderId, double amount, CashfreeSuccess result) async {
    try {
      final verified = await PaymentApiService.verifyPayment(
        orderId: orderId,
        cashfreeOrderId: result.cashfreeOrderId,
      );
      if (!mounted) return;
      setState(() => _isProcessing = false);
      // The backend reports the method actually used, which can differ from the
      // one picked here if the buyer switched inside the gateway sheet.
      _showSuccessDialog(
        orderId: orderId,
        amount: amount,
        methodLabel: _methodLabel(verified['payment_method'] as String?),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isProcessing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Payment verification failed. If you were charged, contact support.';
          _isProcessing = false;
        });
      }
    }
  }

  void _onPaymentError(String message) {
    if (!mounted) return;
    setState(() {
      _isPlacing = false;
      _isProcessing = false;
      _error = message;
    });
  }

  void _showSuccessDialog({
    required String orderId,
    required double amount,
    required String methodLabel,
  }) {
    final cart = context.read<CartProvider>();
    cart.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.success, size: 28),
              ),
              const SizedBox(height: AppDimensions.md),
              Text('Payment Successful!', style: AppTextStyles.headline3),
              const SizedBox(height: AppDimensions.sm),
              Text(
                '₹${amount.toStringAsFixed(2)} paid via $methodLabel',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.xl),
              AppButton(
                label: 'View Order',
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamedAndRemoveUntil(context, '/orders', (_) => false);
                },
              ),
              const SizedBox(height: AppDimensions.sm),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
                },
                child: Text(
                  'Continue Shopping',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The payment methods the buyer can choose from, as configured in the Admin
  /// app and filtered to their delivery region. Which gateway settles any of
  /// them is never surfaced here.
  Widget _paymentMethods() {
    if (_loadingMethods) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: const Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_methodsError != null || _methods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.info_circle, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _methodsError ??
                    'No payment methods are available for this delivery address.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ),
            if (_methodsError != null)
              TextButton(onPressed: _loadPaymentMethods, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final method in _methods) ...[
          _paymentMethodTile(method),
          if (method != _methods.last) const SizedBox(height: AppDimensions.sm),
        ],
      ],
    );
  }

  Widget _paymentMethodTile(PaymentMethod method) {
    final selected = _selectedMethod?.code == method.code;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surface,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            _methodIcon(method, selected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (method.description != null && method.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(method.description!, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodIcon(PaymentMethod method, bool selected) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    final url = method.iconUrl;
    if (url != null && url.isNotEmpty) {
      // An admin-supplied icon; fall back to the built-in one if it won't load.
      return Image.network(
        url,
        width: 24, height: 24,
        errorBuilder: (_, __, ___) => Icon(method.fallbackIcon, size: 24, color: color),
      );
    }
    return Icon(method.fallbackIcon, size: 24, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final subtotal = cart.subtotal;
    // Flat 18% GST plus the configured delivery fee — matches the backend's
    // final_amount so the "Pay ₹…" button shows exactly what the order will be
    // charged.
    final gst = subtotal * 0.18;
    // Delivery is priced by the destination state (falls back to the default
    // fee while no address is picked yet), matching the backend's charge.
    final deliveryFee = _delivery.feeFor(subtotal, state: _selectedAddress?.state);
    final total = subtotal + gst + deliveryFee;
    final addresses = context.watch<AddressProvider>().addresses;

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout', style: AppTextStyles.title),
      ),
      body: WebContentFrame(
        child: ListView(
        padding: const EdgeInsets.all(AppDimensions.md),
        children: [
          _sectionHeader('Delivery Address', Iconsax.location),
          const SizedBox(height: AppDimensions.sm),
          if (_selectedAddress != null)
            GestureDetector(
              onTap: () => _showAddressPicker(context, addresses),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Iconsax.home,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedAddress!.fullName} • ${_selectedAddress!.type}',
                            style: AppTextStyles.subtitle.copyWith(
                              fontWeight: FontWeight.w500, fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_selectedAddress!.street}, ${_selectedAddress!.city}, ${_selectedAddress!.state} - ${_selectedAddress!.pincode}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary, fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textHint, size: 20),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _openAddressSetup(context, addresses),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Iconsax.add_circle,
                          color: AppColors.warning, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Delivery Address',
                            style: AppTextStyles.subtitle.copyWith(
                              fontWeight: FontWeight.w600, fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You need a delivery address to place this order.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary, fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.warning, size: 20),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppDimensions.lg),
          _sectionHeader('Payment Methods', Iconsax.wallet),
          const SizedBox(height: AppDimensions.sm),
          _paymentMethods(),
          const SizedBox(height: AppDimensions.lg),
          _sectionHeader('Order Summary', Iconsax.receipt),
          const SizedBox(height: AppDimensions.sm),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Column(
              children: [
                ...cart.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: item.product.gradientColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.checkroom_rounded,
                                  size: 22,
                                  color: AppColors.white.withValues(alpha: 0.5)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.title,
                                      style: AppTextStyles.bodySmall
                                          .copyWith(fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                    'Qty: ${item.quantity} • ${item.selectedSize} • ${item.selectedColor}',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                context.read<CartProvider>().removeItem(index);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Iconsax.trash,
                                    size: 16, color: AppColors.error),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('₹${item.totalPrice.toStringAsFixed(2)}',
                                style: AppTextStyles.priceSmall),
                          ],
                        ),
                      );
                    }),
                const Divider(),
                _summaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                _summaryRow('GST (18%)', '₹${gst.toStringAsFixed(2)}'),
                _summaryRow('Delivery',
                    deliveryFee > 0 ? '₹${deliveryFee.toStringAsFixed(2)}' : 'FREE'),
                const Divider(color: AppColors.brandGold, thickness: 1),
                _summaryRow('Total', '₹${total.toStringAsFixed(2)}',
                    isTotal: true),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          const SizedBox(height: AppDimensions.xl),
          Consumer<AuthProvider>(
            builder: (_, auth, __) {
              if (!auth.isLoggedIn) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Iconsax.info_circle,
                              color: AppColors.warning, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Please sign in to place your order',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    AppButton(
                      label: 'Sign In to Continue',
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                    ),
                  ],
                );
              }
              return AppButton(
                label: 'Pay ₹${total.toStringAsFixed(2)}',
                onPressed: _placeOrder,
                isLoading: _isPlacing || _isProcessing,
              );
            },
          ),
          const SizedBox(height: AppDimensions.lg),
        ],
        ),
      ),
    );
  }

  void _openAddressSetup(BuildContext context, List<Address> addresses) {
    if (addresses.isEmpty) {
      _openNewAddress();
      return;
    }
    _showAddressPicker(context, addresses);
  }

  Future<void> _openNewAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _NewAddressScreen()),
    );
    if (!mounted) return;
    final provider = context.read<AddressProvider>();
    await provider.fetchAddresses();
    if (!mounted) return;
    final updated = provider.addresses;
    if (updated.isNotEmpty && _selectedAddress == null) {
      setState(() => _selectedAddress = updated.first);
      await _loadPaymentMethods();
    }
  }

  void _showAddressPicker(BuildContext context, List<Address> addresses) {
    if (addresses.isEmpty) {
      _openNewAddress();
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Address', style: AppTextStyles.title),
            const SizedBox(height: AppDimensions.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: addresses
                      .map((a) => RadioListTile<Address>(
                            value: a,
                            groupValue: _selectedAddress,
                            onChanged: (v) {
                              _onAddressChanged(v!);
                              Navigator.pop(ctx);
                            },
                            title: Text('${a.fullName} • ${a.type}',
                                style: AppTextStyles.subtitle),
                            subtitle: Text(
                                '${a.street}, ${a.city} - ${a.pincode}',
                                style: AppTextStyles.caption),
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _NewAddressScreen(),
                  ),
                );
              },
              icon: const Icon(Iconsax.add, size: 18),
              label: const Text('Add New Address'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textPrimary),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.subtitle),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: isTotal ? AppTextStyles.title : AppTextStyles.bodySmall),
          Text(value,
              style: isTotal
                  ? AppTextStyles.headline3.copyWith(
                      color: AppColors.brandGold, fontSize: 18)
                  : AppTextStyles.body),
        ],
      ),
    );
  }
}

class _NewAddressScreen extends StatefulWidget {
  const _NewAddressScreen();

  @override
  State<_NewAddressScreen> createState() => _NewAddressScreenState();
}

class _NewAddressScreenState extends State<_NewAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AddressProvider>();
    final success = await provider.createAddress(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address added')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddressProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('New Address', style: AppTextStyles.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _nameController,
                labelText: 'Full Name',
                hintText: 'Enter full name',
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppDimensions.md),
              AppTextField(
                controller: _phoneController,
                labelText: 'Phone',
                hintText: 'Enter phone',
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppDimensions.md),
              AppTextField(
                controller: _streetController,
                labelText: 'Street',
                hintText: 'Enter street',
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppDimensions.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _cityController,
                      labelText: 'City',
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _stateController,
                      labelText: 'State',
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              AppTextField(
                controller: _pincodeController,
                labelText: 'Pincode',
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppDimensions.xxl),
              AppButton(
                label: 'Save',
                onPressed: _save,
                isLoading: provider.isLoading,
              ),
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(provider.error!, style: const TextStyle(color: AppColors.error)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

