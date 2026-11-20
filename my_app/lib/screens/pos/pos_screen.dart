import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/config/app_language.dart';
import 'package:my_app/models/mart_models.dart';
import 'package:my_app/services/mart_service.dart';
import 'package:my_app/widgets/product_image.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final MartService _martService = MartService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();

  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  int _selectedCategoryId = 0; // 0 = all
  bool _isLoading = true;

  // Cart
  final List<CartItemModel> _cart = [];
  CustomerModel? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    AppLanguage.languageNotifier.addListener(_onLanguageChanged);
    _martService.productsRevision.addListener(_onProductsChanged);
    _loadData();
  }

  void _onProductsChanged() {
    if (!mounted) return;
    final search = _searchController.text.trim().toLowerCase();
    setState(() {
      _products = _martService.products.where((product) {
        if (!product.isActive) return false;
        if (_selectedCategoryId > 0 &&
            product.categoryId != _selectedCategoryId) {
          return false;
        }
        return search.isEmpty ||
            product.nameKh.toLowerCase().contains(search) ||
            product.nameEn.toLowerCase().contains(search) ||
            product.barcode.toLowerCase().contains(search);
      }).toList();
    });
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppLanguage.languageNotifier.removeListener(_onLanguageChanged);
    _martService.productsRevision.removeListener(_onProductsChanged);
    _searchController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cats = await _martService.getCategories();
    final prods = await _martService.getProducts();
    if (mounted) {
      setState(() {
        _categories = cats;
        _products = prods;
        _isLoading = false;
      });
    }
  }

  void _filterProducts() async {
    final prods = await _martService.getProducts(
      categoryId: _selectedCategoryId == 0 ? null : _selectedCategoryId,
      search: _searchController.text.trim(),
    );
    if (mounted) {
      setState(() => _products = prods);
    }
  }

  void _onBarcodeScan(String code) {
    if (code.isEmpty) return;
    final product = _martService.findProductByBarcode(code);
    if (product != null) {
      _addToCart(product);
      _barcodeController.clear();
      EasyLoading.showToast('បានបន្ថែម: ${product.nameKh}', duration: const Duration(seconds: 1));
    } else {
      EasyLoading.showError('មិនមានទំនិញបាកូដនេះទេ ($code)');
    }
  }

  void _addToCart(ProductModel product) {
    if (product.stockQuantity <= 0) {
      EasyLoading.showInfo('ទំនិញនេះអស់ពីស្តុកហើយ');
      return;
    }

    setState(() {
      int idx = _cart.indexWhere((item) => item.product.id == product.id);
      if (idx != -1) {
        if (_cart[idx].quantity < product.stockQuantity) {
          _cart[idx].quantity++;
        } else {
          EasyLoading.showToast('លើសចំនួនក្នុងស្តុកហើយ');
        }
      } else {
        _cart.add(CartItemModel(product: product, quantity: 1));
      }
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final item = _cart[index];
      final newQty = item.quantity + delta;
      if (newQty <= 0) {
        _cart.removeAt(index);
      } else if (newQty <= item.product.stockQuantity) {
        item.quantity = newQty;
      } else {
        EasyLoading.showToast('ស្តុកនៅសល់ត្រឹម ${item.product.stockQuantity}');
      }
    });
  }

  double get _cartSubtotalUsd =>
      _cart.fold(0.0, (sum, i) => sum + i.subtotalUsd);
  double get _cartSubtotalKhr =>
      _cart.fold(0.0, (sum, i) => sum + i.subtotalKhr);

  // Discount state: 'none', 'percent', 'amount'
  String _discountType = 'none';
  double _discountPercent = 0.0;
  double _discountAmountUsd = 0.0;

  double get _discountUsd {
    if (_discountType == 'percent') {
      return (_cartSubtotalUsd * (_discountPercent / 100.0));
    } else if (_discountType == 'amount') {
      return _discountAmountUsd.clamp(0.0, _cartSubtotalUsd);
    }
    return 0.0;
  }

  double get _discountKhr =>
      (_discountUsd * _martService.exchangeRate).roundToDouble();

  double get _cartTotalUsd =>
      (_cartSubtotalUsd - _discountUsd).clamp(0.0, 9999999.0);
  double get _cartTotalKhr =>
      (_cartTotalUsd * _martService.exchangeRate).roundToDouble();
  int get _cartItemCount => _cart.fold(0, (sum, i) => sum + i.quantity);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLanguage.isEnglish ? 'Mart POS Terminal' : 'កន្លែងគិតលុយ',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              AppLanguage.isEnglish
                  ? 'Exchange Rate: \$1 = ${_martService.formatKhr(_martService.exchangeRate)}'
                  : 'អត្រាប្តូរប្រាក់: \$1 = ${_martService.formatKhr(_martService.exchangeRate)}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: AppLanguage.isEnglish ? 'Quick Barcode Scanner' : 'ស្កេនបាកូដរហ័ស',
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: _showBarcodeScanDialog,
          ),
          IconButton(
            tooltip: AppLanguage.isEnglish ? 'Customer Loyalty Search' : 'ស្វែងរកអតិថិជន',
            icon: const Icon(Icons.person_search, color: Colors.white),
            onPressed: _showCustomerLookupDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Search & Quick Barcode input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _filterProducts(),
                    decoration: InputDecoration(
                      hintText: AppLanguage.isEnglish
                          ? 'Search product name or barcode...'
                          : 'ស្វែងរកឈ្មោះទំនិញ ឬបាកូដ...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _filterProducts();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.barcode_reader, color: AppColors.primary),
                  onPressed: _showBarcodeScanDialog,
                ),
              ],
            ),
          ),

          // Categories horizontal list
          Container(
            height: 48,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              children: [
                _buildCategoryChip(
                    0, AppLanguage.isEnglish ? 'All' : 'ទាំងអស់'),
                ..._categories.map((c) => _buildCategoryChip(
                    c.id,
                    AppLanguage.isEnglish && c.nameEn.isNotEmpty
                        ? c.nameEn
                        : c.nameKh)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Product Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              AppLanguage.isEnglish
                                  ? 'No products match your search'
                                  : 'មិនមានទំនិញតាមលក្ខខណ្ឌស្វែងរកនេះទេ',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.82,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return _buildProductCard(product);
                        },
                      ),
          ),

          // Bottom Cart Summary Bar
          _buildBottomCartBar(),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(int id, String title) {
    final bool isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (selected) {
          setState(() {
            _selectedCategoryId = id;
          });
          _filterProducts();
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _addToCart(product),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Barcode and stock tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.unit,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.isLowStock
                          ? AppColors.danger.withValues(alpha: 0.12)
                          : AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      AppLanguage.isEnglish
                          ? 'Rem: ${product.stockQuantity}'
                          : 'សល់ ${product.stockQuantity}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: product.isLowStock ? AppColors.danger : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Product image
              Center(
                child: ProductImage(
                  imageUrl: product.imageUrl,
                  width: 84,
                  height: 84,
                  borderRadius: BorderRadius.circular(12),
                  placeholderIcon: Icons.shopping_bag_outlined,
                ),
              ),
              const Spacer(),

              // Product Names with Item Code (e.g. BEV-0001. Coca-Cola)
              RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    if (product.itemCode.isNotEmpty)
                      TextSpan(
                        text: '${product.itemCode}. ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    TextSpan(
                      text: AppLanguage.isEnglish
                          ? (product.nameEn.isNotEmpty
                              ? product.nameEn
                              : product.nameKh)
                          : (product.nameKh.isNotEmpty
                              ? product.nameKh
                              : product.nameEn),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Dual Currency Pricing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _martService.formatUsd(product.sellingPriceUsd),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        _martService.formatKhr(product.sellingPriceKhr),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(5),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCartBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, -3),
            blurRadius: 10,
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cart badge & click to open sheet
            InkWell(
              onTap: _showCartBottomSheet,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary, size: 26),
                  ),
                  if (_cartItemCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_cartItemCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Dual currency totals
            Expanded(
              child: InkWell(
                onTap: _showCartBottomSheet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${AppLanguage.isEnglish ? "Total" : "សរុប"}: ${_martService.formatUsd(_cartTotalUsd)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      _martService.formatKhr(_cartTotalKhr),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
            ),

            // Checkout Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _cart.isEmpty ? Colors.grey : AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.payments_outlined, color: Colors.white, size: 20),
              label: Text(
                AppLanguage.isEnglish ? 'Pay' : 'គិតលុយ',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: _cart.isEmpty ? null : _showCheckoutDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomDiscountDialog(
      void Function(void Function()) setSheetState) async {
    final bool isEn = AppLanguage.isEnglish;
    int tab = _discountType == 'amount' ? 1 : 0; // 0 = %, 1 = $
    final ctrl = TextEditingController(
      text: tab == 0
          ? (_discountPercent > 0 ? _discountPercent.toStringAsFixed(0) : '')
          : (_discountAmountUsd > 0
              ? _discountAmountUsd.toStringAsFixed(2)
              : ''),
    );

    await showDialog(
      context: context,
      builder: (dlgContext) {
        return StatefulBuilder(
          builder: (c, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              title: Row(
                children: [
                  const Icon(Icons.discount,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isEn ? 'Custom Discount' : 'បញ្ចុះតម្លៃផ្ទាល់ខ្លួន',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tab selector: % or $
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              isEn ? 'Percent (%)' : 'ភាគរយ (%)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: tab == 0
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          selected: tab == 0,
                          selectedColor: AppColors.primary,
                          onSelected: (val) {
                            if (val) setDlgState(() => tab = 0);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              isEn ? 'Amount (\$)' : 'ទឹកប្រាក់ (\$)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: tab == 1
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          selected: tab == 1,
                          selectedColor: AppColors.primary,
                          onSelected: (val) {
                            if (val) setDlgState(() => tab = 1);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: tab == 0
                          ? (isEn ? 'Enter percentage (%)' : 'បញ្ចូលភាគរយ (%)')
                          : (isEn
                              ? 'Enter amount (\$)'
                              : 'បញ្ចូលទឹកប្រាក់ (\$)'),
                      prefixIcon: Icon(
                        tab == 0 ? Icons.percent : Icons.attach_money,
                        size: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgContext),
                  child: Text(isEn ? 'Cancel' : 'បោះបង់'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final val = double.tryParse(ctrl.text.trim()) ?? 0.0;
                    if (val <= 0) {
                      setState(() {
                        _discountType = 'none';
                        _discountPercent = 0.0;
                        _discountAmountUsd = 0.0;
                      });
                    } else if (tab == 0) {
                      setState(() {
                        _discountType = 'percent';
                        _discountPercent = val.clamp(0.0, 100.0);
                        _discountAmountUsd = 0.0;
                      });
                    } else {
                      setState(() {
                        _discountType = 'amount';
                        _discountAmountUsd =
                            val.clamp(0.0, _cartSubtotalUsd);
                        _discountPercent = 0.0;
                      });
                    }
                    setSheetState(() {});
                    Navigator.pop(dlgContext);
                  },
                  child: Text(
                    isEn ? 'Apply' : 'អនុវត្ត',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // CART DETAILS BOTTOM SHEET
  // ==========================================
  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLanguage.isEnglish
                            ? 'Cart Items'
                            : 'កន្ត្រកទំនិញ',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      if (_cart.isNotEmpty)
                        TextButton.icon(
                          icon: const Icon(Icons.delete_sweep,
                              size: 18, color: AppColors.danger),
                          label: Text(
                              AppLanguage.isEnglish ? 'Clear' : 'សម្អាត',
                              style: const TextStyle(
                                  color: AppColors.danger, fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              _cart.clear();
                              _discountType = 'none';
                              _discountPercent = 0.0;
                              _discountAmountUsd = 0.0;
                            });
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                  const Divider(),

                  // Items List
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(
                            child: Text('មិនទាន់មានទំនិញក្នុងកន្ត្រកទេ',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          )
                        : ListView.separated(
                            itemCount: _cart.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _cart[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppLanguage.isEnglish
                                                ? (item.product.nameEn.isNotEmpty
                                                    ? item.product.nameEn
                                                    : item.product.nameKh)
                                                : (item.product.nameKh.isNotEmpty
                                                    ? item.product.nameKh
                                                    : item.product.nameEn),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13),
                                          ),
                                          Text(
                                            '${_martService.formatUsd(item.product.sellingPriceUsd)} (${_martService.formatKhr(item.product.sellingPriceKhr)}) / ${item.product.unit}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Quantity Selector
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline,
                                              size: 22,
                                              color: AppColors.primary),
                                          onPressed: () {
                                            _updateQuantity(index, -1);
                                            setSheetState(() {});
                                          },
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 22,
                                              color: AppColors.primary),
                                          onPressed: () {
                                            _updateQuantity(index, 1);
                                            setSheetState(() {});
                                          },
                                        ),
                                      ],
                                    ),

                                    // Item total
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _martService
                                              .formatUsd(item.subtotalUsd),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: AppColors.primary),
                                        ),
                                        Text(
                                          _martService
                                              .formatKhr(item.subtotalKhr),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.secondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // 1. Discount Section (Before Checkout)
                  if (_cart.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _discountUsd > 0
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _discountUsd > 0
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.discount_outlined,
                                    size: 16,
                                    color: _discountUsd > 0
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLanguage.isEnglish ? 'Discount:' : 'បញ្ចុះតម្លៃ:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _discountUsd > 0
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              if (_discountUsd > 0)
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _discountType = 'none';
                                      _discountPercent = 0.0;
                                      _discountAmountUsd = 0.0;
                                    });
                                    setSheetState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '-${_martService.formatUsd(_discountUsd)}${_discountType == 'percent' ? ' (${_discountPercent.toStringAsFixed(0)}%)' : ''}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.danger,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.close,
                                            size: 12, color: AppColors.danger),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildDiscountPill(
                                  label: '0%',
                                  isSelected: _discountType == 'none',
                                  onTap: () {
                                    setState(() {
                                      _discountType = 'none';
                                      _discountPercent = 0.0;
                                      _discountAmountUsd = 0.0;
                                    });
                                    setSheetState(() {});
                                  },
                                ),
                                const SizedBox(width: 6),
                                _buildDiscountPill(
                                  label: '5%',
                                  isSelected: _discountType == 'percent' &&
                                      _discountPercent == 5.0,
                                  onTap: () {
                                    setState(() {
                                      _discountType = 'percent';
                                      _discountPercent = 5.0;
                                      _discountAmountUsd = 0.0;
                                    });
                                    setSheetState(() {});
                                  },
                                ),
                                const SizedBox(width: 6),
                                _buildDiscountPill(
                                  label: '10%',
                                  isSelected: _discountType == 'percent' &&
                                      _discountPercent == 10.0,
                                  onTap: () {
                                    setState(() {
                                      _discountType = 'percent';
                                      _discountPercent = 10.0;
                                      _discountAmountUsd = 0.0;
                                    });
                                    setSheetState(() {});
                                  },
                                ),
                                const SizedBox(width: 6),
                                _buildDiscountPill(
                                  label: '15%',
                                  isSelected: _discountType == 'percent' &&
                                      _discountPercent == 15.0,
                                  onTap: () {
                                    setState(() {
                                      _discountType = 'percent';
                                      _discountPercent = 15.0;
                                      _discountAmountUsd = 0.0;
                                    });
                                    setSheetState(() {});
                                  },
                                ),
                                const SizedBox(width: 6),
                                _buildDiscountPill(
                                  label: '20%',
                                  isSelected: _discountType == 'percent' &&
                                      _discountPercent == 20.0,
                                  onTap: () {
                                    setState(() {
                                      _discountType = 'percent';
                                      _discountPercent = 20.0;
                                      _discountAmountUsd = 0.0;
                                    });
                                    setSheetState(() {});
                                  },
                                ),
                                const SizedBox(width: 6),
                                _buildDiscountPill(
                                  label: AppLanguage.isEnglish
                                      ? 'Custom...'
                                      : 'ផ្ទាល់ខ្លួន...',
                                  isSelected: (_discountType == 'percent' &&
                                          ![0.0, 5.0, 10.0, 15.0, 20.0]
                                              .contains(_discountPercent)) ||
                                      _discountType == 'amount',
                                  icon: Icons.edit_note_rounded,
                                  onTap: () async {
                                    await _showCustomDiscountDialog(
                                        setSheetState);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 2. Summary & Bottom checkout button inside sheet
                  const Divider(height: 8),
                  if (_discountUsd > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            AppLanguage.isEnglish
                                ? 'Subtotal:'
                                : 'សរុបរង:',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        Text(
                          '${_martService.formatUsd(_cartSubtotalUsd)} (${_martService.formatKhr(_cartSubtotalKhr)})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            AppLanguage.isEnglish
                                ? 'Discount:'
                                : 'បញ្ចុះតម្លៃ:',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger)),
                        Text(
                          '-${_martService.formatUsd(_discountUsd)} (-${_martService.formatKhr(_discountKhr)})',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('សរុប: ',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                _martService.formatUsd(_cartTotalUsd),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                          Text(
                            _martService.formatKhr(_cartTotalKhr),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _cart.isEmpty
                            ? null
                            : () {
                                Navigator.pop(context);
                                _showCheckoutDialog();
                              },
                        child: Text(
                            AppLanguage.isEnglish
                                ? 'Proceed to Checkout'
                                : 'បន្តទៅគិតលុយ',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // CHECKOUT DIALOG (CASH & BAKONG KHQR)
  // ==========================================
  void _showCheckoutDialog() {
    int paymentTab = 0; // 0 = Cash, 1 = KHQR Bakong
    final TextEditingController usdPaidCtrl = TextEditingController();
    final TextEditingController khrPaidCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double paidUsd = double.tryParse(usdPaidCtrl.text) ?? 0.0;
            double paidKhr = double.tryParse(khrPaidCtrl.text) ?? 0.0;
            double totalPaidUsdEquivalent = paidUsd + (paidKhr / _martService.exchangeRate);
            double changeUsd = (totalPaidUsdEquivalent - _cartTotalUsd) > 0 ? (totalPaidUsdEquivalent - _cartTotalUsd) : 0.0;
            double changeKhr = (changeUsd * _martService.exchangeRate).roundToDouble();

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 440,
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLanguage.isEnglish
                                ? 'Payment & Checkout'
                                : 'ការទូទាត់ប្រាក់',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),

                      // Total to pay banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            if (_discountUsd > 0) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      AppLanguage.isEnglish
                                          ? 'Subtotal:'
                                          : 'សរុបរង:',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                  Text(
                                    '${_martService.formatUsd(_cartSubtotalUsd)} (${_martService.formatKhr(_cartSubtotalKhr)})',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        decoration:
                                            TextDecoration.lineThrough),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      AppLanguage.isEnglish
                                          ? 'Discount:'
                                          : 'បញ្ចុះតម្លៃ:',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.danger)),
                                  Text(
                                    '-${_martService.formatUsd(_discountUsd)} (-${_martService.formatKhr(_discountKhr)})',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.danger),
                                  ),
                                ],
                              ),
                              const Divider(height: 12),
                            ],
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    AppLanguage.isEnglish
                                        ? 'Total Amount to Pay:'
                                        : 'ចំនួនទឹកប្រាក់ត្រូវបង់:',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(_martService.formatUsd(_cartTotalUsd),
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary)),
                                    Text(_martService.formatKhr(_cartTotalKhr),
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondary)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Payment Method Selector Tabs
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: paymentTab == 0 ? AppColors.primary : AppColors.surface,
                                foregroundColor: paymentTab == 0 ? Colors.white : AppColors.textPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.money, size: 18),
                              label: Text(
                                AppLanguage.isEnglish ? 'Cash' : 'សាច់ប្រាក់',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => setDialogState(() => paymentTab = 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: paymentTab == 1 ? AppColors.khqrBakongRed : AppColors.surface,
                                foregroundColor: paymentTab == 1 ? Colors.white : AppColors.textPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.qr_code_2, size: 18),
                              label: Text(
                                AppLanguage.isEnglish ? 'Bakong KHQR' : 'បាគង KHQR',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => setDialogState(() => paymentTab = 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // CASH TAB
                      if (paymentTab == 0) ...[
                        Text(
                          AppLanguage.isEnglish ? 'Enter Amount Received:' : 'បញ្ចូលប្រាក់ទទួលពីអតិថិជន:',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: usdPaidCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setDialogState(() {}),
                                decoration: InputDecoration(
                                  labelText: AppLanguage.isEnglish ? 'Received in USD (\$)' : 'ទទួលជាដុល្លារ (\$)',
                                  prefixIcon: const Icon(Icons.attach_money, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: khrPaidCtrl,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setDialogState(() {}),
                                decoration: InputDecoration(
                                  labelText: AppLanguage.isEnglish ? 'Received in KHR (៛)' : 'ទទួលជារៀល (៛)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Quick cash buttons
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildQuickCashButton('\$5', () {
                              usdPaidCtrl.text = '5';
                              setDialogState(() {});
                            }),
                            _buildQuickCashButton('\$10', () {
                              usdPaidCtrl.text = '10';
                              setDialogState(() {});
                            }),
                            _buildQuickCashButton('\$20', () {
                              usdPaidCtrl.text = '20';
                              setDialogState(() {});
                            }),
                            _buildQuickCashButton('20,000 ៛', () {
                              khrPaidCtrl.text = '20000';
                              setDialogState(() {});
                            }),
                            _buildQuickCashButton('50,000 ៛', () {
                              khrPaidCtrl.text = '50000';
                              setDialogState(() {});
                            }),
                            _buildQuickCashButton(AppLanguage.isEnglish ? 'Exact' : 'គ្រប់ចំនួន', () {
                              usdPaidCtrl.text = _cartTotalUsd.toStringAsFixed(2);
                              setDialogState(() {});
                            }),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Change Calculation Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: changeUsd > 0 ? AppColors.success.withValues(alpha: 0.1) : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLanguage.isEnglish ? 'Change Due:' : 'ប្រាក់អាប់ជូន:',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(_martService.formatUsd(changeUsd), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                                  Text(_martService.formatKhr(changeKhr), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      // BAKONG KHQR TAB
                      if (paymentTab == 1) ...[
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.khqrBakongRed, width: 2),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.khqrBakongRed,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('KHQR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('BAKONG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      height: 140,
                                      width: 140,
                                      color: Colors.black12,
                                      child: const Center(
                                        child: Icon(Icons.qr_code_2, size: 120, color: Colors.black87),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _martService.getSettings().bakongMerchantName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    Text(
                                      '${_martService.formatUsd(_cartTotalUsd)} / ${_martService.formatKhr(_cartTotalKhr)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLanguage.isEnglish
                                    ? 'Scan with any Mobile Banking or Bakong app'
                                    : 'ស្កេនជាមួយ App ធនាគារ ឬបាគងណាមួយ',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Complete Payment Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: paymentTab == 1 ? AppColors.khqrBakongRed : AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _executeCheckout(
                            paymentMethod: paymentTab == 1 ? 'khqr_bakong' : 'cash_usd',
                            receivedUsd: paidUsd,
                            receivedKhr: paidKhr,
                          );
                        },
                        child: Text(
                          paymentTab == 1
                              ? (AppLanguage.isEnglish ? 'Confirm KHQR Payment' : 'បញ្ជាក់ការទទួលប្រាក់តាម KHQR')
                              : (AppLanguage.isEnglish ? 'Print Receipt & Complete Sale' : 'បោះពុម្ពវិក្កយបត្រ & បញ្ចប់ការលក់'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickCashButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
    );
  }

  Future<void> _executeCheckout({
    required String paymentMethod,
    double receivedUsd = 0.0,
    double receivedKhr = 0.0,
  }) async {
    EasyLoading.show(status: 'កំពុងចេញវិក្កយបត្រ...');
    try {
      final order = await _martService.checkout(
        items: List.from(_cart),
        paymentMethod: paymentMethod,
        discountUsd: _discountUsd,
        receivedUsd: receivedUsd,
        receivedKhr: receivedKhr,
        customerPhone: _selectedCustomer?.phone,
        customerName: _selectedCustomer?.name,
      );

      EasyLoading.dismiss();
      setState(() {
        _cart.clear();
        _selectedCustomer = null;
        _discountType = 'none';
        _discountPercent = 0.0;
        _discountAmountUsd = 0.0;
      });

      if (mounted) {
        _showReceiptDialog(order);
      }
    } catch (e) {
      EasyLoading.showError('មានបញ្ហាក្នុងការគិតលុយ: $e');
    }
  }

  // ==========================================
  // RECEIPT PREVIEW MODAL
  // ==========================================
  void _showReceiptDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) {
        final setting = _martService.getSettings();
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Receipt Header
                  Text(
                    setting.martNameKh,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  Text(
                    setting.martNameEn,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    setting.branchName,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    'ទូរស័ព្ទ: ${setting.phone}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const Divider(thickness: 1, height: 16),

                  // Invoice info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${AppLanguage.isEnglish ? "Invoice No:" : "លេខវិក្កយបត្រ:"} ${order.invoiceNo}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(order.createdAt.substring(11, 16), style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${AppLanguage.isEnglish ? "Cashier:" : "បេឡាករ:"} ${order.cashierName}', style: const TextStyle(fontSize: 11)),
                      Text(order.createdAt.substring(0, 10), style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  const Divider(thickness: 1, height: 16),

                  // Items table
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName} x${item.quantity}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          _martService.formatUsd(item.subtotalUsd),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
                  const Divider(thickness: 1, height: 16),

                  // Subtotal & Discount if applicable
                  if (order.discountUsd > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLanguage.isEnglish ? 'Subtotal:' : 'សរុបរង:',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        Text(_martService.formatUsd(order.subtotalUsd),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLanguage.isEnglish ? 'Discount:' : 'បញ្ចុះតម្លៃ:',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger)),
                        Text('-${_martService.formatUsd(order.discountUsd)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger)),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Total USD & KHR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLanguage.isEnglish ? 'Total USD:' : 'សរុបជាដុល្លារ:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(_martService.formatUsd(order.totalUsd), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLanguage.isEnglish ? 'Total KHR:' : 'សរុបជារៀល:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(_martService.formatKhr(order.totalKhr), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary)),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${AppLanguage.isEnglish ? "Payment Method:" : "វិធីទូទាត់:"} ${order.paymentMethod == "khqr_bakong" ? (AppLanguage.isEnglish ? "Bakong KHQR" : "បាគង KHQR") : (AppLanguage.isEnglish ? "Cash" : "សាច់ប្រាក់")}', style: const TextStyle(fontSize: 11)),
                      Text('${AppLanguage.isEnglish ? "Rate:" : "អត្រា:"} \$1 = ${_martService.formatKhr(order.exchangeRate)}', style: const TextStyle(fontSize: 11)),
                    ],
                  ),

                  if (order.changeUsd > 0 || order.changeKhr > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLanguage.isEnglish ? 'Change:' : 'ប្រាក់អាប់:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('${_martService.formatUsd(order.changeUsd)} / ${_martService.formatKhr(order.changeKhr)}', style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold)),
                      ],
                    ),

                  const Divider(thickness: 1, height: 20),
                  Text(
                    AppLanguage.isEnglish ? setting.receiptFooterEn : setting.receiptFooterKh,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.print, size: 18),
                          label: Text(AppLanguage.isEnglish ? 'Print' : 'បោះពុម្ព'),
                          onPressed: () {
                            EasyLoading.showSuccess(AppLanguage.isEnglish ? 'Sent to POS printer!' : 'បានបញ្ជូនទៅម៉ាស៊ីនព្រីន POS!');
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () => Navigator.pop(context),
                          child: Text(AppLanguage.isEnglish ? 'Done' : 'រួចរាល់', style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBarcodeScanDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLanguage.isEnglish ? 'Scan or Enter Barcode' : 'ស្កេន ឬបញ្ចូលបាកូដ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _barcodeController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: AppLanguage.isEnglish ? 'Barcode' : 'លេខបាកូដ',
              prefixIcon: const Icon(Icons.barcode_reader),
            ),
            onSubmitted: (code) {
              Navigator.pop(context);
              _onBarcodeScan(code);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLanguage.isEnglish ? 'Cancel' : 'បោះបង់'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final code = _barcodeController.text.trim();
                Navigator.pop(context);
                _onBarcodeScan(code);
              },
              child: Text(AppLanguage.isEnglish ? 'Scan' : 'ស្កេន', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showCustomerLookupDialog() {
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLanguage.isEnglish
                ? 'Customer Loyalty Search'
                : 'ស្វែងរកអតិថិជនសន្សំពិន្ទុ',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: AppLanguage.isEnglish ? 'Phone Number' : 'លេខទូរស័ព្ទ',
              prefixIcon: const Icon(Icons.phone),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLanguage.isEnglish ? 'Cancel' : 'បោះបង់')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final phone = phoneCtrl.text.trim();
                final c = _martService.findCustomerByPhone(phone);
                if (c != null) {
                  setState(() => _selectedCustomer = c);
                  EasyLoading.showSuccess(AppLanguage.isEnglish ? 'Connected: ${c.name} (${c.points} pts)' : 'បានភ្ជាប់: ${c.name} (${c.points} ពិន្ទុ)');
                } else {
                  EasyLoading.showInfo(AppLanguage.isEnglish ? 'No member found, will auto-register on purchase' : 'មិនទាន់មានសមាជិកនេះទេ នឹងចុះឈ្មោះស្វ័យប្រវត្តិនឹងការទិញ');
                }
                Navigator.pop(context);
              },
              child: Text(AppLanguage.isEnglish ? 'Link Customer' : 'ភ្ជាប់អតិថិជន', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
