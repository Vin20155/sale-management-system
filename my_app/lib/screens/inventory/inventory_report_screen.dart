import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/config/app_language.dart';
import 'package:my_app/models/mart_models.dart';
import 'package:my_app/services/mart_service.dart';
import 'package:my_app/utils/invoice_printer.dart';
import 'package:my_app/widgets/product_image.dart';

class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({super.key});

  @override
  State<InventoryReportScreen> createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
  final MartService _martService = MartService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  Map<int, int> _soldQtyByProductId = {};
  bool _isLoading = true;

  // Expiry / Date filters: 'all', 'expiring_soon', 'custom_date', 'custom_range'
  String _expiryFilter = 'all';
  DateTime? _selectedDate;
  DateTimeRange? _selectedRange;
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 6, minute: 0);
  List<OrderModel> _allOrders = [];

  // Stock status filters: 'all', 'healthy', 'low', 'out'
  String _stockFilter = 'all';

  // Category filter: 0 = All
  int _selectedCategoryId = 0;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatYmd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _cleanExpiry(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    if (raw.length >= 10) return raw.substring(0, 10);
    return raw;
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    final minute = t.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }

  void _recalculateSoldMap() {
    final Map<int, int> soldMap = {};
    for (final order in _allOrders) {
      if (order.isVoided) continue;
      if (_expiryFilter == 'custom_range' && _selectedRange != null) {
        final startDt = DateTime(
          _selectedRange!.start.year,
          _selectedRange!.start.month,
          _selectedRange!.start.day,
          _startTime.hour,
          _startTime.minute,
        );
        final endDt = DateTime(
          _selectedRange!.end.year,
          _selectedRange!.end.month,
          _selectedRange!.end.day,
          _endTime.hour,
          _endTime.minute,
        );
        final orderDt = DateTime.tryParse(order.createdAt.replaceAll('/', '-'));
        if (orderDt != null) {
          if (orderDt.isBefore(startDt) || orderDt.isAfter(endDt)) {
            continue;
          }
        }
      }
      for (final item in order.items) {
        soldMap[item.productId] =
            (soldMap[item.productId] ?? 0) + item.quantity;
      }
    }
    _soldQtyByProductId = soldMap;
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    final cats = await _martService.getCategories();
    final prods = await _martService.getProducts();
    final orders = await _martService.getOrders();

    if (mounted) {
      setState(() {
        _categories = cats;
        _products = List<ProductModel>.from(prods);
        _allOrders = List<OrderModel>.from(orders);
        _recalculateSoldMap();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickSingleExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _expiryFilter = 'custom_date';
        _recalculateSoldMap();
      });
    }
  }

  Future<void> _pickExpiryRange() async {
    // If range is already active, open the Date & Time Range bottom sheet directly
    if (_expiryFilter == 'custom_range' && _selectedRange != null) {
      await _showDateTimeRangePickerSheet();
      return;
    }

    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedRange ??
          DateTimeRange(
            start: now,
            end: now.add(const Duration(days: 1)),
          ),
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      // Prompt user to select/confirm time range as well
      await _showDateTimeRangePickerSheet(initialPicked: picked);
    }
  }

  Future<void> _showDateTimeRangePickerSheet(
      {DateTimeRange? initialPicked}) async {
    final bool isEn = AppLanguage.isEnglish;
    final now = DateTime.now();

    DateTime start = initialPicked?.start ??
        _selectedRange?.start ??
        now;
    DateTime end = initialPicked?.end ??
        _selectedRange?.end ??
        now.add(const Duration(days: 1));
    TimeOfDay sTime = _startTime;
    TimeOfDay eTime = _endTime;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            String formatD(DateTime dt) =>
                '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.schedule_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isEn
                              ? 'Select Date & Time Range'
                              : 'ជ្រើសរើសចន្លោះកាលបរិច្ឆេទ & ម៉ោង',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Date Range Row
                  Text(
                    isEn ? 'DATE RANGE' : 'ចន្លោះកាលបរិច្ឆេទ',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        initialDateRange:
                            DateTimeRange(start: start, end: end),
                        firstDate: DateTime(2023),
                        lastDate: DateTime(now.year + 5),
                        builder: (c, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          start = picked.start;
                          end = picked.end;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${formatD(start)}   →   ${formatD(end)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            isEn ? 'Change Dates' : 'ប្តូរថ្ងៃ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Time Range Selection
                  Text(
                    isEn
                        ? 'TIME RANGE (START & END TIME)'
                        : 'ចន្លោះម៉ោង (START & END TIME)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Start Time Card
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: sTime,
                            );
                            if (pickedTime != null) {
                              setModalState(() => sTime = pickedTime);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEn ? 'Start Time' : 'ម៉ោងចាប់ផ្តើម',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded,
                                        size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatTimeOfDay(sTime),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // End Time Card
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: eTime,
                            );
                            if (pickedTime != null) {
                              setModalState(() => eTime = pickedTime);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEn ? 'End Time' : 'ម៉ោងបញ្ចប់',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                        Icons.access_time_filled_rounded,
                                        size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatTimeOfDay(eTime),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. Shift Presets
                  Text(
                    isEn ? 'SHIFT PRESETS' : 'ជម្រើសម៉ោងវេនលក់',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.bolt,
                            size: 14, color: AppColors.primary),
                        label: const Text(
                            '06:00 AM → 06:00 AM (Next Day Shift)'),
                        labelStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                        onPressed: () {
                          setModalState(() {
                            sTime = const TimeOfDay(hour: 6, minute: 0);
                            eTime = const TimeOfDay(hour: 6, minute: 0);
                            if (end.isBefore(
                                start.add(const Duration(days: 1)))) {
                              end = start.add(const Duration(days: 1));
                            }
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('08:00 AM → 10:00 PM (Day Shift)'),
                        labelStyle: const TextStyle(fontSize: 11),
                        backgroundColor: Colors.white,
                        onPressed: () {
                          setModalState(() {
                            sTime = const TimeOfDay(hour: 8, minute: 0);
                            eTime = const TimeOfDay(hour: 22, minute: 0);
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('12:00 AM → 11:59 PM (Full Day)'),
                        labelStyle: const TextStyle(fontSize: 11),
                        backgroundColor: Colors.white,
                        onPressed: () {
                          setModalState(() {
                            sTime = const TimeOfDay(hour: 0, minute: 0);
                            eTime = const TimeOfDay(hour: 23, minute: 59);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. Apply Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text(
                      isEn
                          ? 'Apply Date & Time Range'
                          : 'អនុវត្តចន្លោះកាលបរិច្ឆេទ & ម៉ោង',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(modalContext);
                      setState(() {
                        _selectedRange =
                            DateTimeRange(start: start, end: end);
                        _startTime = sTime;
                        _endTime = eTime;
                        _expiryFilter = 'custom_range';
                        _recalculateSoldMap();
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _activeFilterLabel(bool isEn) {
    String expPart;
    switch (_expiryFilter) {
      case 'expiring_soon':
        expPart = isEn ? 'Expiring Soon (≤60d)' : 'ជិតផុតកំណត់ (≤60ថ្ងៃ)';
        break;
      case 'custom_date':
        final d = _selectedDate != null ? _formatYmd(_selectedDate!) : '';
        expPart = isEn ? 'Expiry: $d' : 'ផុតកំណត់: $d';
        break;
      case 'custom_range':
        if (_selectedRange == null) {
          expPart = isEn ? 'Date & Time Range' : 'ចន្លោះថ្ងៃ & ម៉ោង';
        } else {
          final s = _formatYmd(_selectedRange!.start);
          final e = _formatYmd(_selectedRange!.end);
          final st = _formatTimeOfDay(_startTime);
          final et = _formatTimeOfDay(_endTime);
          expPart = '$s ($st) → $e ($et)';
        }
        break;
      case 'all':
      default:
        expPart = isEn ? 'All Products' : 'ទំនិញទាំងអស់';
        break;
    }

    if (_selectedCategoryId != 0) {
      try {
        final cat =
            _categories.firstWhere((c) => c.id == _selectedCategoryId);
        final catName =
            isEn && cat.nameEn.isNotEmpty ? cat.nameEn : cat.nameKh;
        return '$expPart • $catName';
      } catch (_) {}
    }
    return expPart;
  }

  List<ProductModel> get _filteredProducts {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _products.where((p) {
      // 1. Category filter
      if (_selectedCategoryId != 0 && p.categoryId != _selectedCategoryId) {
        return false;
      }

      // 2. Stock status filter
      if (_stockFilter == 'out') {
        if (p.stockQuantity > 0) return false;
      } else if (_stockFilter == 'low') {
        if (!p.isLowStock) return false;
      } else if (_stockFilter == 'healthy') {
        if (p.isLowStock) return false;
      }

      // 3. Expiry date filter
      final expStr = _cleanExpiry(p.expiryDate);
      if (_expiryFilter == 'expiring_soon') {
        if (!p.isExpiringSoon) return false;
      } else if (_expiryFilter == 'custom_date' && _selectedDate != null) {
        if (expStr != _formatYmd(_selectedDate!)) return false;
      } else if (_expiryFilter == 'custom_range' && _selectedRange != null) {
        if (expStr == '-') return false;
        final startStr = _formatYmd(_selectedRange!.start);
        final endStr = _formatYmd(_selectedRange!.end);
        if (expStr.compareTo(startStr) < 0 || expStr.compareTo(endStr) > 0) {
          return false;
        }
      }

      // 4. Search query (Name KH, Name EN, Barcode, Category)
      if (query.isNotEmpty) {
        final matchKh = p.nameKh.toLowerCase().contains(query);
        final matchEn = p.nameEn.toLowerCase().contains(query);
        final matchBarcode = p.barcode.toLowerCase().contains(query);
        final matchCat =
            (p.categoryName ?? '').toLowerCase().contains(query);
        if (!matchKh && !matchEn && !matchBarcode && !matchCat) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  String _stockStatusLabel(ProductModel p, bool isEn) {
    if (p.stockQuantity <= 0) {
      return isEn ? 'OUT OF STOCK' : 'អស់ពីស្តុក';
    }
    if (p.isLowStock) {
      return isEn ? 'LOW STOCK' : 'ជិតអស់ស្តុក';
    }
    return isEn ? 'IN STOCK' : 'ស្តុកគ្រប់គ្រាន់';
  }

  Color _stockStatusColor(ProductModel p) {
    if (p.stockQuantity <= 0) return AppColors.danger;
    if (p.isLowStock) return AppColors.warning;
    return AppColors.success;
  }

  Future<void> _copyProductText(ProductModel p, bool isEn) async {
    final stockValUsd = p.stockQuantity * p.sellingPriceUsd;
    final stockValKhr = p.stockQuantity * p.sellingPriceKhr;
    final text = StringBuffer()
      ..writeln('Product: ${p.nameKh} (${p.nameEn})')
      ..writeln('Barcode: ${p.barcode}')
      ..writeln('Category: ${p.categoryName ?? '-'}')
      ..writeln(
          'Stock: ${p.stockQuantity} ${p.unit} (${_stockStatusLabel(p, true)})')
      ..writeln(
          'Unit Price: ${_martService.formatUsd(p.sellingPriceUsd)} (${_martService.formatKhr(p.sellingPriceKhr)})')
      ..writeln(
          'Total Stock Value: ${_martService.formatUsd(stockValUsd)} (${_martService.formatKhr(stockValKhr)})')
      ..writeln('Expiry Date: ${_cleanExpiry(p.expiryDate)}');

    await Clipboard.setData(ClipboardData(text: text.toString()));
    EasyLoading.showSuccess(
      isEn ? 'Copied product stock info!' : 'បានចម្លងព័ត៌មានស្តុកទំនិញ!',
    );
  }

  Future<void> _printSingleProductSlip(ProductModel p) async {
    final bool isEn = AppLanguage.isEnglish;
    final setting = _martService.getSettings();
    final stockValUsd = p.stockQuantity * p.sellingPriceUsd;
    final stockValKhr = p.stockQuantity * p.sellingPriceKhr;

    final htmlDoc = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Stock Slip ${p.barcode}</title>
  <style>
    @page { size: 80mm auto; margin: 4mm; }
    body {
      font-family: 'Segoe UI', Tahoma, sans-serif;
      width: 76mm;
      margin: 0 auto;
      padding: 8px;
      color: #111;
      font-size: 12px;
    }
    .center { text-align: center; }
    .divider { border-top: 1px dashed #666; margin: 8px 0; }
    .meta-row { display: flex; justify-content: space-between; margin: 3px 0; font-size: 11px; }
    .total-row { display: flex; justify-content: space-between; margin: 5px 0; font-weight: bold; font-size: 13px; }
    @media print { .no-print { display: none; } }
  </style>
</head>
<body onload="window.print();">
  <div class="no-print" style="text-align:center;margin-bottom:10px;">
    <button onclick="window.print();" style="padding:6px 14px;background:#0F766E;color:#fff;border:none;border-radius:6px;cursor:pointer;font-weight:bold;">
      🖨️ Print Stock Slip
    </button>
  </div>
  <div class="center">
    <div style="font-size:15px;font-weight:bold;">${setting.martNameKh}</div>
    <div style="font-size:11px;color:#555;">INVENTORY STOCK CARD</div>
  </div>
  <div class="divider"></div>
  <div style="font-size:14px;font-weight:bold;">${p.nameKh}</div>
  <div style="font-size:12px;color:#555;">${p.nameEn}</div>
  <div class="divider"></div>
  <div class="meta-row"><span>Barcode:</span><strong>${p.barcode}</strong></div>
  <div class="meta-row"><span>Category:</span><span>${p.categoryName ?? '-'}</span></div>
  <div class="meta-row"><span>Status:</span><strong>${_stockStatusLabel(p, isEn)}</strong></div>
  <div class="meta-row"><span>Expiry Date:</span><span>${_cleanExpiry(p.expiryDate)}</span></div>
  <div class="divider"></div>
  <div class="meta-row"><span>Unit Price (USD):</span><span>${_martService.formatUsd(p.sellingPriceUsd)}</span></div>
  <div class="meta-row"><span>Unit Price (KHR):</span><span>${_martService.formatKhr(p.sellingPriceKhr)}</span></div>
  <div class="total-row"><span>Current Stock:</span><span>${p.stockQuantity} ${p.unit}</span></div>
  <div class="total-row"><span>Stock Value (USD):</span><span>${_martService.formatUsd(stockValUsd)}</span></div>
  <div class="meta-row"><span>Stock Value (KHR):</span><strong>${_martService.formatKhr(stockValKhr)}</strong></div>
</body>
</html>
''';

    final opened =
        await triggerPlatformPrintHtml(htmlDoc, 'Stock_${p.barcode}');
    if (opened == null) {
      await _copyProductText(p, isEn);
    }
  }

  String _buildCsvContent(List<ProductModel> filtered, bool isEn) {
    final setting = _martService.getSettings();
    final int totalUnitsSold =
        filtered.fold(0, (sum, p) => sum + (_soldQtyByProductId[p.id] ?? 0));
    final int lowStockCount = filtered.where((p) => p.isLowStock).length;
    final int outOfStockCount =
        filtered.where((p) => p.stockQuantity <= 0).length;
    final int expiringCount = filtered.where((p) => p.isExpiringSoon).length;
    final double totalSoldRevenueUsd = filtered.fold(0.0,
        (sum, p) => sum + ((_soldQtyByProductId[p.id] ?? 0) * p.sellingPriceUsd));
    final double totalSoldRevenueKhr = filtered.fold(0.0,
        (sum, p) => sum + ((_soldQtyByProductId[p.id] ?? 0) * p.sellingPriceKhr));

    String esc(Object? val) {
      final str = (val ?? '').toString().replaceAll('"', '""');
      return '"$str"';
    }

    String row(List<Object?> cells) => cells.map(esc).join(',');

    final nowStr = DateTime.now().toString().substring(0, 19);
    final csv = StringBuffer();

    // 1. Store & Inventory Report Metadata Header
    csv.writeln(row([
      isEn ? 'STORE NAME' : 'ឈ្មោះហាង',
      '${setting.martNameKh} (${setting.martNameEn})',
      isEn ? 'BRANCH' : 'សាខា',
      setting.branchName,
    ]));
    csv.writeln(row([
      isEn ? 'REPORT TYPE' : 'ប្រភេទរបាយការណ៍',
      isEn ? 'INVENTORY & STOCK VALUATION REPORT' : 'របាយការណ៍ស្តុកទំនិញទាំងអស់',
      isEn ? 'EXPORTED AT' : 'ទាញយកនៅម៉ោង',
      nowStr,
    ]));
    csv.writeln(row([
      isEn ? 'FILTER' : 'តម្រង',
      _activeFilterLabel(isEn),
      isEn ? 'EXCHANGE RATE' : 'អត្រាប្តូរប្រាក់',
      '1 USD = ${_martService.exchangeRate.round()} KHR',
    ]));
    csv.writeln();

    // 2. Summary Totals Block
    csv.writeln(row([
      isEn ? 'INVENTORY SUMMARY' : 'របាយការណ៍សង្ខេបស្តុក',
      isEn ? 'COUNT / UNITS' : 'ចំនួន',
      isEn ? 'SOLD AMOUNT (USD)' : 'ទឹកប្រាក់លក់ (USD)',
      isEn ? 'SOLD AMOUNT (KHR)' : 'ទឹកប្រាក់លក់ (KHR)',
    ]));
    csv.writeln(row([
      isEn ? 'Total Products (SKUs)' : 'មុខទំនិញសរុប (SKUs)',
      '${filtered.length} SKUs ($totalUnitsSold Sold)',
      totalSoldRevenueUsd.toStringAsFixed(2),
      totalSoldRevenueKhr.round(),
    ]));
    csv.writeln(row([
      isEn ? 'Low Stock Products' : 'ទំនិញជិតអស់ស្តុក',
      '$lowStockCount SKUs ($outOfStockCount Out of Stock)',
      '',
      '',
    ]));
    csv.writeln(row([
      isEn ? 'Expiring Soon Products' : 'ទំនិញជិតផុតកំណត់',
      '$expiringCount SKUs',
      '',
      '',
    ]));
    csv.writeln();

    // 3. Products Table Header
    csv.writeln(row([
      'No.',
      isEn ? 'Barcode' : 'លេខបាកូដ',
      isEn ? 'Product Name (KH)' : 'ឈ្មោះទំនិញ (ខ្មែរ)',
      isEn ? 'Product Name (EN)' : 'ឈ្មោះទំនិញ (អង់គ្លេស)',
      isEn ? 'Category' : 'ប្រភេទទំនិញ',
      isEn ? 'Status' : 'ស្ថានភាពស្តុក',
      isEn ? 'Quantity Sold' : 'ចំនួនលក់',
      isEn ? 'Stock Qty' : 'ចំនួនស្តុក',
      isEn ? 'Unit' : 'ឯកតា',
      isEn ? 'Reorder Level' : 'កម្រិតប្រកាសអាសន្ន',
      isEn ? 'Unit Price (USD)' : 'តម្លៃរាយ (\$)',
      isEn ? 'Unit Price (KHR)' : 'តម្លៃរាយ (៛)',
      isEn ? 'Sold Total (USD)' : 'សរុបលក់ (\$)',
      isEn ? 'Sold Total (KHR)' : 'សរុបលក់ (៛)',
      isEn ? 'Expiry Date' : 'ថ្ងៃផុតកំណត់',
    ]));

    // 4. Product Rows
    for (int i = 0; i < filtered.length; i++) {
      final p = filtered[i];
      final soldQty = _soldQtyByProductId[p.id] ?? 0;
      final valUsd = soldQty * p.sellingPriceUsd;
      final valKhr = soldQty * p.sellingPriceKhr;

      csv.writeln(row([
        i + 1,
        p.barcode,
        p.nameKh,
        p.nameEn,
        p.categoryName ?? (isEn ? 'General' : 'ទូទៅ'),
        _stockStatusLabel(p, isEn),
        soldQty,
        p.stockQuantity,
        p.unit,
        p.reorderLevel,
        p.sellingPriceUsd.toStringAsFixed(2),
        p.sellingPriceKhr.round(),
        valUsd.toStringAsFixed(2),
        valKhr.round(),
        _cleanExpiry(p.expiryDate),
      ]));
    }

    // 5. Aligned Footer Totals Row
    csv.writeln();
    csv.writeln(row([
      '',
      isEn ? 'TOTAL SOLD SALES' : 'សរុបការលក់ទាំងអស់',
      '${filtered.length} SKUs',
      '',
      '',
      '$lowStockCount Low / $expiringCount Exp',
      totalUnitsSold,
      '',
      '',
      '',
      '',
      totalSoldRevenueUsd.toStringAsFixed(2),
      totalSoldRevenueKhr.round(),
      '',
    ]));

    return csv.toString();
  }

  Future<void> _exportInventoryCsv(List<ProductModel> filtered) async {
    final bool isEn = AppLanguage.isEnglish;
    if (filtered.isEmpty) {
      EasyLoading.showInfo(
        isEn ? 'No products to export' : 'មិនមានទំនិញសម្រាប់ទាញយកទេ',
      );
      return;
    }

    final csvContent = _buildCsvContent(filtered, isEn);
    final fileName = 'inventory_report_${_formatYmd(DateTime.now())}.csv';
    final savedLocation =
        await triggerPlatformDownloadCsv(csvContent, fileName);
    await Clipboard.setData(ClipboardData(text: csvContent));

    if (!mounted) return;
    _showCsvExportResultDialog(
      filtered: filtered,
      csvContent: csvContent,
      fileName: fileName,
      savedLocation: savedLocation,
    );
  }

  void _showCsvExportResultDialog({
    required List<ProductModel> filtered,
    required String csvContent,
    required String fileName,
    required String? savedLocation,
  }) {
    final bool isEn = AppLanguage.isEnglish;
    final int totalUnitsSold =
        filtered.fold(0, (sum, p) => sum + (_soldQtyByProductId[p.id] ?? 0));
    final int lowStockCount = filtered.where((p) => p.isLowStock).length;
    final int expiringCount = filtered.where((p) => p.isExpiringSoon).length;
    final double totalSoldRevenueUsd = filtered.fold(0.0,
        (sum, p) => sum + ((_soldQtyByProductId[p.id] ?? 0) * p.sellingPriceUsd));
    final double totalSoldRevenueKhr = filtered.fold(0.0,
        (sum, p) => sum + ((_soldQtyByProductId[p.id] ?? 0) * p.sellingPriceKhr));

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
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
                                  ? 'Inventory CSV Ready'
                                  : 'ទាញយករបាយការណ៍ស្តុក CSV រួចរាល់',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isEn
                                  ? 'Saved & copied to clipboard for Excel'
                                  : 'បានរក្សាទុក និងចម្លងសម្រាប់ Excel',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close,
                            size: 20, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.table_chart_outlined,
                            size: 17, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildMetaRow(
                          isEn ? 'Filter:' : 'តម្រង:',
                          _activeFilterLabel(isEn),
                          isBold: true,
                        ),
                        _buildMetaRow(
                          isEn ? 'Total Products:' : 'ចំនួនទំនិញ:',
                          '${filtered.length} SKUs ($totalUnitsSold ${isEn ? 'sold' : 'លក់បាន'})',
                        ),
                        _buildMetaRow(
                          isEn ? 'Low Stock / Expiring:' : 'ជិតអស់ / ជិតផុតកំណត់:',
                          '$lowStockCount ${isEn ? 'low' : 'ជិតអស់'} • $expiringCount ${isEn ? 'expiring' : 'ជិតផុត'}',
                        ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEn ? 'Total Sold Revenue:' : 'ចំណូលលក់សរុប:',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '${_martService.formatUsd(totalSoldRevenueUsd)} (${_martService.formatKhr(totalSoldRevenueKhr)})',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEn
                        ? 'Exported Products (${filtered.length})'
                        : 'បញ្ជីទំនិញក្នុងឯកសារ (${filtered.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 165),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 10, color: Colors.grey.shade100),
                      itemBuilder: (context, idx) {
                        final p = filtered[idx];
                        final valUsd = p.stockQuantity * p.sellingPriceUsd;
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEn && p.nameEn.isNotEmpty
                                        ? p.nameEn
                                        : p.nameKh,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${p.barcode} • ${p.stockQuantity} ${p.unit} × ${_martService.formatUsd(p.sellingPriceUsd)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _martService.formatUsd(valUsd),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded,
                        size: 18, color: Colors.white),
                    label: Text(
                      isEn
                          ? 'Download CSV File Again'
                          : 'ទាញយកឯកសារ CSV ម្តងទៀត',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      await triggerPlatformDownloadCsv(csvContent, fileName);
                      EasyLoading.showSuccess(
                        isEn
                            ? 'Downloaded $fileName!'
                            : 'បានទាញយក $fileName!',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                                color:
                                    AppColors.primary.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.copy_all_rounded, size: 16),
                          label: Text(
                            isEn ? 'Copy CSV' : 'ចម្លង CSV',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () async {
                            await Clipboard.setData(
                                ClipboardData(text: csvContent));
                            EasyLoading.showSuccess(
                              isEn ? 'CSV copied!' : 'បានចម្លង CSV!',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            isEn ? 'Close' : 'បិទ',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _printInventoryReport(List<ProductModel> filtered) async {
    final bool isEn = AppLanguage.isEnglish;
    final setting = _martService.getSettings();

    // Fetch orders to calculate real sold quantities per product
    final orders = await _martService.getOrders();
    final Map<int, int> soldQtyByProductId = {};
    for (final order in orders) {
      if (order.isVoided) continue;
      if (_expiryFilter == 'custom_range' && _selectedRange != null) {
        final startDt = DateTime(
          _selectedRange!.start.year,
          _selectedRange!.start.month,
          _selectedRange!.start.day,
          _startTime.hour,
          _startTime.minute,
        );
        final endDt = DateTime(
          _selectedRange!.end.year,
          _selectedRange!.end.month,
          _selectedRange!.end.day,
          _endTime.hour,
          _endTime.minute,
        );
        final orderDt = DateTime.tryParse(order.createdAt.replaceAll('/', '-'));
        if (orderDt != null) {
          if (orderDt.isBefore(startDt) || orderDt.isAfter(endDt)) {
            continue;
          }
        }
      }
      for (final item in order.items) {
        soldQtyByProductId[item.productId] =
            (soldQtyByProductId[item.productId] ?? 0) + item.quantity;
      }
    }

    // Group products by Category
    final Map<String, List<ProductModel>> grouped = {};
    for (final p in filtered) {
      final cat = p.categoryName != null && p.categoryName!.isNotEmpty
          ? p.categoryName!
          : (isEn ? 'GENERAL' : 'ទូទៅ');
      grouped.putIfAbsent(cat.toUpperCase(), () => []).add(p);
    }

    final nowStr = DateTime.now().toString().substring(0, 16);
    int overallIndex = 0;
    double grandQty = 0;
    double grandSubtotal = 0;
    double grandCost = 0;
    double grandMargin = 0;

    final buffer = StringBuffer();

    grouped.forEach((categoryName, items) {
      buffer.writeln('''
        <tr class="group-header-row">
          <td colspan="13"><strong>Group : $categoryName</strong></td>
        </tr>
      ''');

      double groupQty = 0;
      double groupSubtotal = 0;
      double groupCost = 0;
      double groupMargin = 0;

      for (final p in items) {
        overallIndex++;
        // Quantity sold from orders (matching Item Sale Group By Category)
        final double qty = (soldQtyByProductId[p.id] ?? 0).toDouble();
        final double unitPrice = p.sellingPriceUsd;
        final double cost = p.costPriceUsd;
        final double subtotal = qty * unitPrice;
        final double extCost = qty * cost;
        final double margin = subtotal - extCost;

        groupQty += qty;
        groupSubtotal += subtotal;
        groupCost += extCost;
        groupMargin += margin;

        final desc = p.nameKh.isNotEmpty && p.nameEn.isNotEmpty
            ? '${p.nameKh} / ${p.nameEn}'
            : (p.nameKh.isNotEmpty ? p.nameKh : p.nameEn);

        buffer.writeln('''
          <tr class="item-row">
            <td class="center">$overallIndex</td>
            <td>${p.barcode}</td>
            <td>${p.barcode}. $desc</td>
            <td class="right">${qty.toStringAsFixed(2)}</td>
            <td class="right">${unitPrice.toStringAsFixed(2)}</td>
            <td class="right">${cost.toStringAsFixed(4)}</td>
            <td class="right">${subtotal.toStringAsFixed(2)}</td>
            <td class="right">0.00</td>
            <td class="right">0.00</td>
            <td class="right">0.00</td>
            <td class="right">${subtotal.toStringAsFixed(2)}</td>
            <td class="right">${extCost.toStringAsFixed(2)}</td>
            <td class="right">${margin.toStringAsFixed(2)}</td>
          </tr>
        ''');
      }

      grandQty += groupQty;
      grandSubtotal += groupSubtotal;
      grandCost += groupCost;
      grandMargin += groupMargin;

      // Group subtotal footer row
      buffer.writeln('''
        <tr class="group-total-row">
          <td colspan="2"><strong>Count : ${items.length}</strong></td>
          <td><strong>Total &nbsp; $categoryName</strong></td>
          <td class="right"><strong>${groupQty.toStringAsFixed(2)}</strong></td>
          <td></td>
          <td></td>
          <td class="right"><strong>${groupSubtotal.toStringAsFixed(2)}</strong></td>
          <td class="right">0.00</td>
          <td class="right">0.00</td>
          <td class="right">0.00</td>
          <td class="right"><strong>${groupSubtotal.toStringAsFixed(2)}</strong></td>
          <td class="right"><strong>${groupCost.toStringAsFixed(2)}</strong></td>
          <td class="right"><strong>${groupMargin.toStringAsFixed(2)}</strong></td>
        </tr>
      ''');
    });

    final htmlDoc = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>${setting.martNameKh} - Item Sale Group By Category</title>
  <style>
    @page {
      size: A4 landscape;
      margin: 12mm 10mm 15mm 10mm;
    }
    body {
      font-family: Arial, "Helvetica Neue", Helvetica, sans-serif;
      font-size: 10px;
      color: #000;
      margin: 0;
      padding: 10px;
      background: #fff;
    }
    .store-title {
      font-size: 22px;
      font-weight: bold;
      margin-bottom: 6px;
      letter-spacing: -0.3px;
    }
    .report-title {
      font-size: 12px;
      font-weight: bold;
      margin-bottom: 12px;
    }
    .meta-block {
      font-size: 9.5px;
      line-height: 1.45;
      margin-bottom: 14px;
    }
    .meta-line {
      margin-bottom: 2px;
    }
    table.report-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 9.5px;
    }
    table.report-table thead th {
      border-top: 1.5px solid #000;
      border-bottom: 1.5px solid #000;
      padding: 6px 3px;
      font-weight: normal;
      font-size: 9px;
      text-align: left;
    }
    table.report-table thead th.right,
    table.report-table td.right {
      text-align: right;
    }
    table.report-table thead th.center,
    table.report-table td.center {
      text-align: center;
    }
    tr.group-header-row td {
      padding: 9px 3px 4px 3px;
      font-size: 9.5px;
      font-weight: bold;
      border-bottom: 1px solid #000;
    }
    tr.item-row td {
      padding: 4.5px 3px;
      border-bottom: 1px dotted #888;
    }
    tr.group-total-row td {
      padding: 6px 3px 10px 3px;
      border-bottom: 1.5px solid #000;
      font-size: 9.5px;
    }
    tr.grand-total-row td {
      padding: 8px 3px;
      font-weight: bold;
      font-size: 10px;
      border-top: 1.5px solid #000;
      border-bottom: 2px solid #000;
    }
    .footer-bar {
      margin-top: 16px;
      display: flex;
      justify-content: space-between;
      font-size: 9.5px;
      color: #333;
    }
    @media print {
      .no-print { display: none !important; }
      body { padding: 0; }
      tr.item-row { page-break-inside: avoid; }
      tr.group-header-row { page-break-after: avoid; }
      tr.group-total-row { page-break-before: avoid; }
    }
  </style>
</head>
<body onload="window.print();">
  <div class="no-print" style="margin-bottom:14px;">
    <button onclick="window.print();" style="padding:8px 18px;background:#000;color:#fff;border:none;border-radius:4px;cursor:pointer;font-weight:bold;font-size:12px;">
      🖨️ Print POS Report (Landscape)
    </button>
  </div>

  <div class="store-title">${setting.martNameKh} (${setting.martNameEn})</div>
  <div class="report-title">Menu Item Sale Group By Category</div>

  <div class="meta-block">
    <div class="meta-line"><strong>Sale Status :</strong> ${_stockFilter == 'all' ? 'All' : _stockFilter.toUpperCase()}</div>
    <div class="meta-line"><strong>Date / Period :</strong> ${_activeFilterLabel(isEn)}</div>
    <div class="meta-line"><strong>From Category :</strong> ${_selectedCategoryId == 0 ? 'All' : _activeFilterLabel(isEn)} &nbsp; <strong>To :</strong> All</div>
    <div class="meta-line"><strong>From Menu Item ... To ...</strong></div>
  </div>

  <table class="report-table">
    <thead>
      <tr>
        <th class="center" style="width:26px;">Nº</th>
        <th style="width:75px;">Item Code</th>
        <th>Item Description</th>
        <th class="right" style="width:55px;">Quantity</th>
        <th class="right" style="width:55px;">Unit Price</th>
        <th class="right" style="width:55px;">Cost</th>
        <th class="right" style="width:65px;">SubTotal</th>
        <th class="right" style="width:45px;">Tax</th>
        <th class="right" style="width:45px;">Discount</th>
        <th class="right" style="width:45px;">Free</th>
        <th class="right" style="width:65px;">Ext. Price</th>
        <th class="right" style="width:55px;">Ext. Cost</th>
        <th class="right" style="width:55px;">Margin</th>
      </tr>
    </thead>
    <tbody>
      ${buffer.toString()}
      <tr class="grand-total-row">
        <td colspan="2"><strong>Count All Group : ${filtered.length}</strong></td>
        <td></td>
        <td class="right"><strong>${grandQty.toStringAsFixed(2)}</strong></td>
        <td></td>
        <td></td>
        <td class="right"><strong>${grandSubtotal.toStringAsFixed(2)}</strong></td>
        <td class="right"><strong>0.00</strong></td>
        <td class="right"><strong>0.00</strong></td>
        <td class="right"><strong>0.00</strong></td>
        <td class="right"><strong>${grandSubtotal.toStringAsFixed(2)}</strong></td>
        <td class="right"><strong>${grandCost.toStringAsFixed(2)}</strong></td>
        <td class="right"><strong>${grandMargin.toStringAsFixed(2)}</strong></td>
      </tr>
    </tbody>
  </table>

  <div class="footer-bar">
    <div>Report run on $nowStr</div>
    <div>${setting.branchName}</div>
  </div>
</body>
</html>
''';

    final opened =
        await triggerPlatformPrintHtml(htmlDoc, 'Item_Sale_Group_By_Category');
    if (opened == null) {
      await _exportInventoryCsv(filtered);
    }
  }

  void _showRestockDialog(ProductModel product) {
    final bool isEn = AppLanguage.isEnglish;
    final qtyCtrl = TextEditingController(text: '20');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          isEn
              ? 'Restock: ${product.nameEn.isNotEmpty ? product.nameEn : product.nameKh}'
              : 'បញ្ចូលស្តុក: ${product.nameKh}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn
                  ? 'Current Stock: ${product.stockQuantity} ${product.unit}'
                  : 'ស្តុកបច្ចុប្បន្ន: ${product.stockQuantity} ${product.unit}',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isEn
                    ? 'Quantity to add (${product.unit})'
                    : 'ចំនួនបន្ថែម (${product.unit})',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Cancel' : 'បោះបង់'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.add_shopping_cart,
                size: 16, color: Colors.white),
            label: Text(
              isEn ? 'Add Stock' : 'រក្សាទុកស្តុក',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              final add = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              if (add > 0) {
                setState(() {
                  product.stockQuantity += add;
                });
                await _martService.updateProduct(product);
                EasyLoading.showSuccess(
                  isEn
                      ? 'Added +$add ${product.unit} to stock!'
                      : 'បានបញ្ចូលស្តុកបន្ថែម +$add ${product.unit}!',
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = AppLanguage.isEnglish;
    final filtered = _filteredProducts;

    final int totalUnitsSold =
        filtered.fold(0, (sum, p) => sum + (_soldQtyByProductId[p.id] ?? 0));
    final int lowStockCount = filtered.where((p) => p.isLowStock).length;
    final int expiringCount = filtered.where((p) => p.isExpiringSoon).length;
    final double totalSoldRevenueUsd = filtered.fold(0.0,
        (sum, p) => sum + ((_soldQtyByProductId[p.id] ?? 0) * p.sellingPriceUsd));
    final double totalSoldRevenueKhr = filtered.fold(0.0,
        (sum, p) => sum + ((_soldQtyByProductId[p.id] ?? 0) * p.sellingPriceKhr));

    final String customDateLabel =
        _expiryFilter == 'custom_date' && _selectedDate != null
            ? _formatYmd(_selectedDate!)
            : (isEn ? 'Pick Expiry' : 'ថ្ងៃផុតកំណត់');

    final String customRangeLabel =
        _expiryFilter == 'custom_range' && _selectedRange != null
            ? '${_selectedRange!.start.day}/${_selectedRange!.start.month} (${_formatTimeOfDay(_startTime)}) → ${_selectedRange!.end.day}/${_selectedRange!.end.month} (${_formatTimeOfDay(_endTime)})'
            : (isEn ? 'Date & Time Range' : 'ចន្លោះថ្ងៃ & ម៉ោង');

    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          isEn
              ? 'Inventory Report'
              : 'របាយការណ៍ស្តុកទំនិញ',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: isEn ? 'Print Inventory Report' : 'បោះពុម្ពរបាយការណ៍ស្តុក',
            icon: const Icon(Icons.print_outlined, color: Colors.white),
            onPressed: () => _printInventoryReport(filtered),
          ),
          IconButton(
            tooltip: isEn ? 'Export CSV' : 'ទាញយក CSV',
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () => _exportInventoryCsv(filtered),
          ),
          IconButton(
            tooltip: isEn ? 'Refresh' : 'ផ្ទុកឡើងវិញ',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInventory,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search & Date / Stock / Category Filter Bar (like Sales Invoices)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: isEn
                        ? 'Search product name, barcode, or category...'
                        : 'ស្វែងរកឈ្មោះទំនិញ, លេខបាកូដ ឬប្រភេទ...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildExpiryChip(
                        value: 'all',
                        label: isEn ? 'All Products' : 'ទំនិញទាំងអស់',
                        icon: Icons.inventory_2_outlined,
                        onTap: () => setState(() => _expiryFilter = 'all'),
                      ),
                      const SizedBox(width: 6),
                      _buildExpiryChip(
                        value: 'expiring_soon',
                        label: isEn ? 'Expiring Soon' : 'ជិតផុតកំណត់',
                        icon: Icons.alarm,
                        onTap: () =>
                            setState(() => _expiryFilter = 'expiring_soon'),
                      ),
                      const SizedBox(width: 6),
                      _buildExpiryChip(
                        value: 'custom_date',
                        label: customDateLabel,
                        icon: Icons.event_available,
                        onTap: _pickSingleExpiryDate,
                      ),
                      const SizedBox(width: 6),
                      _buildExpiryChip(
                        value: 'custom_range',
                        label: customRangeLabel,
                        icon: Icons.date_range,
                        onTap: _pickExpiryRange,
                      ),
                      Container(
                        height: 20,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.grey.shade300,
                      ),
                      _buildStockChip(
                        'all',
                        isEn ? 'All Status' : 'គ្រប់ស្ថានភាព',
                        AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      _buildStockChip(
                        'healthy',
                        isEn ? 'Healthy' : 'ស្តុកគ្រប់',
                        AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      _buildStockChip(
                        'low',
                        isEn ? 'Low Stock' : 'ជិតអស់ស្តុក',
                        AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      _buildStockChip(
                        'out',
                        isEn ? 'Out of Stock' : 'អស់ពីស្តុក',
                        AppColors.danger,
                      ),
                    ],
                  ),
                ),
                if (_categories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryChip(
                          0,
                          isEn ? 'All Categories' : 'គ្រប់ប្រភេទ',
                        ),
                        ..._categories.map(
                          (c) => _buildCategoryChip(
                            c.id,
                            isEn && c.nameEn.isNotEmpty ? c.nameEn : c.nameKh,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Live Inventory Summary Strip + Print / Export CSV Controls
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildSummaryMetric(
                      label: isEn ? 'Products (SKUs)' : 'មុខទំនិញសរុប',
                      value: '${filtered.length}',
                      subValue:
                          '$totalUnitsSold ${isEn ? 'units sold' : 'ឯកតាលក់បាន'}',
                      color: AppColors.textPrimary,
                    ),
                    _buildVerticalDivider(),
                    _buildSummaryMetric(
                      label: isEn ? 'Low Stock' : 'ជិតអស់ស្តុក',
                      value: '$lowStockCount',
                      subValue: isEn ? 'Need restock' : 'ត្រូវបញ្ចូលស្តុក',
                      color: AppColors.danger,
                    ),
                    _buildVerticalDivider(),
                    _buildSummaryMetric(
                      label: isEn ? 'Expiring Soon' : 'ជិតផុតកំណត់',
                      value: '$expiringCount',
                      subValue: isEn ? 'Within 60 days' : 'ក្នុង 60 ថ្ងៃ',
                      color: AppColors.warning,
                    ),
                    _buildVerticalDivider(),
                    _buildSummaryMetric(
                      label: isEn ? 'Sales Amount' : 'ចំណូលលក់សរុប',
                      value: _martService.formatUsd(totalSoldRevenueUsd),
                      subValue: _martService.formatKhr(totalSoldRevenueKhr),
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '📦 ${_activeFilterLabel(isEn)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _printInventoryReport(filtered),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.print,
                                    size: 13, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  isEn ? 'Print Report' : 'បោះពុម្ពសរុប',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _exportInventoryCsv(filtered),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.download_rounded,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  isEn ? 'Export CSV' : 'ទាញយក CSV',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Product Inventory List (like Sales Invoices)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              isEn
                                  ? 'No matching products in inventory'
                                  : 'មិនមានទំនិញត្រូវនឹងការស្វែងរកទេ',
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInventory,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            return _buildProductInventoryCard(product, isEn);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryChip({
    required String value,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool selected = _expiryFilter == value;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 14,
        color: selected ? Colors.white : AppColors.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildStockChip(String value, String label, Color activeColor) {
    final bool selected = _stockFilter == value;
    return ChoiceChip(
      selected: selected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selectedColor: activeColor,
      backgroundColor: AppColors.surface,
      onSelected: (_) => setState(() => _stockFilter = value),
    );
  }

  Widget _buildCategoryChip(int id, String label) {
    final bool selected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        selected: selected,
        visualDensity: VisualDensity.compact,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
        selectedColor: AppColors.secondary,
        backgroundColor: AppColors.surface,
        onSelected: (_) => setState(() => _selectedCategoryId = id),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 28,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.grey.shade300,
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required String subValue,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInventoryCard(ProductModel p, bool isEn) {
    final statusColor = _stockStatusColor(p);
    final int soldQty = _soldQtyByProductId[p.id] ?? 0;
    final double soldValUsd = soldQty * p.sellingPriceUsd;
    final double soldValKhr = soldQty * p.sellingPriceKhr;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: p.isLowStock
            ? BorderSide(color: statusColor.withValues(alpha: 0.35))
            : BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _showProductStockDetails(p),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImage(
                    imageUrl: p.imageUrl,
                    width: 52,
                    height: 52,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                isEn && p.nameEn.isNotEmpty
                                    ? p.nameEn
                                    : p.nameKh,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _stockStatusLabel(p, isEn),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEn ? p.nameKh : p.nameEn,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Category badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '🏷️ ${p.categoryName ?? (isEn ? 'General' : 'ទូទៅ')}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            // Barcode badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${p.barcode}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Unit Price badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${isEn ? 'Price' : 'តម្លៃ'}: ${_martService.formatUsd(p.sellingPriceUsd)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            // Expiry badge
                            if (p.expiryDate != null &&
                                p.expiryDate!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.isExpiringSoon
                                      ? AppColors.warning
                                          .withValues(alpha: 0.15)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${isEn ? 'Exp' : 'ផុតកំណត់'}: ${_cleanExpiry(p.expiryDate)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: p.isExpiringSoon
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: p.isExpiringSoon
                                        ? AppColors.warning
                                        : AppColors.textSecondary,
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
              const Divider(height: 16),

              // Bottom Row: Sold Quantity & Stock Remaining + Quick Actions + Total Sold Revenue
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Sold Quantity pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${isEn ? 'Sold' : 'លក់បាន'}: $soldQty ${p.unit}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        // Remaining stock pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${isEn ? 'Stock' : 'ស្តុក'}: ${p.stockQuantity}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Quick Print Slip button
                        InkWell(
                          onTap: () => _printSingleProductSlip(p),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.print,
                                    size: 12, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Text(
                                  isEn ? 'Print' : 'បោះពុម្ព',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Quick Restock button
                        InkWell(
                          onTap: () => _showRestockDialog(p),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_shopping_cart,
                                    size: 12, color: AppColors.secondary),
                                const SizedBox(width: 3),
                                Text(
                                  isEn ? 'Restock' : 'បញ្ចូលស្តុក',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Quick Copy button
                        InkWell(
                          onTap: () => _copyProductText(p, isEn),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _martService.formatUsd(soldValUsd),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        _martService.formatKhr(soldValKhr),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductStockDetails(ProductModel p) {
    final bool isEn = AppLanguage.isEnglish;
    final setting = _martService.getSettings();
    final double stockValUsd = p.stockQuantity * p.sellingPriceUsd;
    final double stockValKhr = p.stockQuantity * p.sellingPriceKhr;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    setting.martNameKh,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    isEn
                        ? 'Product Inventory & Valuation Sheet'
                        : 'ប័ណ្ណត្រួតពិនិត្យស្តុកទំនិញលម្អិត',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      ProductImage(
                        imageUrl: p.imageUrl,
                        width: 60,
                        height: 60,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nameKh,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              p.nameEn,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildMetaRow(
                    isEn ? 'Barcode:' : 'លេខបាកូដ:',
                    p.barcode,
                    isBold: true,
                  ),
                  _buildMetaRow(
                    isEn ? 'Category:' : 'ប្រភេទទំនិញ:',
                    p.categoryName ?? (isEn ? 'General' : 'ទូទៅ'),
                  ),
                  _buildMetaRow(
                    isEn ? 'Stock Status:' : 'ស្ថានភាពស្តុក:',
                    _stockStatusLabel(p, isEn),
                    isBold: true,
                  ),
                  _buildMetaRow(
                    isEn ? 'Current Stock:' : 'បរិមាណក្នុងស្តុក:',
                    '${p.stockQuantity} ${p.unit} (Reorder ≤ ${p.reorderLevel})',
                    isBold: true,
                  ),
                  _buildMetaRow(
                    isEn ? 'Expiry Date:' : 'ថ្ងៃផុតកំណត់:',
                    _cleanExpiry(p.expiryDate),
                  ),
                  const Divider(height: 20),
                  _buildMetaRow(
                    isEn ? 'Selling Price (USD):' : 'តម្លៃលក់រាយ (\$):',
                    _martService.formatUsd(p.sellingPriceUsd),
                  ),
                  _buildMetaRow(
                    isEn ? 'Selling Price (KHR):' : 'តម្លៃលក់រាយ (៛):',
                    _martService.formatKhr(p.sellingPriceKhr),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildMetaRow(
                          isEn
                              ? 'Total Stock Value (USD):'
                              : 'តម្លៃស្តុកសរុប (\$):',
                          _martService.formatUsd(stockValUsd),
                          isBold: true,
                        ),
                        _buildMetaRow(
                          isEn
                              ? 'Total Stock Value (KHR):'
                              : 'តម្លៃស្តុកសរុប (៛):',
                          _martService.formatKhr(stockValKhr),
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed: () => _printSingleProductSlip(p),
                      icon: const Icon(Icons.print,
                          size: 18, color: Colors.white),
                      label: Text(
                        isEn
                            ? 'Print Stock Slip (${p.barcode})'
                            : 'បោះពុម្ពប័ណ្ណស្តុក (${p.barcode})',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showRestockDialog(p);
                          },
                          icon:
                              const Icon(Icons.add_shopping_cart, size: 15),
                          label: Text(
                            isEn ? 'Restock' : 'បញ្ចូលស្តុក',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyProductText(p, isEn),
                          icon: const Icon(Icons.copy, size: 15),
                          label: Text(
                            isEn ? 'Copy' : 'ចម្លង',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            isEn ? 'Close' : 'បិទ',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

