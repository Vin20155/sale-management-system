import 'package:flutter/material.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/config/app_language.dart';
import 'package:my_app/models/mart_models.dart';
import 'package:my_app/services/mart_service.dart';
import 'package:my_app/widgets/product_image.dart';
import 'package:my_app/screens/inventory/stock_in_dialog.dart';

class ProductDetailSheet extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onStockUpdated;

  const ProductDetailSheet({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onStockUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required ProductModel product,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onStockUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductDetailSheet(
        product: product,
        onEdit: onEdit,
        onDelete: onDelete,
        onStockUpdated: onStockUpdated,
      ),
    );
  }

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  final MartService _martService = MartService();
  List<ProductBatchModel> _batches = [];
  bool _loadingBatches = true;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    final list = await _martService.getProductBatches(widget.product.id);
    if (mounted) {
      setState(() {
        _batches = list;
        _loadingBatches = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = AppLanguage.isEnglish;
    final p = widget.product;
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle & Top Bar
          Container(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEn ? 'Product Details' : 'ព័ត៌មានលម្អិតទំនិញ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content Scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Header with Product Image & Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ProductImage(
                            imageUrl: p.imageUrl,
                            width: 90,
                            height: 90,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    if (p.itemCode.isNotEmpty)
                                      TextSpan(
                                        text: '${p.itemCode}. ',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    TextSpan(
                                      text: isEn
                                          ? (p.nameEn.isNotEmpty ? p.nameEn : p.nameKh)
                                          : (p.nameKh.isNotEmpty ? p.nameKh : p.nameEn),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  // Category Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.category,
                                            size: 11, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          p.categoryName ??
                                              (isEn ? 'General' : 'ទូទៅ'),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Stock Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: p.isLowStock
                                          ? AppColors.danger
                                              .withValues(alpha: 0.12)
                                          : AppColors.success
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      p.isLowStock
                                          ? (isEn ? 'LOW STOCK' : 'ជិតអស់ស្តុក')
                                          : (isEn ? 'IN STOCK' : 'មានក្នុងស្តុក'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: p.isLowStock
                                            ? AppColors.danger
                                            : AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pricing & Stock KPI Cards
                  Row(
                    children: [
                      // Selling Price
                      Expanded(
                        child: _buildKpiCard(
                          title: isEn ? 'Selling Price' : 'តម្លៃលក់',
                          primaryValue: _martService.formatUsd(p.sellingPriceUsd),
                          secondaryValue:
                              _martService.formatKhr(p.sellingPriceKhr),
                          icon: Icons.payments,
                          iconColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Current Stock
                      Expanded(
                        child: _buildKpiCard(
                          title: isEn ? 'Current Stock' : 'ចំនួនស្តុកសរុប',
                          primaryValue: '${p.stockQuantity} ${p.unit}',
                          secondaryValue:
                              '${isEn ? 'Reorder' : 'កម្រិតប្រកាស'}: ${p.reorderLevel} ${p.unit}',
                          icon: Icons.inventory_2,
                          iconColor: p.isLowStock
                              ? AppColors.danger
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Cost Price
                      Expanded(
                        child: _buildKpiCard(
                          title: isEn ? 'Cost Price' : 'តម្លៃដើម',
                          primaryValue: _martService.formatUsd(p.costPriceUsd),
                          secondaryValue:
                              _martService.formatKhr(p.costPriceKhr),
                          icon: Icons.receipt_long,
                          iconColor: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Profit Margin
                      Expanded(
                        child: _buildKpiCard(
                          title: isEn ? 'Est. Margin' : 'ចំណេញប៉ាន់ស្មាន',
                          primaryValue: _martService.formatUsd(
                              (p.sellingPriceUsd - p.costPriceUsd).clamp(0, 9999)),
                          secondaryValue: p.sellingPriceUsd > 0
                              ? '${(((p.sellingPriceUsd - p.costPriceUsd) / p.sellingPriceUsd) * 100).toStringAsFixed(1)}%'
                              : '0%',
                          icon: Icons.trending_up,
                          iconColor: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Specifications Table
                  Text(
                    isEn ? 'Product Information' : 'ព័ត៌មានលម្អិតបច្ចេកទេស',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        if (p.itemCode.isNotEmpty) ...[
                          _buildInfoRow(
                            icon: Icons.tag,
                            label: isEn ? 'Item Code' : 'កូដទំនិញ',
                            value: p.itemCode,
                            isHighlight: true,
                            valueColor: AppColors.primary,
                          ),
                          const Divider(height: 1),
                        ],
                        _buildInfoRow(
                          icon: Icons.qr_code_2,
                          label: isEn ? 'Barcode' : 'លេខកូដបាកូដ',
                          value: p.barcode,
                          isHighlight: true,
                        ),
                        const Divider(height: 1),
                        _buildInfoRow(
                          icon: Icons.straighten,
                          label: isEn ? 'Unit of Measure' : 'ឯកតារាប់',
                          value: p.unit,
                        ),
                        if (p.formattedReceivedDate.isNotEmpty) ...[
                          const Divider(height: 1),
                          _buildInfoRow(
                            icon: Icons.event_available,
                            label: isEn ? 'Received Date' : 'កាលបរិច្ឆេទទទួល',
                            value: p.formattedReceivedDate,
                          ),
                        ],
                        const Divider(height: 1),
                        _buildInfoRow(
                          icon: Icons.event_busy,
                          label: isEn ? 'Current Expiry Date' : 'កាលបរិច្ឆេទផុតកំណត់',
                          value: p.formattedExpiryDate.isNotEmpty
                              ? p.formattedExpiryDate
                              : (isEn ? 'Not Set' : 'មិនកំណត់'),
                          valueColor: p.isExpiringSoon
                              ? AppColors.warning
                              : AppColors.textPrimary,
                        ),
                        const Divider(height: 1),
                        _buildInfoRow(
                          icon: Icons.check_circle_outline,
                          label: isEn ? 'Status' : 'ស្ថានភាពលក់',
                          value: p.isActive
                              ? (isEn ? 'Active' : 'សកម្ម')
                              : (isEn ? 'Inactive' : 'ផ្អាកលក់'),
                          valueColor: p.isActive
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stock Batches / Shipments Section
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEn
                              ? 'Stock Batches'
                              : 'បញ្ជីឡូតិ៍ស្តុក',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          StockInDialog.show(
                            context,
                            product: p,
                            onStockUpdated: () {
                              _loadBatches();
                              widget.onStockUpdated?.call();
                            },
                          );
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(
                          isEn ? 'Stock In' : 'បញ្ចូលស្តុកថ្មី',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (_loadingBatches)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_batches.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          isEn
                              ? 'No individual batches recorded yet.\nClick "+ Stock In" to add a new shipment with expiry date.'
                              : 'មិនទាន់មានទិន្នន័យឡូតិ៍ស្តុកនៅឡើយទេ។\nចុច "+ បញ្ចូលស្តុកថ្មី" ដើម្បីកត់ត្រាការទទួលទំនិញ និងថ្ងៃផុតកំណត់។',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _batches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final b = _batches[idx];
                        final isExp = b.isExpired;
                        final isSoon = b.isExpiringSoon;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isExp
                                ? AppColors.danger.withValues(alpha: 0.04)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isExp
                                  ? AppColors.danger.withValues(alpha: 0.3)
                                  : (isSoon
                                      ? AppColors.warning.withValues(alpha: 0.3)
                                      : Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isExp
                                    ? AppColors.danger.withValues(alpha: 0.15)
                                    : (isSoon
                                        ? AppColors.warning
                                            .withValues(alpha: 0.15)
                                        : AppColors.success
                                            .withValues(alpha: 0.15)),
                                child: Icon(
                                  isExp
                                      ? Icons.warning_amber
                                      : (isSoon
                                          ? Icons.alarm
                                          : Icons.check_circle),
                                  size: 18,
                                  color: isExp
                                      ? AppColors.danger
                                      : (isSoon
                                          ? AppColors.warning
                                          : AppColors.success),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          b.batchNo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (b.supplierName != null &&
                                            b.supplierName!.isNotEmpty)
                                          Expanded(
                                            child: Text(
                                              '(${b.supplierName})',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${isEn ? 'Received' : 'ទទួល'}: ${b.receivedDate}  •  ${isEn ? 'Expiry' : 'ផុតកំណត់'}: ${b.expiryDate ?? (isEn ? 'N/A' : 'គ្មាន')}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isExp
                                            ? AppColors.danger
                                            : (isSoon
                                                ? AppColors.warning
                                                : AppColors.textSecondary),
                                        fontWeight: isExp || isSoon
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${b.quantityRemaining} ${p.unit}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: b.quantityRemaining > 0
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '/${b.quantityReceived} ${p.unit}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Restock / Stock In Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        StockInDialog.show(
                          context,
                          product: p,
                          onStockUpdated: () {
                            _loadBatches();
                            widget.onStockUpdated?.call();
                          },
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: Text(
                        isEn ? 'Stock In' : 'បញ្ចូលស្តុក',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Edit Button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onEdit?.call();
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text(
                        isEn ? 'Edit Info' : 'កែប្រែទំនិញ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String primaryValue,
    required String secondaryValue,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconColor.withValues(alpha: 0.15),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  primaryValue,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  secondaryValue,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
