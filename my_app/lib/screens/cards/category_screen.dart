import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/models/mart_models.dart';
import 'package:my_app/services/mart_service.dart';
import 'package:my_app/screens/cards/product_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final MartService _martService = MartService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  final List<String> _availableColors = [
    '#0F766E', // Emerald
    '#0284C7', // Sky Blue
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#10B981', // Green
    '#64748B', // Slate
    '#6366F1', // Indigo
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

  IconData _getIconData(String iconName) {
    return _availableIcons[iconName] ?? Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'ប្រភេទទំនិញម៉ាត (Categories)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'បន្ថែមប្រភេទទំនិញថ្មី',
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 26),
            onPressed: () => _showAddEditCategoryDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'បន្ថែមប្រភេទថ្មី',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showAddEditCategoryDialog(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'មិនទាន់មានប្រភេទទំនិញនៅឡើយទេ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('បង្កើតប្រភេទដំបូង', style: TextStyle(color: Colors.white)),
                        onPressed: () => _showAddEditCategoryDialog(),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.98,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      Color catColor;
                      try {
                        catColor = Color(int.parse(cat.colorHex.replaceFirst('#', '0xFF')));
                      } catch (_) {
                        catColor = AppColors.primary;
                      }

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductScreen(initialCategoryId: cat.id),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: catColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(_getIconData(cat.icon), color: catColor, size: 26),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                                      onSelected: (val) {
                                        if (val == 'view_products') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ProductScreen(initialCategoryId: cat.id),
                                            ),
                                          );
                                        } else if (val == 'edit') {
                                          _showAddEditCategoryDialog(category: cat);
                                        } else if (val == 'delete') {
                                          _confirmDeleteCategory(cat);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'view_products',
                                          child: Row(
                                            children: [
                                              Icon(Icons.inventory, size: 16, color: AppColors.primary),
                                              SizedBox(width: 8),
                                              Text('មើលទំនិញ'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 16),
                                              SizedBox(width: 8),
                                              Text('កែប្រែ'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red, size: 16),
                                              SizedBox(width: 8),
                                              Text('លុប', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              const Spacer(),
                              Text(
                                cat.nameKh,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              ),
                              Text(
                                cat.nameEn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      cat.code,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                    ),
                                  ),
                                  if (cat.productCount > 0)
                                    Text(
                                      '${cat.productCount} មុខ',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  ),
                ),
    );
  }

  void _showAddEditCategoryDialog({CategoryModel? category}) {
    final nameKhCtrl = TextEditingController(text: category?.nameKh ?? '');
    final nameEnCtrl = TextEditingController(text: category?.nameEn ?? '');
    final codeCtrl = TextEditingController(text: category?.code ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    String selectedColor = category?.colorHex ?? _availableColors[0];
    String selectedIcon = category?.icon ?? 'category';

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
                      category == null ? 'បន្ថែមប្រភេទទំនិញថ្មី (Add Category)' : 'កែប្រែប្រភេទទំនិញ (Edit Category)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameKhCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ឈ្មោះខ្មែរ (Khmer Name)',
                        hintText: 'ឧ. គ្រឿងទេស & ទឹកជ្រលក់',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label, color: AppColors.primary),
                      ),
                      onChanged: (val) {
                        // Auto generate code if empty
                        if (codeCtrl.text.isEmpty && val.isNotEmpty) {
                          setModalState(() {
                            codeCtrl.text = 'CAT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: nameEnCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ឈ្មោះឡាតាំង (English Name)',
                        hintText: 'ឧ. Spices & Sauces',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.language, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'កូដសម្គាល់ (Category Code)',
                        hintText: 'ឧ. SPC, BEV, SNK',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Color selection
                    const Text('ជ្រើសរើសពណ៌សម្គាល់ (Color Theme):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableColors.map((hex) {
                        final Color c = Color(int.parse(hex.replaceFirst('#', '0xFF')));
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
                                color: isSel ? Colors.black87 : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: isSel ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Icon selection
                    const Text('ជ្រើសរើសរូបតំណាង (Icon):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                              onTap: () => setModalState(() => selectedIcon = entry.key),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  entry.value,
                                  color: isSel ? Colors.white : AppColors.textPrimary,
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
                      decoration: const InputDecoration(
                        labelText: 'ការពិពណ៌នា (Description - Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                          code = 'CAT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
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
                          );
                          await _martService.updateCategory(updated);
                        }

                        EasyLoading.dismiss();
                        Navigator.pop(context);
                        _loadCategories();
                        EasyLoading.showSuccess('បានរក្សាទុកប្រភេទទំនិញជោគជ័យ!');
                      },
                      child: Text(
                        category == null ? 'រក្សាទុកប្រភេទថ្មី' : 'រក្សាទុកការកែប្រែ',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('បញ្ជាក់ការលុបប្រភេទ'),
        content: Text('តើអ្នកពិតជាចង់លុបប្រភេទ "${catName(category)}" នេះមែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('បោះបង់'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              EasyLoading.show(status: 'កំពុងលុប...');
              await _martService.deleteCategory(category.id);
              EasyLoading.dismiss();
              Navigator.pop(context);
              _loadCategories();
              EasyLoading.showSuccess('បានលុបប្រភេទទំនិញជោគជ័យ!');
            },
            child: const Text('លុប', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String catName(CategoryModel cat) => cat.nameKh.isNotEmpty ? cat.nameKh : cat.nameEn;
}