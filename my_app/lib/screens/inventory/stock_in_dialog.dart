import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/config/app_language.dart';
import 'package:my_app/models/mart_models.dart';
import 'package:my_app/services/mart_service.dart';

class StockInDialog extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onStockUpdated;

  const StockInDialog({
    super.key,
    required this.product,
    this.onStockUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required ProductModel product,
    VoidCallback? onStockUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StockInDialog(
        product: product,
        onStockUpdated: onStockUpdated,
      ),
    );
  }

  @override
  State<StockInDialog> createState() => _StockInDialogState();
}

class _StockInDialogState extends State<StockInDialog> {
  final MartService _martService = MartService();
  final _qtyCtrl = TextEditingController(text: '24');
  final _costCtrl = TextEditingController();
  final _batchNoCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  DateTime _receivedDate = DateTime.now();
  DateTime? _expiryDate;

  List<ProductBatchModel> _existingBatches = [];
  bool _loadingBatches = true;

  @override
  void initState() {
    super.initState();
    _costCtrl.text = widget.product.costPriceUsd > 0
        ? widget.product.costPriceUsd.toStringAsFixed(2)
        : '';
    _batchNoCtrl.text =
        'B${DateFormat('yyMMdd').format(_receivedDate)}-${widget.product.barcode.length > 4 ? widget.product.barcode.substring(widget.product.barcode.length - 4) : '01'}';

    // Default expiry: 1 year from received date if previously had an expiry
    if (widget.product.expiryDate != null &&
        widget.product.expiryDate!.isNotEmpty) {
      try {
        _expiryDate = DateTime.parse(widget.product.expiryDate!);
      } catch (_) {
        _expiryDate = DateTime.now().add(const Duration(days: 365));
      }
    } else {
      _expiryDate = DateTime.now().add(const Duration(days: 365));
    }

    _loadBatches();
  }

  Future<void> _loadBatches() async {
    final list = await _martService.getProductBatches(widget.product.id);
    if (mounted) {
      setState(() {
        _existingBatches = list;
        _loadingBatches = false;
      });
    }
  }

