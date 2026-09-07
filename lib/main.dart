import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'core/services/api_client.dart';
import 'core/services/referral_link_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/product_provider.dart';
import 'providers/category_provider.dart';
import 'providers/banner_provider.dart';
import 'providers/location_provider.dart';
import 'providers/order_provider.dart';
import 'providers/address_provider.dart';
import 'providers/delivery_provider.dart';
import 'routes/app_routes.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.init();
  // Initialize Cashfree payment gateway SDK (mobile only). On web the
  // cashfree.js script is loaded on demand, so no init is needed there.
  try {
    CFPaymentGatewayService();
  } catch (_) {}
  // A shared link is opened as a plain URL on the website, so read `?ref=` (and
  // any /product/<id>) from the address bar before the first frame. On
  // Android/iOS Uri.base is inert and the deep-link handler below does this.
  await ReferralLink.restore();
  final launchProductId = await ReferralLink.capture(Uri.base);
  final wishlistProvider = WishlistProvider();
  await wishlistProvider.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(GarmentEcommerceApp(
    wishlistProvider: wishlistProvider,
    launchProductId: launchProductId,
  ));
}

class GarmentEcommerceApp extends StatefulWidget {
  final WishlistProvider wishlistProvider;

  /// Product to open straight away, when the app was launched from a shared
  /// product link.
  final String? launchProductId;

  const GarmentEcommerceApp({
    super.key,
    required this.wishlistProvider,
    this.launchProductId,
  });

  @override
  State<GarmentEcommerceApp> createState() => _GarmentEcommerceAppState();
}

class _GarmentEcommerceAppState extends State<GarmentEcommerceApp> {
  String? _pendingProductId;
  String? _pendingRefCode;

  Future<void> _handleDeepLink() async {
    try {
      final initialUri = await _getInitialUri();
      if (initialUri != null) {
        await _parseAndNavigate(initialUri);
      }
    } catch (_) {}
  }

  Future<String?> _getInitialUri() async {
    // Returns the initial URI from the app launch
    // On Android/iOS, this comes from the platform channel
    try {
      const platform = MethodChannel('com.garment.ecommerce/deeplink');
      final uri = await platform.invokeMethod<String>('getInitialUri');
      return uri;
    } catch (_) {
      return null;
    }
  }

  Future<void> _parseAndNavigate(String uri) async {
    final uriParsed = Uri.tryParse(uri);
    if (uriParsed == null) return;
    // Remembers `?ref=` so it can be attached to a later registration, and
    // returns the shared product id.
    final productId = await ReferralLink.capture(uriParsed);
    if (productId == null || !mounted) return;
    setState(() {
      _pendingProductId = productId;
      _pendingRefCode = ReferralLink.pendingCode;
    });
  }

  @override
  void initState() {
    super.initState();
    _pendingProductId = widget.launchProductId;
    _pendingRefCode = ReferralLink.pendingCode;
    _handleDeepLink();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider.value(value: widget.wishlistProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()..load()),
      ],
      child: MaterialApp(
        title: 'Dristi Fashions',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: SplashScreen(
          pendingProductId: _pendingProductId,
          pendingRefCode: _pendingRefCode,
        ),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}


