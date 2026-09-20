import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/services/referral_link_service.dart';
import '../../../models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/delivery_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../widgets/product_video_player.dart';
import '../../checkout/screens/checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _fullProduct;
  bool _isLoadingDetail = true;
  String _selectedSize = '';
  String _selectedColor = '';
  final int _quantity = 1;
  final PageController _galleryController = PageController();
  int _currentImage = 0;

  Product get _product => _fullProduct ?? widget.product;

  /// The photos to show in the header gallery, primary first, with a graceful
  /// fall back to the single list-view image while the detail is still loading.
  List<String> get _galleryImages {
    if (_product.images.isNotEmpty) return _product.images;
    if (_product.imageUrl.isNotEmpty) return [_product.imageUrl];
    return const [];
  }

  /// The product's video, shown as the last slide of the header gallery (a
  /// product has at most one). Null when the product has none.
  ProductVideo? get _galleryVideo =>
      _product.videos.isNotEmpty ? _product.videos.first : null;

  /// Delivery chip text reflecting the store's actual policy, rather than a
  /// hardcoded "Free Delivery".
  String get _deliveryLabel =>
      context.watch<DeliveryProvider>().settings.chipLabel;

  bool get _isWishlisted =>
      context.watch<WishlistProvider>().isWishlisted(_product.id);

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.product.sizes.isNotEmpty ? widget.product.sizes.first : '';
    _selectedColor = widget.product.colors.isNotEmpty ? widget.product.colors.first : '';
    _fetchDetail();
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    try {
      final detail = await context.read<ProductProvider>().fetchProductDetail(widget.product.id);
      if (mounted) {
        setState(() {
          _fullProduct = detail;
          _isLoadingDetail = false;
          if (detail != null) {
            if (detail.sizes.isNotEmpty) _selectedSize = detail.sizes.first;
            if (detail.colors.isNotEmpty) _selectedColor = detail.colors.first;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingDetail = false;
        });
      }
    }
  }

  /// The link to hand out for this product. A logged-in shopper's own referral
  /// code rides along, so anything they share can earn them commission.
  String get _shareUrl => ReferralLink.productUrl(
        _product.id,
        referralCode: context.read<AuthProvider>().user?.referralCode,
      );

  String get _shareMessage =>
      'Check out ${_product.title} at ₹${_product.price.toStringAsFixed(2)} on Dristi Fashions\n$_shareUrl';

  void _shareProduct() {
    Share.share(_shareMessage, subject: _product.title);
  }

  Future<void> _copyLink() async {
    final url = _shareUrl;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    final earns = context.read<AuthProvider>().user?.referralCode != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(earns
            ? 'Link copied — you earn when a friend buys through it'
            : 'Product link copied'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addToCart() {
    context.read<CartProvider>().addToCart(
      product: _product,
      quantity: _quantity,
      selectedSize: _selectedSize,
      selectedColor: _selectedColor,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to cart'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _buyNow() {
    final cart = context.read<CartProvider>();
    cart.clear();
    cart.addToCart(
      product: _product,
      quantity: _quantity,
      selectedSize: _selectedSize,
      selectedColor: _selectedColor,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;

    if (_isLoadingDetail) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 18, color: AppColors.textPrimary),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isWishlisted ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: _isWishlisted
                          ? AppColors.secondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  onPressed: () {
                    final auth = context.read<AuthProvider>();
                    if (!auth.isLoggedIn) {
                      Navigator.pushNamed(context, '/login');
                      return;
                    }
                    context.read<WishlistProvider>().toggle(_product.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isWishlisted
                              ? 'Removed from wishlist'
                              : 'Added to wishlist',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.share, size: 18),
                  ),
                  onPressed: () => _shareProduct(),
                ),
                IconButton(
                  tooltip: 'Copy link',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.copy, size: 18),
                  ),
                  onPressed: _copyLink,
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: 'product-${product.id}',
                  child: _buildGallery(product),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.brand.toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.title,
                                style: AppTextStyles.headline3,
                              ),
                            ],
                          ),
                        ),
                        if (product.discountPercentage > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-${product.discountPercentage}% OFF',
                              style: AppTextStyles.priceSmall.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 16, color: AppColors.rating),
                        const SizedBox(width: 4),
                        Text(
                          '${product.rating}',
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${product.stock} in stock',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(2)}',
                          style: AppTextStyles.displayMedium.copyWith(
                            color: AppColors.secondary,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (product.discountPercentage > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '₹${product.originalPrice.toStringAsFixed(2)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      product.gstPercentage > 0
                          ? 'Incl. GST ${product.gstPercentage.toStringAsFixed(product.gstPercentage % 1 == 0 ? 0 : 2)}% '
                              '(CGST ${product.cgstPercentage.toStringAsFixed(product.cgstPercentage % 1 == 0 ? 0 : 2)}% '
                              '+ SGST ${product.sgstPercentage.toStringAsFixed(product.sgstPercentage % 1 == 0 ? 0 : 2)}%)'
                          : 'Includes GST',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.md),
                child: Divider(color: AppColors.divider),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Size', style: AppTextStyles.subtitle),
                    const SizedBox(height: AppDimensions.sm),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: product.sizes.map((size) {
                        final selected = _selectedSize == size;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedSize = size),
                          child: Container(
                            width: 50,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.divider,
                              borderRadius: BorderRadius.circular(10),
                              border: selected
                                  ? Border.all(
                                      color: AppColors.primary, width: 1.5)
                                  : null,
                            ),
                            child: Text(
                              size,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? AppColors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text('Select Color', style: AppTextStyles.subtitle),
                    const SizedBox(height: AppDimensions.sm),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: product.colors.map((color) {
                        final selected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedColor = color),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.divider,
                              borderRadius: BorderRadius.circular(10),
                              border: selected
                                  ? Border.all(
                                      color: AppColors.primary, width: 1.5)
                                  : null,
                            ),
                            child: Text(
                              color,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? AppColors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.md),
                child: Divider(color: AppColors.divider),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Description', style: AppTextStyles.subtitle),
                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      product.description.trim().isNotEmpty
                          ? product.description
                          : 'No description available.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (product.sku.trim().isNotEmpty)
                          _infoChip(Iconsax.box, 'SKU: ${product.sku}'),
                        _infoChip(Iconsax.verify, '100% Original'),
                        _infoChip(Iconsax.clock, _deliveryLabel),
                        if (product.isReturnable)
                          _infoChip(Iconsax.refresh_circle, '7-day Returns'),
                        if (product.isReplaceable)
                          _infoChip(Iconsax.repeate_one, 'Replaceable'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.md,
                  AppDimensions.md,
                  AppDimensions.md,
                  100,
                ),
                child: SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.md,
          AppDimensions.sm,
          AppDimensions.md,
          AppDimensions.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Consumer<WishlistProvider>(
                builder: (_, wishlist, __) {
                  final isWishlisted = wishlist.isWishlisted(_product.id);
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isWishlisted ? Iconsax.heart : Iconsax.heart,
                        size: 22,
                        color: isWishlisted
                            ? AppColors.secondary
                            : AppColors.textPrimary,
                      ),
                      onPressed: () {
                        final auth = context.read<AuthProvider>();
                        if (!auth.isLoggedIn) {
                          Navigator.pushNamed(context, '/login');
                          return;
                        }
                        wishlist.toggle(_product.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isWishlisted
                                  ? 'Removed from wishlist'
                                  : 'Added to wishlist',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Add to Cart',
                  onPressed: _addToCart,
                  height: 48,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Buy Now',
                  onPressed: _buyNow,
                  height: 48,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The collapsing-header gallery: a swipeable, contain-fit page per photo
  /// with a dot indicator. Photos are shown contain (never cropped) over the
  /// product's gradient, matching the storefront's image convention.
  Widget _buildGallery(Product product) {
    final images = _galleryImages;
    final video = _galleryVideo;
    // The video is not a section of its own: it rides along as the slide after
    // the last photo, so one swipe gets the shopper from stills to video.
    final slideCount = images.length + (video != null ? 1 : 0);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: product.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: slideCount == 0
          ? _galleryFallback()
          : Stack(
              children: [
                PageView.builder(
                  controller: _galleryController,
                  itemCount: slideCount,
                  onPageChanged: (i) => setState(() => _currentImage = i),
                  itemBuilder: (_, i) {
                    if (video != null && i == slideCount - 1) {
                      return ProductVideoPlayer(
                        videoUrl: video.videoUrl,
                        thumbnailUrl: video.thumbnailUrl,
                        borderRadius: BorderRadius.zero,
                        posterFit: BoxFit.contain,
                        expand: true,
                      );
                    }
                    return CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, __) => _galleryFallback(),
                      errorWidget: (_, __, ___) => _galleryFallback(),
                    );
                  },
                ),
                if (slideCount > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(slideCount, (i) {
                        final active = i == _currentImage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.white
                                : AppColors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _galleryFallback() => Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: 160,
          color: AppColors.white.withValues(alpha: 0.3),
        ),
      );

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