  Future<void> _selectReceivedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _receivedDate = picked;
        _batchNoCtrl.text =
            'B${DateFormat('yyMMdd').format(_receivedDate)}-${widget.product.barcode.length > 4 ? widget.product.barcode.substring(widget.product.barcode.length - 4) : '01'}';
      });
    }
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      EasyLoading.showError(
        AppLanguage.isEnglish
            ? 'Please enter a valid quantity'
            : 'សូមបញ្ចូលចំនួនស្តុកដែលត្រូវបញ្ចូលឱ្យបានត្រឹមត្រូវ',
      );
      return;
    }

    final cost = double.tryParse(_costCtrl.text.trim());
    final receivedStr = DateFormat('yyyy-MM-dd').format(_receivedDate);
    final expiryStr =
        _expiryDate != null ? DateFormat('yyyy-MM-dd').format(_expiryDate!) : null;

    EasyLoading.show(
      status: AppLanguage.isEnglish
          ? 'Recording Stock In...'
          : 'កំពុងកត់ត្រាការបញ្ចូលស្តុក...',
    );

    final success = await _martService.addStockBatch(
      productId: widget.product.id,
      quantity: qty,
      receivedDate: receivedStr,
      expiryDate: expiryStr,
      batchNo: _batchNoCtrl.text.trim().isNotEmpty
          ? _batchNoCtrl.text.trim()
          : null,
      costPriceUsd: cost,
      supplierName: _supplierCtrl.text.trim().isNotEmpty
          ? _supplierCtrl.text.trim()
          : null,
      note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
    );

    EasyLoading.dismiss();

    if (success) {
      EasyLoading.showSuccess(
        AppLanguage.isEnglish
            ? 'Stock received and batch recorded!'
            : 'បានបញ្ចូលស្តុក និងកត់ត្រាឡូតិ៍ជោគជ័យ!',
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onStockUpdated?.call();
      }
    } else {
      EasyLoading.showError(
        AppLanguage.isEnglish
            ? 'Failed to record stock'
            : 'បរាជ័យក្នុងការកត់ត្រាស្តុក',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = AppLanguage.isEnglish;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn
                            ? 'Stock In'
                            : 'កត់ត្រាការបញ្ចូលស្តុក',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${isEn && widget.product.nameEn.isNotEmpty ? widget.product.nameEn : widget.product.nameKh} • ${widget.product.barcode}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const Divider(height: 20),

            // Current Stock Summary Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        isEn ? 'Current Total Stock' : 'ស្តុកសរុបបច្ចុប្បន្ន',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.product.stockQuantity} ${widget.product.unit}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Container(height: 24, width: 1, color: Colors.grey.shade300),
                  Column(
                    children: [
                      Text(
                        isEn ? 'Active Batches' : 'ចំនួនឡូតិ៍សកម្ម',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_existingBatches.where((b) => b.quantityRemaining > 0).length} ${isEn ? 'batches' : 'ឡូតិ៍'}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Form: Quantity & Batch No
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: isEn
                          ? 'Received Quantity (${widget.product.unit}) *'
                          : 'ចំនួនទទួល (${widget.product.unit}) *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.add_shopping_cart, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _batchNoCtrl,
                    decoration: InputDecoration(
                      labelText: isEn ? 'Batch / Lot #' : 'លេខឡូតិ៍ស្តុក',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.tag, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dates: Received Date & Expiry Date (The Critical Tracking Point)
            Row(
              children: [
                // Received Date
                Expanded(
                  child: InkWell(
                    onTap: _selectReceivedDate,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: isEn
                            ? 'Received Date *'
                            : 'កាលបរិច្ឆេទទទួលស្តុក *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(_receivedDate),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Expiry Date
                Expanded(
                  child: InkWell(
                    onTap: _selectExpiryDate,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: isEn
                            ? 'Expiry Date'
                            : 'ថ្ងៃផុតកំណត់',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.event_busy,
                          size: 18,
                          color: AppColors.warning,
                        ),
                      ),
                      child: Text(
                        _expiryDate != null
                            ? DateFormat('yyyy-MM-dd').format(_expiryDate!)
                            : (isEn ? 'Not Set' : 'មិនកំណត់'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _expiryDate != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Cost Price & Supplier
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _costCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isEn ? 'Cost Price (\$)' : 'តម្លៃដើម (\$)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.attach_money, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _supplierCtrl,
                    decoration: InputDecoration(
                      labelText: isEn ? 'Supplier / Source' : 'អ្នកផ្គត់ផ្គង់',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.business, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _submit,
              child: Text(
                isEn
                    ? 'Confirm & Receive Stock'
                    : 'កត់ត្រាបញ្ចូលស្តុក',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Batches History Accordion
            ExpansionTile(
              title: Text(
                isEn
                    ? 'View Existing Shipments / Batches (${_existingBatches.length})'
                    : 'មើលបញ្ជីឡូតិ៍ដែលបានទទួលពីមុន (${_existingBatches.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: false,
              children: [
                if (_loadingBatches)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_existingBatches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      isEn
                          ? 'No recorded batches yet for this product.'
                          : 'មិនទាន់មានទិន្នន័យឡូតិ៍សម្រាប់ទំនិញនេះនៅឡើយទេ។',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _existingBatches.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final b = _existingBatches[idx];
                      final isExp = b.isExpired;
                      final isSoon = b.isExpiringSoon;

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isExp
                              ? AppColors.danger.withValues(alpha: 0.15)
                              : (isSoon
                                  ? AppColors.warning.withValues(alpha: 0.15)
                                  : AppColors.success.withValues(alpha: 0.15)),
                          child: Icon(
                            isExp
                                ? Icons.cancel
                                : (isSoon ? Icons.alarm : Icons.check),
                            size: 16,
                            color: isExp
                                ? AppColors.danger
                                : (isSoon
                                    ? AppColors.warning
                                    : AppColors.success),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              b.batchNo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${b.quantityRemaining} / ${b.quantityReceived} ${widget.product.unit}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: b.quantityRemaining > 0
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${isEn ? 'Received' : 'ទទួល'}: ${b.receivedDate} • ${isEn ? 'Expiry' : 'ផុតកំណត់'}: ${b.expiryDate ?? (isEn ? 'N/A' : 'គ្មាន')}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isExp
                                ? AppColors.danger
                                : (isSoon
                                    ? AppColors.warning
                                    : AppColors.textSecondary),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
