import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/config/app_language.dart';
import 'package:my_app/models/mart_models.dart';
import 'package:my_app/screens/inventory/product_screen.dart';
import 'package:my_app/services/mart_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final MartService _martService = MartService();
  final TextEditingController _searchCtrl = TextEditingController();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  final List<String> _availableColors = [
    '#0F766E',
    '#0284C7',
    '#F59E0B',
    '#EF4444',
    '#8B5CF6',
    '#EC4899',
    '#10B981',
    '#64748B',
    '#6366F1',
  ];

  final Map<String, IconData> _availableIcons = {
    'local_drink': Icons.local_drink,
    'fastfood': Icons.fastfood,
    'icecream': Icons.icecream,
    'lunch_dining': Icons.lunch_dining,
    'bakery_dining': Icons.bakery_dining,
    'clean_hands': Icons.clean_hands,
    'home': Icons.home,
    'shopping_bag': Icons.shopping_bag,
    'restaurant': Icons.restaurant,
    'set_meal': Icons.set_meal,
    'category': Icons.category,
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final cats = await _martService.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    }
  }

  List<CategoryModel> get _filteredCategories {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _categories;

    return _categories.where((category) {
      return category.nameKh.toLowerCase().contains(query) ||
          category.nameEn.toLowerCase().contains(query) ||
          category.code.toLowerCase().contains(query);
    }).toList();
  }

  IconData _getIconData(String iconName) {
    return _availableIcons[iconName] ?? Icons.category;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _filteredCategories;
    final isEn = AppLanguage.isEnglish;

    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          isEn ? 'Product Categories' : 'ប្រភេទទំនិញម៉ាត',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: isEn ? 'Add New Category' : 'បន្ថែមប្រភេទទំនិញថ្មី',
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 26),
            onPressed: () => _showAddEditCategoryDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          isEn ? 'Add Category' : 'បន្ថែមប្រភេទថ្មី',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showAddEditCategoryDialog(),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: isEn ? 'Search by name or code...' : 'ស្វែងរកតាមឈ្មោះ ឬលេខកូដ...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category_outlined,
                                size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              isEn ? 'No categories yet' : 'មិនទាន់មានប្រភេទទំនិញនៅឡើយទេ',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: Text(isEn ? 'Create First Category' : 'បង្កើតប្រភេទដំបូង',
                                  style: const TextStyle(color: Colors.white)),
                              onPressed: () => _showAddEditCategoryDialog(),
                            ),
                          ],
                        ),
                      )
                    : filteredCategories.isEmpty
                        ? Center(
                            child: Text(
                              isEn ? 'No matching categories found' : 'មិនមានប្រភេទដែលត្រូវនឹងការស្វែងរកទេ',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCategories,
                            child: GridView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 80),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.98,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: filteredCategories.length,
                              itemBuilder: (context, index) {
                                final cat = filteredCategories[index];
                                Color catColor;
                                try {
                                  catColor = Color(int.parse(
                                      cat.colorHex.replaceFirst('#', '0xFF')));
                                } catch (_) {
                                  catColor = AppColors.primary;
                                }

                                return Card(
                                  elevation: 1.5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductScreen(
                                              initialCategoryId: cat.id),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: catColor.withValues(
                                                      alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                    _getIconData(cat.icon),
                                                    color: catColor,
                                                    size: 26),
                                              ),
                                              PopupMenuButton<String>(
                                                icon: const Icon(
                                                    Icons.more_vert,
                                                    size: 18,
                                                    color: AppColors
                                                        .textSecondary),
                                                onSelected: (val) {
                                                  if (val == 'view_products') {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ProductScreen(
                                                                initialCategoryId:
                                                                    cat.id),
                                                      ),
                                                    );
                                                  } else if (val == 'edit') {
                                                    _showAddEditCategoryDialog(
                                                        category: cat);
                                                  } else if (val == 'delete') {
                                                    _confirmDeleteCategory(cat);
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: 'view_products',
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.inventory,
                                                            size: 16,
                                                            color: AppColors
                                                                .primary),
                                                        const SizedBox(width: 8),
                                                        Text(isEn ? 'View Products' : 'មើលទំនិញ'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.edit,
                                                            size: 16),
                                                        const SizedBox(width: 8),
                                                        Text(isEn ? 'Edit' : 'កែប្រែ'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.delete,
                                                            color: Colors.red,
                                                            size: 16),
                                                        const SizedBox(width: 8),
                                                        Text(isEn ? 'Delete' : 'លុប',
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .red)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Text(
                                            isEn && cat.nameEn.isNotEmpty ? cat.nameEn : cat.nameKh,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  cat.code,
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors
                                                          .textSecondary),
                                                ),
                                              ),
                                              if (cat.productCount > 0)
                                                Text(
                                                  '${cat.productCount} ${isEn ? 'items' : 'មុខ'}',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                            ],
                                          ),
                                          if (cat.units.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '${isEn ? 'Units' : 'ឯកតា'}: ${cat.units.join(", ")}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                color: catColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _showAddEditCategoryDialog({CategoryModel? category}) {
    final nameKhCtrl = TextEditingController(text: category?.nameKh ?? '');
    final nameEnCtrl = TextEditingController(text: category?.nameEn ?? '');
    final codeCtrl = TextEditingController(text: category?.code ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    final newUnitCtrl = TextEditingController();
    final isEn = AppLanguage.isEnglish;
    String selectedColor = category?.colorHex ?? _availableColors[0];
    String selectedIcon = category?.icon ?? 'category';

    List<String> units = category != null && category.units.isNotEmpty
        ? List<String>.from(category.units)
        : ['កំប៉ុង', 'ដប', 'កញ្ចប់', 'ប្រអប់'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                      category == null
                          ? (isEn ? 'Add Category' : 'បន្ថែមប្រភេទទំនិញថ្មី')
                          : (isEn ? 'Edit Category' : 'កែប្រែប្រភេទទំនិញ'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameKhCtrl,
                      decoration: InputDecoration(
                        labelText: isEn ? 'Khmer Name' : 'ឈ្មោះខ្មែរ',
                        hintText: isEn ? 'e.g. Spices' : 'ឧ. គ្រឿងទេស',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.label, color: AppColors.primary),
                      ),
                      onChanged: (val) {
                        // Auto generate code if empty
                        if (codeCtrl.text.isEmpty && val.isNotEmpty) {
                          setModalState(() {
                            codeCtrl.text =
                                'CAT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: nameEnCtrl,
                      decoration: InputDecoration(
                        labelText: isEn ? 'English Name' : 'ឈ្មោះឡាតាំង',
                        hintText: isEn ? 'e.g. Spices & Sauces' : 'ឧ. Spices & Sauces',
                        border: const OutlineInputBorder(),
                        prefixIcon:
                            const Icon(Icons.language, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: isEn ? 'Category Code' : 'កូដសម្គាល់',
                        hintText: isEn ? 'e.g. BEV, SNK' : 'ឧ. BEV, SNK',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.tag, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Color selection
                    Text(
                        isEn ? 'Select Color Theme:' : 'ជ្រើសរើសពណ៌សម្គាល់:',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableColors.map((hex) {
                        final Color c =
                            Color(int.parse(hex.replaceFirst('#', '0xFF')));
                        final bool isSel = selectedColor == hex;
                        return InkWell(
                          onTap: () => setModalState(() => selectedColor = hex),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isSel ? Colors.black87 : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: isSel
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Icon selection
                    Text(isEn ? 'Select Icon:' : 'ជ្រើសរើសរូបតំណាង:',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _availableIcons.entries.map((entry) {
                          final bool isSel = selectedIcon == entry.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () =>
                                  setModalState(() => selectedIcon = entry.key),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  entry.value,
                                  color: isSel
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  size: 22,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: isEn ? 'Description (Optional)' : 'ការពិពណ៌នា (មិនបង្ខំ)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Units Management Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEn ? 'Units in this Category:' : 'ឯកតារាប់ទំនិញ:',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${units.length} ${isEn ? 'units' : 'ឯកតា'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Quick add unit input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newUnitCtrl,
                            decoration: InputDecoration(
                              hintText: isEn ? 'Enter unit (e.g. Can, Bottle, Box, Kg)' : 'បញ្ចូលឯកតាថ្មី (ឧ. កំប៉ុង, ដប, កេស, គីឡូ)',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onSubmitted: (val) {
                              final text = val.trim();
                              if (text.isNotEmpty && !units.contains(text)) {
                                setModalState(() {
                                  units.add(text);
                                  newUnitCtrl.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            final text = newUnitCtrl.text.trim();
                            if (text.isNotEmpty && !units.contains(text)) {
                              setModalState(() {
                                units.add(text);
                                newUnitCtrl.clear();
                              });
                            }
                          },
                          child: Text(
                            isEn ? '+ Add' : '+ បន្ថែម',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Display chips for current units
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: units.map((u) {
                        return Chip(
                          label: Text(
                            u,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          deleteIconColor: AppColors.danger,
                          onDeleted: () {
                            setModalState(() {
                              units.remove(u);
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final nameKh = nameKhCtrl.text.trim();
                        final nameEn = nameEnCtrl.text.trim();
                        String code = codeCtrl.text.trim().toUpperCase();

                        if (nameKh.isEmpty) {
                          EasyLoading.showError('សូមបញ្ចូលឈ្មោះខ្មែរ');
                          return;
                        }

                        if (code.isEmpty) {
                          code =
                              'CAT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                        }

                        EasyLoading.show(status: 'កំពុងរក្សាទុក...');

                        if (category == null) {
                          final newCat = CategoryModel(
                            id: DateTime.now().millisecondsSinceEpoch,
                            nameEn: nameEn.isEmpty ? nameKh : nameEn,
                            nameKh: nameKh,
                            code: code,
                            icon: selectedIcon,
                            colorHex: selectedColor,
                            description: descCtrl.text.trim(),
                            units: units,
                          );
                          await _martService.addCategory(newCat);
                        } else {
                          final updated = CategoryModel(
                            id: category.id,
                            nameEn: nameEn.isEmpty ? nameKh : nameEn,
                            nameKh: nameKh,
                            code: code,
                            icon: selectedIcon,
                            colorHex: selectedColor,
                            description: descCtrl.text.trim(),
                            productCount: category.productCount,
                            units: units,
                          );
                          await _martService.updateCategory(updated);
                        }

                        EasyLoading.dismiss();
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        _loadCategories();
                        EasyLoading.showSuccess(
                            'បានរក្សាទុកប្រភេទទំនិញជោគជ័យ!');
                      },
                      child: Text(
                        category == null
                            ? (isEn ? 'Save Category' : 'រក្សាទុកប្រភេទថ្មី')
                            : (isEn ? 'Save Changes' : 'រក្សាទុកការកែប្រែ'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
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

  void _confirmDeleteCategory(CategoryModel category) {
    final isEn = AppLanguage.isEnglish;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEn ? 'Confirm Delete Category' : 'បញ្ជាក់ការលុបប្រភេទ'),
        content:
            Text(isEn
                ? 'Are you sure you want to delete "${catName(category)}"?'
                : 'តើអ្នកពិតជាចង់លុបប្រភេទ "${catName(category)}" នេះមែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isEn ? 'Cancel' : 'បោះបង់'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              EasyLoading.show(status: isEn ? 'Deleting...' : 'កំពុងលុប...');
              await _martService.deleteCategory(category.id);
              EasyLoading.dismiss();
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadCategories();
              EasyLoading.showSuccess(isEn ? 'Category deleted successfully!' : 'បានលុបប្រភេទទំនិញជោគជ័យ!');
            },
            child: Text(isEn ? 'Delete' : 'លុប', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String catName(CategoryModel cat) =>
      cat.nameKh.isNotEmpty ? cat.nameKh : cat.nameEn;
}
