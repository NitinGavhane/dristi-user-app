import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/animations.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../providers/product_provider.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final Category? category;
  final String? searchQuery;
  final String? title;
  final double? maxPrice;
  final String? initialGender;

  const ProductListScreen({
    super.key,
    this.category,
    this.searchQuery,
    this.title,
    this.maxPrice,
    this.initialGender,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const double _kMaxPrice = 50000;
  // Quick "under ₹X" price points shown as circular buttons above the grid.
  static const List<double> _kPriceChips = [199, 299, 499, 799, 999];
  String? _selectedSize;
  String? _selectedColor;
  late double _maxPrice;
  // The active price chip (an "under ₹X" cap), or null when none is chosen.
  double? _selectedPriceChip;
  String _sortBy = 'Popular';
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  List<Product> get _products {
    final productProvider = context.read<ProductProvider>();
    var filtered = widget.category != null
        ? productProvider.products
        : widget.searchQuery != null
            ? productProvider.searchProducts(widget.searchQuery!)
            : productProvider.products;

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList();
    }

    if (_selectedSize != null) {
      filtered = filtered
          .where((p) => p.sizes.contains(_selectedSize))
          .toList();
    }

    if (_selectedColor != null) {
      filtered = filtered
          .where((p) => p.colors.contains(_selectedColor))
          .toList();
    }

    filtered = filtered.where((p) => p.price <= _maxPrice).toList();

    switch (_sortBy) {
      case 'Price: Low to High':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Newest':
        filtered.sort((a, b) => b.isNew ? 1 : -1);
        break;
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _maxPrice = widget.maxPrice ?? _kMaxPrice;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts(
        category: widget.category?.id,
        search: widget.searchQuery,
        gender: widget.initialGender,
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            widget.title ?? widget.category?.name ?? 'Products',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.festiveGold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.sort, size: 20),
            onPressed: () => _showSortSheet(context),
          ),
          IconButton(
            icon: const Icon(Iconsax.setting_4, size: 20),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: context.watch<ProductProvider>().isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.md,
                    AppDimensions.sm + 2,
                    AppDimensions.md,
                    0,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v.trim()),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText:
                          'Search in ${widget.title ?? widget.category?.name ?? 'products'}...',
                      prefixIcon: const Icon(Iconsax.search_normal_1,
                          size: 18, color: AppColors.brandGold),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: AppColors.textHint),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _search = '');
                              },
                            ),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                _priceChips(),
                if (_products.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_products.length} products found',
                          style: AppTextStyles.bodySmall,
                        ),
                        Text(
                          'Sort: $_sortBy',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.box,
                                  size: 64, color: AppColors.textHint),
                              const SizedBox(height: 16),
                              Text(
                                'No products found',
                                style: AppTextStyles.subtitle,
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(AppDimensions.md),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.58,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return StaggeredEntrance(
                              index: index,
                              child: ProductCard(
                                product: product,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailScreen(product: product),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  /// Circular "under ₹X" price-filter buttons. Tapping one caps the grid at
  /// that price; tapping the active one clears it. The selection is highlighted.
  Widget _priceChips() {
    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.sm),
      height: 82,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
        children: _kPriceChips.map((value) {
          final selected = _selectedPriceChip == value;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _selectedPriceChip = null;
                  _maxPrice = widget.maxPrice ?? _kMaxPrice;
                } else {
                  _selectedPriceChip = value;
                  _maxPrice = value;
                }
              }),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.primary : AppColors.surface,
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.divider,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '₹${value.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Under',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: selected ? AppColors.primary : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final sorts = ['Popular', 'Newest', 'Rating', 'Price: Low to High', 'Price: High to Low'];
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
            Text('Sort by', style: AppTextStyles.title),
            const SizedBox(height: AppDimensions.md),
            ...sorts.map((s) => RadioListTile<String>(
                  value: s,
                  groupValue: _sortBy,
                  onChanged: (v) {
                    setState(() => _sortBy = v!);
                    Navigator.pop(ctx);
                  },
                  title: Text(s, style: AppTextStyles.body),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                )),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: AppTextStyles.title),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedSize = null;
                        _selectedColor = null;
                        _selectedPriceChip = null;
                        _maxPrice = widget.maxPrice ?? _kMaxPrice;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text('Clear All',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary)),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              Text('Size', style: AppTextStyles.subtitle),
              const SizedBox(height: AppDimensions.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'].map((s) => FilterChip(
                  label: Text(s),
                  selected: _selectedSize == s,
                  onSelected: (v) {
                    setSheetState(() => _selectedSize = v ? s : null);
                    setState(() => _selectedSize = v ? s : null);
                  },
                )).toList(),
              ),
              const SizedBox(height: AppDimensions.md),
              Text('Max Price: ₹${_maxPrice.toStringAsFixed(0)}',
                  style: AppTextStyles.subtitle),
              Slider(
                value: _maxPrice,
                min: 0,
                max: _kMaxPrice,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  setSheetState(() => _maxPrice = v);
                  setState(() {
                    _maxPrice = v;
                    // A manual slider adjustment supersedes any active chip.
                    _selectedPriceChip = null;
                  });
                },
              ),
              const SizedBox(height: AppDimensions.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
            ],
          ),
        ),
      ),
    );
  }
}
