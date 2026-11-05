import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/models/mart_models.dart';
import 'package:my_app/services/mart_service.dart';
import 'package:my_app/widgets/product_image.dart';

class ProductScreen extends StatefulWidget {
  final int? initialCategoryId;
  const ProductScreen({super.key, this.initialCategoryId});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final MartService _martService = MartService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  int _selectedCatId = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      _selectedCatId = widget.initialCategoryId!;
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final cats = await _martService.getCategories();
    final prods = await _martService.getProducts(
      categoryId: _selectedCatId == 0 ? null : _selectedCatId,
    );
    if (mounted) {
      setState(() {
        _categories = cats;
        _products = prods;
        _isLoading = false;
      });
    }
  }

  void _filter() async {
    final prods = await _martService.getProducts(
      categoryId: _selectedCatId == 0 ? null : _selectedCatId,
      search: _searchCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _products = prods);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'គ្រប់គ្រងទំនិញម៉ាត (Products)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'បន្ថែមទំនិញថ្មី',
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 26),
            onPressed: () => _showAddEditProductDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _filter(),
                  decoration: InputDecoration(
                    hintText: 'ស្វែងរកតាមឈ្មោះ ឬលេខបាកូដ...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _filter();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCatFilter(0, 'ទាំងអស់ (${_products.length})'),
                      ..._categories.map((c) => _buildCatFilter(c.id, c.nameKh)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Product List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 50, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            const Text('មិនមានទំនិញឡើយ'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ProductImage(
                                    productId: product.id,
                                    imageUrl: product.imageUrl,
                                    width: 54,
                                    height: 54,
                                  ),
                                  const SizedBox(width: 12),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.nameKh,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ),
                                            Text(
                                              _martService.formatUsd(product.sellingPriceUsd),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.nameEn,
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              ),
                                            ),
                                            Text(
                                              _martService.formatKhr(product.sellingPriceKhr),
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.secondary),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Badges: Category, Barcode, Stock, Expiry
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            // Category badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.category, size: 11, color: AppColors.primary),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    product.categoryName ?? 'ទូទៅ',
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Barcode badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.surface,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.barcode_reader, size: 12, color: AppColors.textSecondary),
                                                  const SizedBox(width: 3),
                                                  Text(product.barcode, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                                ],
                                              ),
                                            ),

                                            // Stock badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: product.isLowStock
                                                    ? AppColors.danger.withValues(alpha: 0.12)
                                                    : AppColors.success.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'ស្តុក: ${product.stockQuantity} ${product.unit}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: product.isLowStock ? AppColors.danger : AppColors.success,
                                                ),
                                              ),
                                            ),

                                            // Expiry badge
                                            if (product.expiryDate != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: product.isExpiringSoon
                                                      ? AppColors.warning.withValues(alpha: 0.15)
                                                      : Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'ផុតកំណត់: ${product.expiryDate}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: product.isExpiringSoon ? AppColors.warning : AppColors.textSecondary,
                                                    fontWeight: product.isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quick Actions
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        _showAddEditProductDialog(product: product);
                                      } else if (val == 'stock') {
                                        _showAdjustStockDialog(product);
                                      } else if (val == 'delete') {
                                        _deleteProduct(product);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('កែប្រែ')]),
                                      ),
                                      const PopupMenuItem(
                                        value: 'stock',
                                        child: Row(children: [Icon(Icons.add_shopping_cart, size: 16), SizedBox(width: 8), Text('បញ្ចូលស្តុក')]),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 16), SizedBox(width: 8), Text('លុប', style: TextStyle(color: Colors.red))]),
                                      ),
                                    ],
                                  ),
                                ],
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

  Widget _buildCatFilter(int id, String title) {
    final bool isSelected = _selectedCatId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        selected: isSelected,
        label: Text(title, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textPrimary)),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        onSelected: (sel) {
          setState(() => _selectedCatId = id);
          _filter();
        },
      ),
    );
  }

  void _showAdjustStockDialog(ProductModel product) {
    final qtyCtrl = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('បញ្ចូលស្តុក: ${product.nameKh}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ស្តុកបច្ចុប្បន្ន: ${product.stockQuantity} ${product.unit}'),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ចំនួនបន្ថែម',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('បោះបង់')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                int add = int.tryParse(qtyCtrl.text) ?? 0;
                if (add > 0) {
                  setState(() {
                    product.stockQuantity += add;
                  });
                  _martService.updateProduct(product);
                  EasyLoading.showSuccess('បានបញ្ចូលស្តុកជោគជ័យ!');
                }
                Navigator.pop(context);
              },
              child: const Text('រក្សាទុក', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAddEditProductDialog({ProductModel? product}) {
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? DateTime.now().millisecondsSinceEpoch.toString().substring(0, 12));
    final nameKhCtrl = TextEditingController(text: product?.nameKh ?? '');
    final nameEnCtrl = TextEditingController(text: product?.nameEn ?? '');
    final unitCtrl = TextEditingController(text: product?.unit ?? 'កំប៉ុង');
    final priceUsdCtrl = TextEditingController(text: product != null ? product.sellingPriceUsd.toString() : '0.50');
    final stockCtrl = TextEditingController(text: product != null ? product.stockQuantity.toString() : '20');
    final expiryCtrl = TextEditingController(text: product?.expiryDate ?? '2027-12-31');
    XFile? selectedImage;
    Uint8List? selectedImageBytes;
    bool removeExistingImage = false;
    
    int selectedCat = product?.categoryId ?? (_selectedCatId > 0 ? _selectedCatId : (_categories.isNotEmpty ? _categories.first.id : 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      product == null ? 'បន្ថែមទំនិញថ្មី (New Product)' : 'កែប្រែទំនិញ (Edit Product)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: selectedImageBytes != null
                              ? Image.memory(
                                  selectedImageBytes!,
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                )
                              : ProductImage(
                                  productId: product?.id,
                                  imageUrl: removeExistingImage
                                      ? null
                                      : product?.imageUrl,
                                  width: 110,
                                  height: 110,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    final picked =
                                        await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 85,
                                      maxWidth: 1600,
                                    );
                                    if (picked == null) return;
                                    final bytes = await picked.readAsBytes();
                                    setModalState(() {
                                      selectedImage = picked;
                                      selectedImageBytes = bytes;
                                      removeExistingImage = false;
                                    });
                                  } catch (error) {
                                    EasyLoading.showError(
                                      'មិនអាចជ្រើសរើសរូបភាពបានទេ: $error',
                                    );
                                  }
                                },
                                icon: const Icon(Icons.photo_library_outlined),
                                label: Text(
                                  product?.imageUrl == null &&
                                          selectedImage == null
                                      ? 'ជ្រើសរើសរូបភាព'
                                      : 'ប្តូររូបភាព',
                                ),
                              ),
                              if (selectedImage != null ||
                                  (product?.imageUrl != null &&
                                      !removeExistingImage))
                                TextButton.icon(
                                  onPressed: () {
                                    setModalState(() {
                                      selectedImage = null;
                                      selectedImageBytes = null;
                                      removeExistingImage = true;
                                    });
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('លុបរូបភាព'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Selector Dropdown
                    if (_categories.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        initialValue: _categories.any((c) => c.id == selectedCat) ? selectedCat : _categories.first.id,
                        decoration: InputDecoration(
                          labelText: 'ប្រភេទទំនិញ (Category)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.category, color: AppColors.primary),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: _categories.map((c) {
                          Color catColor;
                          try {
                            catColor = Color(int.parse(c.colorHex.replaceFirst('#', '0xFF')));
                          } catch (_) {
                            catColor = AppColors.primary;
                          }
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${c.nameKh} (${c.code})',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedCat = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: barcodeCtrl,
                      decoration: const InputDecoration(labelText: 'លេខបាកូដ (Barcode)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameKhCtrl,
                      decoration: const InputDecoration(labelText: 'ឈ្មោះខ្មែរ (Khmer Name)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameEnCtrl,
                      decoration: const InputDecoration(labelText: 'ឈ្មោះឡាតាំង (English Name)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceUsdCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'តម្លៃលក់ (\$)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'ចំនួនស្តុក', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: unitCtrl,
                            decoration: const InputDecoration(labelText: 'ឯកតា (កំប៉ុង/ដប/កញ្ចប់)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: expiryCtrl,
                            decoration: const InputDecoration(labelText: 'ថ្ងៃផុតកំណត់ (YYYY-MM-DD)', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () async {
                        final barcode = barcodeCtrl.text.trim();
                        final nameKh = nameKhCtrl.text.trim();
                        final nameEn = nameEnCtrl.text.trim();
                        final priceUsd = double.tryParse(priceUsdCtrl.text) ?? 0.5;
                        final priceKhr = priceUsd * _martService.exchangeRate;
                        final stock = int.tryParse(stockCtrl.text) ?? 10;

                        if (nameKh.isEmpty) {
                          EasyLoading.showError('សូមបញ្ចូលឈ្មោះទំនិញជាភាសាខ្មែរ');
                          return;
                        }

                        // Lookup category name
                        String catName = '';
                        try {
                          catName = _categories.firstWhere((c) => c.id == selectedCat).nameKh;
                        } catch (_) {}

                        EasyLoading.show(status: 'កំពុងរក្សាទុក...');
                        String? saveError;
                        try {
                          if (product == null) {
                            final newP = ProductModel(
                              id: DateTime.now().millisecondsSinceEpoch,
                              barcode: barcode,
                              nameEn: nameEn.isEmpty ? nameKh : nameEn,
                              nameKh: nameKh,
                              categoryId: selectedCat,
                              categoryName: catName,
                              unit: unitCtrl.text.trim(),
                              sellingPriceUsd: priceUsd,
                              sellingPriceKhr: priceKhr,
                              stockQuantity: stock,
                              expiryDate: expiryCtrl.text.trim(),
                            );
                            await _martService.addProduct(
                              newP,
                              image: selectedImage,
                            );
                          } else {
                            final updated = ProductModel(
                              id: product.id,
                              barcode: barcode,
                              nameEn: nameEn,
                              nameKh: nameKh,
                              categoryId: selectedCat,
                              categoryName: catName,
                              unit: unitCtrl.text.trim(),
                              sellingPriceUsd: priceUsd,
                              sellingPriceKhr: priceKhr,
                              stockQuantity: stock,
                              expiryDate: expiryCtrl.text.trim(),
                              imageUrl:
                                  removeExistingImage ? null : product.imageUrl,
                            );
                            await _martService.updateProduct(
                              updated,
                              image: selectedImage,
                              removeImage: removeExistingImage,
                            );
                          }
                        } catch (error) {
                          saveError = error.toString();
                        } finally {
                          EasyLoading.dismiss();
                        }

                        if (saveError != null) {
                          EasyLoading.showError(
                            'រក្សាទុកមិនបានជោគជ័យ: $saveError',
                          );
                          return;
                        }

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        _loadProducts();
                        EasyLoading.showSuccess('បានរក្សាទុកដោយជោគជ័យ!');
                      },
                      child: const Text('រក្សាទុកទំនិញ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('បញ្ជាក់ការលុប'),
        content: Text('តើអ្នកពិតជាចង់លុបទំនិញ "${product.nameKh}" មែនទេ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('បោះបង់')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _martService.deleteProduct(product.id);
              Navigator.pop(context);
              _loadProducts();
              EasyLoading.showSuccess('បានលុបទំនិញ!');
            },
            child: const Text('លុប', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}