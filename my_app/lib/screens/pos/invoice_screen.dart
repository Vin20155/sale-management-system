import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/config/app_language.dart';
import 'package:my_app/models/mart_models.dart';
import 'package:my_app/services/mart_service.dart';
import 'package:my_app/utils/invoice_printer.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final MartService _martService = MartService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<OrderModel> _orders = [];
  bool _isLoading = true;

  // Date filters: 'today', 'all', 'custom_date', 'custom_range'
  String _dateFilter = 'today';
  DateTime? _selectedDate;
  DateTimeRange? _selectedRange;
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 6, minute: 0);

  // Payment/Status filters: 'all', 'cash', 'khqr', 'voided'
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
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

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final list = await _martService.getOrders();
    if (mounted) {
      setState(() {
        _orders = List<OrderModel>.from(list);
        final todayPrefix = _formatYmd(DateTime.now());
        final hasToday =
            _orders.any((o) => o.createdAt.startsWith(todayPrefix));
        if (!hasToday && _orders.isNotEmpty && _dateFilter == 'today') {
          _dateFilter = 'all';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _pickSingleDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 2),
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
        _dateFilter = 'custom_date';
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    final minute = t.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }

  Future<void> _pickDateRange() async {
    if (_dateFilter == 'custom_range' && _selectedRange != null) {
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
      lastDate: DateTime(now.year + 2),
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
                        lastDate: DateTime(now.year + 2),
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
                        _dateFilter = 'custom_range';
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

  String _activePeriodLabel(bool isEn) {
    switch (_dateFilter) {
      case 'today':
        return isEn
            ? 'Today (${_formatYmd(DateTime.now())})'
            : 'ថ្ងៃនេះ (${_formatYmd(DateTime.now())})';
      case 'custom_date':
        final d = _selectedDate != null ? _formatYmd(_selectedDate!) : '';
        return isEn ? 'Date: $d' : 'ថ្ងៃទី: $d';
      case 'custom_range':
        if (_selectedRange == null) {
          return isEn ? 'Date & Time Range' : 'ចន្លោះថ្ងៃ & ម៉ោង';
        }
        final s = _formatYmd(_selectedRange!.start);
        final e = _formatYmd(_selectedRange!.end);
        final st = _formatTimeOfDay(_startTime);
        final et = _formatTimeOfDay(_endTime);
        return '$s ($st) → $e ($et)';
      case 'all':
      default:
        return isEn ? 'All Dates' : 'គ្រប់កាលបរិច្ឆេទ';
    }
  }

  List<OrderModel> get _filteredOrders {
    final query = _searchCtrl.text.trim().toLowerCase();
    final todayPrefix = _formatYmd(DateTime.now());

    return _orders.where((order) {
      final orderDateStr = order.createdAt.length >= 10
          ? order.createdAt.substring(0, 10)
          : order.createdAt;

      // 1. Date & Time filter
      if (_dateFilter == 'today') {
        if (!orderDateStr.startsWith(todayPrefix)) return false;
      } else if (_dateFilter == 'custom_date' && _selectedDate != null) {
        final target = _formatYmd(_selectedDate!);
        if (orderDateStr != target) return false;
      } else if (_dateFilter == 'custom_range' && _selectedRange != null) {
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
        final orderDt =
            DateTime.tryParse(order.createdAt.replaceAll('/', '-'));
        if (orderDt != null) {
          if (orderDt.isBefore(startDt) || orderDt.isAfter(endDt)) {
            return false;
          }
        } else {
          final startStr = _formatYmd(_selectedRange!.start);
          final endStr = _formatYmd(_selectedRange!.end);
          if (orderDateStr.compareTo(startStr) < 0 ||
              orderDateStr.compareTo(endStr) > 0) {
            return false;
          }
        }
      }

      // 2. Payment / Status filter
      if (_typeFilter == 'voided') {
        if (!order.isVoided) return false;
      } else if (_typeFilter == 'khqr') {
        if (order.isVoided || !order.isKhqr) return false;
      } else if (_typeFilter == 'cash') {
        if (order.isVoided || order.isKhqr) return false;
      }

      // 3. Search query (Invoice No, Customer, Cashier, Item Name, Barcode)
      if (query.isNotEmpty) {
        final matchInvoice = order.invoiceNo.toLowerCase().contains(query);
        final matchCustomer =
            (order.customerName ?? '').toLowerCase().contains(query);
        final matchCashier =
            (order.cashierName ?? '').toLowerCase().contains(query);
        final matchItem = order.items.any(
          (it) =>
              it.productName.toLowerCase().contains(query) ||
              (it.barcode ?? '').toLowerCase().contains(query),
        );
        if (!matchInvoice && !matchCustomer && !matchCashier && !matchItem) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  String _paymentLabel(String method, bool isEn) {
    switch (method) {
      case 'khqr_bakong':
        return isEn ? 'Bakong KHQR' : 'បាគង KHQR';
      case 'cash_khr':
        return isEn ? 'Cash (KHR)' : 'សាច់ប្រាក់ (៛)';
      case 'mixed_cash':
        return isEn ? 'Mixed Cash (\$+៛)' : 'សាច់ប្រាក់ចម្រុះ (\$+៛)';
      case 'cash_usd':
      default:
        return isEn ? 'Cash (USD)' : 'សាច់ប្រាក់ (\$)';
    }
  }

  Future<void> _copyInvoiceText(OrderModel order, bool isEn) async {
    final buffer = StringBuffer()
      ..writeln('Invoice: ${order.invoiceNo}')
      ..writeln('Date: ${order.createdAt}')
      ..writeln('Cashier: ${order.cashierName ?? '-'}')
      ..writeln(
          'Payment: ${_paymentLabel(order.paymentMethod, true)} (${order.isVoided ? 'VOIDED' : 'COMPLETED'})')
      ..writeln('--------------------------------');
    for (final it in order.items) {
      buffer.writeln(
          '${it.productName} x${it.quantity} = ${_martService.formatUsd(it.subtotalUsd)}');
    }
    buffer
      ..writeln('--------------------------------')
      ..writeln(
          'Total: ${_martService.formatUsd(order.totalUsd)} (${_martService.formatKhr(order.totalKhr)})');

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    EasyLoading.showSuccess(
      isEn ? 'Copied receipt to clipboard!' : 'បានចម្លងវិក្កយបត្ររួចរាល់!',
    );
  }

  Future<void> _printSingleInvoice(OrderModel order) async {
    final bool isEn = AppLanguage.isEnglish;
    final setting = _martService.getSettings();

    final itemRows = order.items
        .map((it) => '''
      <tr>
        <td style="padding:4px 0;">
          <div style="font-weight:600;">${it.productName}</div>
          <div style="font-size:11px;color:#555;">${_martService.formatUsd(it.unitPriceUsd)} × ${it.quantity}</div>
        </td>
        <td style="text-align:right;vertical-align:top;padding:4px 0;font-weight:600;">
          ${_martService.formatUsd(it.subtotalUsd)}
        </td>
      </tr>
    ''')
        .join();

    final voidBanner = order.isVoided
        ? '<div style="border:1px solid #d32f2f;color:#d32f2f;text-align:center;padding:4px;font-weight:bold;margin-bottom:8px;">VOIDED INVOICE</div>'
        : '';

    final htmlDoc = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Receipt ${order.invoiceNo}</title>
  <style>
    @page { size: 80mm auto; margin: 4mm; }
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      width: 76mm;
      margin: 0 auto;
      padding: 8px;
      color: #111;
      font-size: 12px;
    }
    .center { text-align: center; }
    .divider { border-top: 1px dashed #666; margin: 8px 0; }
    table { width: 100%; border-collapse: collapse; }
    .meta-row { display: flex; justify-content: space-between; margin: 2px 0; font-size: 11px; }
    .total-row { display: flex; justify-content: space-between; margin: 4px 0; font-weight: bold; font-size: 14px; }
    @media print { .no-print { display: none; } }
  </style>
</head>
<body onload="window.print();">
  <div class="no-print" style="text-align:center;margin-bottom:10px;">
    <button onclick="window.print();" style="padding:6px 14px;background:#0F766E;color:#fff;border:none;border-radius:6px;cursor:pointer;font-weight:bold;">
      🖨️ Print Receipt
    </button>
  </div>
  $voidBanner
  <div class="center">
    <div style="font-size:16px;font-weight:bold;">${setting.martNameKh}</div>
    <div style="font-size:12px;">${setting.martNameEn}</div>
    <div style="font-size:11px;color:#555;">${setting.branchName}</div>
    <div style="font-size:11px;color:#555;">Tel: ${setting.phone}</div>
  </div>
  <div class="divider"></div>
  <div class="meta-row"><span>Invoice:</span><strong>${order.invoiceNo}</strong></div>
  <div class="meta-row"><span>Date:</span><span>${order.createdAt}</span></div>
  <div class="meta-row"><span>Cashier:</span><span>${order.cashierName ?? '-'}</span></div>
  ${order.customerName != null ? '<div class="meta-row"><span>Customer:</span><span>${order.customerName}</span></div>' : ''}
  <div class="meta-row"><span>Payment:</span><strong>${_paymentLabel(order.paymentMethod, isEn)}</strong></div>
  <div class="divider"></div>
  <table>
    <thead>
      <tr style="border-bottom:1px solid #ccc;font-size:11px;color:#555;">
        <th style="text-align:left;padding-bottom:4px;">Item</th>
        <th style="text-align:right;padding-bottom:4px;">Subtotal</th>
      </tr>
    </thead>
    <tbody>
      $itemRows
    </tbody>
  </table>
  <div class="divider"></div>
  ${order.discountUsd > 0 ? '<div class="meta-row"><span>Discount:</span><span>-${_martService.formatUsd(order.discountUsd)}</span></div>' : ''}
  ${order.taxUsd > 0 ? '<div class="meta-row"><span>Tax:</span><span>${_martService.formatUsd(order.taxUsd)}</span></div>' : ''}
  <div class="total-row"><span>Total USD:</span><span>${_martService.formatUsd(order.totalUsd)}</span></div>
  <div class="total-row" style="font-size:13px;"><span>Total KHR:</span><span>${_martService.formatKhr(order.totalKhr)}</span></div>
  <div class="divider"></div>
  <div class="meta-row"><span>Received USD:</span><span>${_martService.formatUsd(order.receivedUsd)}</span></div>
  ${order.receivedKhr > 0 && !order.isKhqr ? '<div class="meta-row"><span>Received KHR:</span><span>${_martService.formatKhr(order.receivedKhr)}</span></div>' : ''}
  ${!order.isKhqr ? '<div class="meta-row"><span>Change USD:</span><strong>${_martService.formatUsd(order.changeUsd)}</strong></div>' : ''}
  ${!order.isKhqr ? '<div class="meta-row"><span>Change KHR:</span><strong>${_martService.formatKhr(order.changeKhr)}</strong></div>' : ''}
  <div class="divider"></div>
  <div class="center" style="font-size:11px;color:#555;margin-top:6px;">
    ${setting.receiptFooterKh}<br>Thank you for shopping with us!
  </div>
</body>
</html>
''';

    final opened =
        await triggerPlatformPrintHtml(htmlDoc, 'Receipt_${order.invoiceNo}');
    if (opened == null) {
      await _copyInvoiceText(order, isEn);
      EasyLoading.showSuccess(
        isEn
            ? 'Receipt prepared & copied for printing!'
            : 'បានរៀបចំវិក្កយបត្រសម្រាប់បោះពុម្ព!',
      );
    }
  }

  String _buildCsvContent(List<OrderModel> filtered, bool isEn) {
    final setting = _martService.getSettings();
    final activeOrders = filtered.where((o) => !o.isVoided).toList();
    final voidedOrders = filtered.where((o) => o.isVoided).toList();
    final int totalItemsQty = activeOrders.fold(
      0,
      (sum, o) => sum + o.items.fold(0, (s, it) => s + it.quantity),
    );
    final double cashUsd = activeOrders
        .where((o) => !o.isKhqr)
        .fold(0.0, (sum, o) => sum + o.totalUsd);
    final double cashKhr = (cashUsd * _martService.exchangeRate).roundToDouble();
    final double khqrUsd = activeOrders
        .where((o) => o.isKhqr)
        .fold(0.0, (sum, o) => sum + o.totalUsd);
    final double khqrKhr = (khqrUsd * _martService.exchangeRate).roundToDouble();
    final double voidedUsd =
        voidedOrders.fold(0.0, (sum, o) => sum + o.totalUsd);
    final double voidedKhr =
        voidedOrders.fold(0.0, (sum, o) => sum + o.totalKhr);
    final double netUsd =
        activeOrders.fold(0.0, (sum, o) => sum + o.totalUsd);
    final double netKhr =
        activeOrders.fold(0.0, (sum, o) => sum + o.totalKhr);

    String esc(Object? val) {
      final str = (val ?? '').toString().replaceAll('"', '""');
      return '"$str"';
    }

    String row(List<Object?> cells) => cells.map(esc).join(',');

    final nowStr = DateTime.now().toString().substring(0, 19);
    final csv = StringBuffer();

    // 1. Store & Report Metadata Header
    csv.writeln(row([
      isEn ? 'STORE NAME' : 'ឈ្មោះហាង',
      '${setting.martNameKh} (${setting.martNameEn})',
      isEn ? 'BRANCH' : 'សាខា',
      setting.branchName,
    ]));
    csv.writeln(row([
      isEn ? 'REPORT PERIOD' : 'កាលបរិច្ឆេទរបាយការណ៍',
      _activePeriodLabel(isEn),
      isEn ? 'EXPORTED AT' : 'ទាញយកនៅម៉ោង',
      nowStr,
    ]));
    csv.writeln(row([
      isEn ? 'EXCHANGE RATE' : 'អត្រាប្តូរប្រាក់',
      '1 USD = ${_martService.exchangeRate.round()} KHR',
      isEn ? 'TOTAL INVOICES' : 'វិក្កយបត្រសរុប',
      '${filtered.length} (${activeOrders.length} Active, ${voidedOrders.length} Voided)',
    ]));
    csv.writeln();

    // 2. Summary Totals Block
    csv.writeln(row([
      isEn ? 'SUMMARY METRIC' : 'របាយការណ៍សង្ខេប',
      isEn ? 'COUNT / QTY' : 'ចំនួន',
      isEn ? 'AMOUNT (USD)' : 'ទឹកប្រាក់ (USD)',
      isEn ? 'AMOUNT (KHR)' : 'ទឹកប្រាក់ (KHR)',
    ]));
    csv.writeln(row([
      isEn ? 'Cash Sales (Active)' : 'លក់ជាសាច់ប្រាក់',
      activeOrders.where((o) => !o.isKhqr).length,
      cashUsd.toStringAsFixed(2),
      cashKhr.round(),
    ]));
    csv.writeln(row([
      isEn ? 'Bakong KHQR Sales (Active)' : 'លក់តាមបាគង KHQR',
      activeOrders.where((o) => o.isKhqr).length,
      khqrUsd.toStringAsFixed(2),
      khqrKhr.round(),
    ]));
    csv.writeln(row([
      isEn ? 'Voided / Cancelled Invoices' : 'វិក្កយបត្របានបោះបង់',
      voidedOrders.length,
      voidedUsd.toStringAsFixed(2),
      voidedKhr.round(),
    ]));
    csv.writeln(row([
      isEn ? 'NET TOTAL REVENUE' : 'ចំណូលសរុបរួម',
      '${activeOrders.length} Bills ($totalItemsQty Qty)',
      netUsd.toStringAsFixed(2),
      netKhr.round(),
    ]));
    csv.writeln();

    // 3. Detailed Invoices Table Header
    csv.writeln(row([
      'No.',
      isEn ? 'Invoice No' : 'លេខវិក្កយបត្រ',
      isEn ? 'Date' : 'កាលបរិច្ឆេទ',
      isEn ? 'Time' : 'ម៉ោង',
      isEn ? 'Status' : 'ស្ថានភាព',
      isEn ? 'Cashier' : 'បេឡាករ',
      isEn ? 'Customer' : 'អតិថិជន',
      isEn ? 'Payment Method' : 'វិធីទូទាត់',
      isEn ? 'Items Count' : 'ចំនួនមុខ',
      isEn ? 'Total Qty' : 'បរិមាណសរុប',
      isEn ? 'Items Detail' : 'មុខទំនិញលម្អិត',
      isEn ? 'Subtotal (USD)' : 'សរុបបឋម (\$)',
      isEn ? 'Discount (USD)' : 'បញ្ចុះតម្លៃ (\$)',
      isEn ? 'Tax (USD)' : 'ពន្ធ (\$)',
      isEn ? 'Total (USD)' : 'សរុបដុល្លារ (\$)',
      isEn ? 'Total (KHR)' : 'សរុបរៀល (៛)',
      isEn ? 'Received (USD)' : 'ប្រាក់ទទួល (\$)',
      isEn ? 'Received (KHR)' : 'ប្រាក់ទទួល (៛)',
      isEn ? 'Change (USD)' : 'ប្រាក់អាប់ (\$)',
      isEn ? 'Change (KHR)' : 'ប្រាក់អាប់ (៛)',
      isEn ? 'Points' : 'ពិន្ទុ',
    ]));

    // 4. Invoice Rows
    for (int i = 0; i < filtered.length; i++) {
      final o = filtered[i];
      final datePart =
          o.createdAt.length >= 10 ? o.createdAt.substring(0, 10) : o.createdAt;
      final timePart =
          o.createdAt.length >= 19 ? o.createdAt.substring(11, 19) : '';
      final int orderQty =
          o.items.fold(0, (sum, item) => sum + item.quantity);
      final itemsStr = o.items
          .map((it) =>
              '${it.productName} x${it.quantity} (\$${it.subtotalUsd.toStringAsFixed(2)})')
          .join(' | ');

      csv.writeln(row([
        i + 1,
        o.invoiceNo,
        datePart,
        timePart,
        o.isVoided
            ? (isEn ? 'VOIDED' : 'បានបោះបង់')
            : (isEn ? 'COMPLETED' : 'ជោគជ័យ'),
        o.cashierName ?? '-',
        o.customerName ?? (isEn ? 'Walk-in' : 'អតិថិជនទូទៅ'),
        _paymentLabel(o.paymentMethod, isEn),
        o.items.length,
        orderQty,
        itemsStr,
        o.subtotalUsd.toStringAsFixed(2),
        o.discountUsd.toStringAsFixed(2),
        o.taxUsd.toStringAsFixed(2),
        o.totalUsd.toStringAsFixed(2),
        o.totalKhr.round(),
        o.receivedUsd.toStringAsFixed(2),
        o.receivedKhr.round(),
        o.changeUsd.toStringAsFixed(2),
        o.changeKhr.round(),
        o.pointsEarned,
      ]));
    }

    // 5. Aligned Column Footer Totals
    csv.writeln();
    csv.writeln(row([
      '',
      isEn ? 'CASH SALES TOTAL' : 'សរុបសាច់ប្រាក់',
      '',
      '',
      '${activeOrders.where((o) => !o.isKhqr).length} Bills',
      '',
      '',
      isEn ? 'Cash' : 'សាច់ប្រាក់',
      '',
      '',
      '',
      '',
      '',
      '',
      cashUsd.toStringAsFixed(2),
      cashKhr.round(),
      '',
      '',
      '',
      '',
      '',
    ]));
    csv.writeln(row([
      '',
      isEn ? 'BAKONG KHQR TOTAL' : 'សរុបបាគង KHQR',
      '',
      '',
      '${activeOrders.where((o) => o.isKhqr).length} Bills',
      '',
      '',
      'Bakong KHQR',
      '',
      '',
      '',
      '',
      '',
      '',
      khqrUsd.toStringAsFixed(2),
      khqrKhr.round(),
      '',
      '',
      '',
      '',
      '',
    ]));
    csv.writeln(row([
      '',
      isEn ? 'NET TOTAL (ACTIVE)' : 'ចំណូលសរុបរួម',
      _activePeriodLabel(isEn),
      '',
      '${activeOrders.length} Active',
      '',
      '',
      '',
      '',
      totalItemsQty,
      '',
      '',
      '',
      '',
      netUsd.toStringAsFixed(2),
      netKhr.round(),
      '',
      '',
      '',
      '',
      '',
    ]));

    return csv.toString();
  }

  String _buildCsvFileName() {
    switch (_dateFilter) {
      case 'custom_date':
        final d = _selectedDate != null
            ? _formatYmd(_selectedDate!)
            : _formatYmd(DateTime.now());
        return 'sales_invoices_$d.csv';
      case 'custom_range':
        if (_selectedRange != null) {
          return 'sales_invoices_${_formatYmd(_selectedRange!.start)}_to_${_formatYmd(_selectedRange!.end)}.csv';
        }
        return 'sales_invoices_range.csv';
      case 'today':
        return 'sales_invoices_${_formatYmd(DateTime.now())}.csv';
      case 'all':
      default:
        return 'sales_invoices_all_${_formatYmd(DateTime.now())}.csv';
    }
  }

  Future<void> _exportFilteredCsv(List<OrderModel> filtered) async {
    final bool isEn = AppLanguage.isEnglish;
    if (filtered.isEmpty) {
      EasyLoading.showInfo(
        isEn ? 'No invoices to export' : 'មិនមានវិក្កយបត្រសម្រាប់ទាញយកទេ',
      );
      return;
    }

    final csvContent = _buildCsvContent(filtered, isEn);
    final fileName = _buildCsvFileName();
    final savedPathOrFile =
        await triggerPlatformDownloadCsv(csvContent, fileName);

    // Also copy to clipboard so the cashier can paste directly into Excel/Google Sheets/Telegram anytime
    await Clipboard.setData(ClipboardData(text: csvContent));

    if (!mounted) return;
    _showCsvExportResultDialog(
      filtered: filtered,
      csvContent: csvContent,
      fileName: fileName,
      savedLocation: savedPathOrFile,
    );
  }

  void _showCsvExportResultDialog({
    required List<OrderModel> filtered,
    required String csvContent,
    required String fileName,
    required String? savedLocation,
  }) {
    final bool isEn = AppLanguage.isEnglish;
    final activeOrders = filtered.where((o) => !o.isVoided).toList();
    final voidedOrders = filtered.where((o) => o.isVoided).toList();
    final double cashUsd = activeOrders
        .where((o) => !o.isKhqr)
        .fold(0.0, (sum, o) => sum + o.totalUsd);
    final double khqrUsd = activeOrders
        .where((o) => o.isKhqr)
        .fold(0.0, (sum, o) => sum + o.totalUsd);
    final double netUsd =
        activeOrders.fold(0.0, (sum, o) => sum + o.totalUsd);
    final double netKhr =
        activeOrders.fold(0.0, (sum, o) => sum + o.totalKhr);

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
                  // Header
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
                                  ? 'CSV Export Ready'
                                  : 'ទាញយកឯកសារ CSV រួចរាល់',
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

                  // File badge
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

                  // Summary Totals Card (No overflow)
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
                        _buildReceiptMetaRow(
                          isEn ? 'Period:' : 'កាលបរិច្ឆេទ:',
                          _activePeriodLabel(isEn),
                          isBold: true,
                        ),
                        _buildReceiptMetaRow(
                          isEn ? 'Invoices:' : 'ចំនួនវិក្កយបត្រ:',
                          isEn
                              ? '${activeOrders.length} Active (${voidedOrders.length} Voided)'
                              : '${activeOrders.length} ជោគជ័យ (${voidedOrders.length} បោះបង់)',
                        ),
                        _buildReceiptMetaRow(
                          isEn ? 'Cash Sales:' : 'លក់ជាសាច់ប្រាក់:',
                          '${_martService.formatUsd(cashUsd)} (${_martService.formatKhr(cashUsd * _martService.exchangeRate)})',
                        ),
                        _buildReceiptMetaRow(
                          isEn ? 'Bakong KHQR:' : 'លក់តាមបាគង KHQR:',
                          '${_martService.formatUsd(khqrUsd)} (${_martService.formatKhr(khqrUsd * _martService.exchangeRate)})',
                        ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEn ? 'Net Total:' : 'ចំណូលសរុបរួម:',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '${_martService.formatUsd(netUsd)} (${_martService.formatKhr(netKhr)})',
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

                  // Clean Table Preview of Exported Invoices
                  Text(
                    isEn
                        ? 'Exported Invoices (${filtered.length})'
                        : 'បញ្ជីវិក្កយបត្រក្នុងឯកសារ (${filtered.length})',
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
                        final o = filtered[idx];
                        final timeStr = o.createdAt.length >= 16
                            ? o.createdAt.substring(11, 16)
                            : o.createdAt;
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.invoiceNo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: o.isVoided
                                          ? AppColors.danger
                                          : AppColors.textPrimary,
                                      decoration: o.isVoided
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  Text(
                                    '$timeStr • ${_paymentLabel(o.paymentMethod, isEn)} • ${o.items.length} ${isEn ? 'items' : 'មុខ'}',
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _martService.formatUsd(o.totalUsd),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: o.isVoided
                                        ? AppColors.textSecondary
                                        : AppColors.primary,
                                  ),
                                ),
                                Text(
                                  _martService.formatKhr(o.totalKhr),
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Primary Full-Width Download Button
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
                      isEn ? 'Download CSV File Again' : 'ទាញយកឯកសារ CSV ម្តងទៀត',
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

                  // Secondary Row: Copy CSV + Close
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

  Future<void> _printSummaryReport(List<OrderModel> filtered) async {
    final bool isEn = AppLanguage.isEnglish;
    final setting = _martService.getSettings();

    // Group filtered orders by cashier
    final Map<String, List<OrderModel>> groupedByCashier = {};
    for (final order in filtered) {
      final cashier =
          (order.cashierName != null && order.cashierName!.trim().isNotEmpty)
              ? order.cashierName!.trim()
              : (isEn ? 'Cashier' : 'បេឡាករ');
      groupedByCashier.putIfAbsent(cashier, () => []).add(order);
    }

    String formatDateTime(String raw) {
      if (raw.isEmpty) return '-';
      try {
        final dt = DateTime.parse(raw);
        final hour =
            dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        final minute = dt.minute.toString().padLeft(2, '0');
        return '${dt.day}/${dt.month}/${dt.year}  ${hour.toString().padLeft(2, '0')}:$minute$ampm';
      } catch (_) {
        return raw;
      }
    }

    String dateRangeStr;
    if (_dateFilter == 'today') {
      final now = DateTime.now();
      final dayStr = now.day.toString().padLeft(2, '0');
      final monthStr = now.month.toString().padLeft(2, '0');
      final nextDay = now.add(const Duration(days: 1));
      final nextDayStr = nextDay.day.toString().padLeft(2, '0');
      final nextMonthStr = nextDay.month.toString().padLeft(2, '0');
      dateRangeStr =
          'Date From $dayStr-$monthStr-${now.year} 06:00 AM To $nextDayStr-$nextMonthStr-${nextDay.year} 06:00 AM';
    } else if (_dateFilter == 'custom_range' && _selectedRange != null) {
      final s = _selectedRange!.start;
      final e = _selectedRange!.end;
      final sTimeStr = _formatTimeOfDay(_startTime);
      final eTimeStr = _formatTimeOfDay(_endTime);
      dateRangeStr =
          'Date From ${s.day.toString().padLeft(2, '0')}-${s.month.toString().padLeft(2, '0')}-${s.year} $sTimeStr To ${e.day.toString().padLeft(2, '0')}-${e.month.toString().padLeft(2, '0')}-${e.year} $eTimeStr';
    } else if (_dateFilter == 'custom_date' && _selectedDate != null) {
      final d = _selectedDate!;
      dateRangeStr =
          'Date From ${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year} 06:00 AM To ${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year} 11:59 PM';
    } else {
      dateRangeStr = 'Date From All To All';
    }

    final String paymentStr = _typeFilter == 'cash'
        ? 'Cash'
        : (_typeFilter == 'khqr' ? 'Bakong KHQR' : 'All');
    final String statusStr = _typeFilter == 'voided'
        ? 'Voided'
        : (_typeFilter == 'all' ? 'All' : 'Active');

    int grandGuest = 0;
    double grandSubtotal = 0.0;
    double grandDiscount = 0.0;
    double grandGrandTotal = 0.0;
    double grandDollar = 0.0;
    double grandCard = 0.0;
    double grandRevenue = 0.0;

    final buffer = StringBuffer();

    groupedByCashier.forEach((cashierName, cashierOrders) {
      buffer.writeln('''
        <tr class="cashier-group-row">
          <td colspan="17"><strong>Cashier : $cashierName</strong></td>
        </tr>
      ''');

      int groupGuest = 0;
      double groupSubtotal = 0.0;
      double groupDiscount = 0.0;
      double groupGrandTotal = 0.0;
      double groupDollar = 0.0;
      double groupCard = 0.0;
      double groupRevenue = 0.0;

      int idx = 0;
      for (final order in cashierOrders) {
        idx++;
        final int guest = order.items
            .fold<int>(0, (s, i) => s + i.quantity)
            .clamp(1, 999);
        final double subtotal =
            order.subtotalUsd > 0 ? order.subtotalUsd : order.totalUsd;
        final double discount = order.discountUsd;
        final double grandTotal = order.totalUsd;
        final double dollar =
            (!order.isKhqr && !order.isVoided) ? order.totalUsd : 0.0;
        final double card =
            (order.isKhqr && !order.isVoided) ? order.totalUsd : 0.0;
        final double revenue = !order.isVoided ? order.totalUsd : 0.0;

        groupGuest += guest;
        groupSubtotal += subtotal;
        groupDiscount += discount;
        groupGrandTotal += grandTotal;
        groupDollar += dollar;
        groupCard += card;
        groupRevenue += revenue;

        final String registerNo = order.id > 0
            ? 'R${order.id.toString().padLeft(10, '0')}'
            : 'R0000000329';
        final String counterName = setting.branchName.isNotEmpty
            ? setting.branchName
            : 'SERVERANGKORBAR';
        final String tableName = order.customerName != null &&
                order.customerName!.toLowerCase().contains('table')
            ? order.customerName!
            : 'Table -';
        final String custName = order.customerName ?? '';

        final String rowStyle = order.isVoided
            ? 'text-decoration:line-through;color:#999;'
            : '';

        buffer.writeln('''
          <tr class="item-row" style="$rowStyle">
            <td class="center">$idx</td>
            <td>$registerNo</td>
            <td><strong>${order.invoiceNo}</strong></td>
            <td>${formatDateTime(order.createdAt)}</td>
            <td>$counterName</td>
            <td>$tableName</td>
            <td>$custName</td>
            <td class="center">$guest</td>
            <td class="right">\$${subtotal.toStringAsFixed(2)}</td>
            <td class="right">\$${discount.toStringAsFixed(2)}</td>
            <td class="right"><strong>\$${grandTotal.toStringAsFixed(2)}</strong></td>
            <td class="right">\$0.00</td>
            <td class="right">\$0.00</td>
            <td class="right">\$${dollar.toStringAsFixed(2)}</td>
            <td class="right">\$0</td>
            <td class="right">\$${card.toStringAsFixed(2)}</td>
            <td class="right"><strong>\$${revenue.toStringAsFixed(2)}</strong></td>
          </tr>
        ''');
      }

      grandGuest += groupGuest;
      grandSubtotal += groupSubtotal;
      grandDiscount += groupDiscount;
      grandGrandTotal += groupGrandTotal;
      grandDollar += groupDollar;
      grandCard += groupCard;
      grandRevenue += groupRevenue;

      // Group Subtotal Row
      buffer.writeln('''
        <tr class="group-total-row">
          <td colspan="5"><strong>Count $cashierName : ${cashierOrders.length} Invoice (s)</strong></td>
          <td colspan="2"><strong>Total $cashierName</strong></td>
          <td class="center"><strong>$groupGuest</strong></td>
          <td class="right"><strong>\$${groupSubtotal.toStringAsFixed(2)}</strong></td>
          <td class="right"><strong>\$${groupDiscount.toStringAsFixed(2)}</strong></td>
          <td class="right"><strong>\$${groupGrandTotal.toStringAsFixed(2)}</strong></td>
          <td class="right"><strong>\$0.00</strong></td>
          <td class="right"><strong>\$0.00</strong></td>
          <td class="right"><strong>\$${groupDollar.toStringAsFixed(2)}</strong></td>
          <td class="right"><strong>\$0</strong></td>
          <td class="right"><strong>\$${groupCard.toStringAsFixed(2)}</strong></td>
          <td class="right"><strong>\$${groupRevenue.toStringAsFixed(2)}</strong></td>
        </tr>
      ''');
    });

    final now = DateTime.now();
    final hour =
        now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    final runOnStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${hour.toString().padLeft(2, '0')}:$minute$ampm';

    final htmlDoc = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Sale Register Report by Cashier</title>
  <style>
    @page {
      size: A4 landscape;
      margin: 10mm 8mm 12mm 8mm;
    }
    body {
      font-family: Arial, "Helvetica Neue", Helvetica, sans-serif;
      font-size: 9px;
      color: #000;
      margin: 0;
      padding: 10px;
      background: #fff;
    }
    .store-title {
      font-size: 20px;
      font-weight: bold;
      margin-bottom: 8px;
    }
    .report-title {
      font-size: 13px;
      font-weight: bold;
      margin: 10px 0 6px 0;
    }
    .meta-block {
      font-size: 9px;
      line-height: 1.4;
      margin-bottom: 6px;
    }
    .meta-line {
      margin-bottom: 2px;
    }
    table.report-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 8.5px;
    }
    table.report-table thead th {
      border-top: 1.5px solid #000;
      border-bottom: 1.5px solid #000;
      padding: 5px 3px;
      font-weight: normal;
      font-size: 8.5px;
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
    tr.cashier-group-row td {
      padding: 8px 3px 4px 3px;
      font-size: 9px;
      font-weight: bold;
    }
    tr.item-row td {
      padding: 3.5px 3px;
      border-bottom: 1px dotted #888;
      font-size: 8.5px;
    }
    tr.group-total-row td {
      padding: 6px 3px;
      border-top: 1.5px solid #000;
      border-bottom: 1.5px solid #000;
      font-size: 8.5px;
      font-weight: bold;
    }
    tr.grand-total-row td {
      padding: 7px 3px;
      font-size: 8.5px;
      font-weight: bold;
      border-top: 1.5px solid #000;
      border-bottom: 2px solid #000;
    }
    tfoot {
      display: table-row-group;
    }
    .footer-bar {
      margin-top: 16px;
      display: flex;
      justify-content: space-between;
      font-size: 9px;
      color: #333;
    }
    @media print {
      .no-print { display: none !important; }
      body { padding: 0; }
      tfoot { display: table-row-group; }
      tr.item-row { page-break-inside: avoid; }
      tr.cashier-group-row { page-break-after: avoid; }
      tr.group-total-row { page-break-before: avoid; }
    }
  </style>
</head>
<body onload="window.print();">
  <div class="no-print" style="margin-bottom:12px;">
    <button onclick="window.print();" style="padding:8px 18px;background:#000;color:#fff;border:none;border-radius:4px;cursor:pointer;font-weight:bold;font-size:12px;">
      🖨️ Print Cashier Register Report (Landscape)
    </button>
  </div>

  <div class="store-title">${setting.martNameKh.isNotEmpty ? setting.martNameKh : setting.martNameEn}</div>

  <div class="meta-block">
    <div class="meta-line">Invoice Status : $statusStr</div>
    <div class="meta-line">Payment : $paymentStr</div>
    <div class="meta-line">$dateRangeStr</div>
    <div class="meta-line">From Cashier ... To ...</div>
  </div>

  <div class="report-title">Sale Register Report by Cashier</div>

  <table class="report-table">
    <thead>
      <tr>
        <th class="center" style="width:24px;">Nº</th>
        <th style="width:75px;">Register Nº</th>
        <th style="width:75px;">Invoice Nº</th>
        <th style="width:95px;">Invoice Date</th>
        <th style="width:90px;">Counter</th>
        <th style="width:55px;">Table Nº</th>
        <th style="width:85px;">Customer Name</th>
        <th class="center" style="width:35px;">Guest</th>
        <th class="right" style="width:50px;">Sub Total</th>
        <th class="right" style="width:48px;">Discount</th>
        <th class="right" style="width:58px;">Grand Total</th>
        <th class="right" style="width:40px;">Free</th>
        <th class="right" style="width:45px;">Balance</th>
        <th class="right" style="width:50px;">Dollar</th>
        <th class="right" style="width:38px;">Riel</th>
        <th class="right" style="width:55px;">Credit Card</th>
        <th class="right" style="width:55px;">Revenue</th>
      </tr>
    </thead>
    <tbody>
      $buffer
    </tbody>
    <tfoot>
      <tr class="grand-total-row">
        <td colspan="7"><strong>Count : ${filtered.length} Invoice (s)</strong></td>
        <td class="center"><strong>$grandGuest</strong></td>
        <td class="right"><strong>\$${grandSubtotal.toStringAsFixed(2)}</strong></td>
        <td class="right"><strong>\$${grandDiscount.toStringAsFixed(2)}</strong></td>
        <td class="right"><strong>\$${grandGrandTotal.toStringAsFixed(2)}</strong></td>
        <td class="right"><strong>\$0.00</strong></td>
        <td class="right"><strong>\$0.00</strong></td>
        <td class="right"><strong>\$${grandDollar.toStringAsFixed(2)}</strong></td>
        <td class="right"><strong>\$0</strong></td>
        <td class="right"><strong>\$${grandCard.toStringAsFixed(2)}</strong></td>
        <td class="right"><strong>\$${grandRevenue.toStringAsFixed(2)}</strong></td>
      </tr>
    </tfoot>
  </table>

  <div class="footer-bar">
    <div>Report run on $runOnStr</div>
    <div>Page 1 of 1</div>
  </div>
</body>
</html>
''';

    final opened = await triggerPlatformPrintHtml(
        htmlDoc, 'Sale_Register_Report_by_Cashier');
    if (opened == null) {
      await _copySummaryTotalsText(filtered);
    }
  }

  Future<void> _copySummaryTotalsText(List<OrderModel> filtered) async {
    final bool isEn = AppLanguage.isEnglish;
    final activeOrders = filtered.where((o) => !o.isVoided).toList();
    final voidedOrders = filtered.where((o) => o.isVoided).toList();
    final double cashUsd = activeOrders
        .where((o) => !o.isKhqr)
        .fold(0.0, (sum, o) => sum + o.totalUsd);
    final double khqrUsd = activeOrders
        .where((o) => o.isKhqr)
        .fold(0.0, (sum, o) => sum + o.totalUsd);
    final double netUsd =
        activeOrders.fold(0.0, (sum, o) => sum + o.totalUsd);
    final double netKhr =
        activeOrders.fold(0.0, (sum, o) => sum + o.totalKhr);

    final sb = StringBuffer()
      ..writeln('📊 SALES INVOICE SUMMARY (${_activePeriodLabel(isEn)})')
      ..writeln('----------------------------------------')
      ..writeln(
          '• Active Bills: ${activeOrders.length} (${voidedOrders.length} voided)')
      ..writeln(
          '• Cash Sales: ${_martService.formatUsd(cashUsd)} (${_martService.formatKhr(cashUsd * _martService.exchangeRate)})')
      ..writeln(
          '• Bakong KHQR: ${_martService.formatUsd(khqrUsd)} (${_martService.formatKhr(khqrUsd * _martService.exchangeRate)})')
      ..writeln(
          '• NET TOTAL: ${_martService.formatUsd(netUsd)} (${_martService.formatKhr(netKhr)})')
      ..writeln('----------------------------------------');

    for (final o in filtered) {
      sb.writeln(
          '${o.invoiceNo} | ${o.createdAt} | ${_paymentLabel(o.paymentMethod, true)} | ${_martService.formatUsd(o.totalUsd)}${o.isVoided ? ' [VOIDED]' : ''}');
    }

    await Clipboard.setData(ClipboardData(text: sb.toString()));
    EasyLoading.showSuccess(
      isEn
          ? 'Summary & totals copied to clipboard!'
          : 'បានចម្លងរបាយការណ៍សរុបរួចរាល់!',
    );
  }

  void _showExportTotalsModal(List<OrderModel> filtered) {
    final bool isEn = AppLanguage.isEnglish;
    final activeOrders = filtered.where((o) => !o.isVoided).toList();
    final voidedOrders = filtered.where((o) => o.isVoided).toList();
    final double cashUsd = activeOrders
        .where((o) => !o.isKhqr)
        .fold(0.0, (sum, o) => sum + o.totalUsd);
    final double khqrUsd = activeOrders
        .where((o) => o.isKhqr)
        .fold(0.0, (sum, o) => sum + o.totalUsd);
    final double netUsd =
        activeOrders.fold(0.0, (sum, o) => sum + o.totalUsd);
    final double netKhr =
        activeOrders.fold(0.0, (sum, o) => sum + o.totalKhr);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isEn
                          ? 'Export & Print Invoices Summary'
                          : 'ទាញយក & បោះពុម្ពរបាយការណ៍សរុប',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _activePeriodLabel(isEn),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _buildReceiptMetaRow(
                      isEn ? 'Active Invoices:' : 'វិក្កយបត្រជោគជ័យ:',
                      '${activeOrders.length} (${voidedOrders.length} ${isEn ? 'voided' : 'បោះបង់'})',
                      isBold: true,
                    ),
                    _buildReceiptMetaRow(
                      isEn ? 'Cash Sales:' : 'លក់ជាសាច់ប្រាក់:',
                      '${_martService.formatUsd(cashUsd)} (${_martService.formatKhr(cashUsd * _martService.exchangeRate)})',
                    ),
                    _buildReceiptMetaRow(
                      isEn ? 'Bakong KHQR Sales:' : 'លក់តាមបាគង KHQR:',
                      '${_martService.formatUsd(khqrUsd)} (${_martService.formatKhr(khqrUsd * _martService.exchangeRate)})',
                    ),
                    const Divider(height: 14),
                    _buildReceiptMetaRow(
                      isEn ? 'Net Total Revenue:' : 'ចំណូលសរុបរួម:',
                      '${_martService.formatUsd(netUsd)} • ${_martService.formatKhr(netKhr)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: Text(
                  isEn
                      ? 'Export Invoices & Totals to CSV (Excel)'
                      : 'ទាញយកវិក្កយបត្រ & សរុបជា CSV',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _exportFilteredCsv(filtered);
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.print_rounded),
                label: Text(
                  isEn
                      ? 'Print Cashier Register Report'
                      : 'បោះពុម្ពរបាយការណ៍បេឡាករ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _printSummaryReport(filtered);
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.copy_all_rounded, size: 18),
                label: Text(
                  isEn
                      ? 'Copy Totals Summary to Clipboard'
                      : 'ចម្លងរបាយការណ៍សរុប',
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _copySummaryTotalsText(filtered);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmVoidOrder(OrderModel order, {bool closeReceiptDialog = false}) {
    final bool isEn = AppLanguage.isEnglish;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isEn
                    ? 'Void Invoice ${order.invoiceNo}?'
                    : 'បោះបង់វិក្កយបត្រ ${order.invoiceNo}?',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          isEn
              ? 'This will cancel the invoice (${_martService.formatUsd(order.totalUsd)}) and automatically restore all ${order.items.length} item(s) back to inventory stock.'
              : 'ការបោះបង់វិក្កយបត្រនេះ (${_martService.formatUsd(order.totalUsd)}) នឹងបង្វិលទំនិញទាំង ${order.items.length} មុខ ចូលទៅក្នុងស្តុកវិញដោយស្វ័យប្រវត្តិ។',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Keep Invoice' : 'រក្សាទុកវិក្កយបត្រ'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            icon: const Icon(Icons.cancel_outlined,
                size: 16, color: Colors.white),
            label: Text(
              isEn ? 'Confirm Void' : 'បញ្ជាក់ការបោះបង់',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (closeReceiptDialog && mounted) {
                Navigator.pop(context);
              }
              EasyLoading.show(
                  status: isEn ? 'Voiding invoice...' : 'កំពុងបោះបង់...');
              final ok = await _martService.voidOrder(order);
              EasyLoading.dismiss();
              if (ok && mounted) {
                setState(() {});
                EasyLoading.showSuccess(
                  isEn
                      ? 'Invoice voided & stock restored!'
                      : 'បានបោះបង់វិក្កយបត្រ និងបង្វិលស្តុកវិញរួចរាល់!',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = AppLanguage.isEnglish;
    final filtered = _filteredOrders;

    // Calculate live summary metrics for non-voided orders in current filter
    final activeFiltered = filtered.where((o) => !o.isVoided).toList();
    final double totalUsd =
        activeFiltered.fold(0.0, (sum, o) => sum + o.totalUsd);
    final double totalKhr =
        activeFiltered.fold(0.0, (sum, o) => sum + o.totalKhr);
    final double cashUsd = activeFiltered
        .where((o) => !o.isKhqr)
        .fold(0.0, (sum, o) => sum + o.totalUsd);
    final double khqrUsd = activeFiltered
        .where((o) => o.isKhqr)
        .fold(0.0, (sum, o) => sum + o.totalUsd);

    final String customDateLabel =
        _dateFilter == 'custom_date' && _selectedDate != null
            ? _formatYmd(_selectedDate!)
            : (isEn ? 'Pick Date' : 'ជ្រើសរើសថ្ងៃ');

    final String customRangeLabel =
        _dateFilter == 'custom_range' && _selectedRange != null
            ? '${_selectedRange!.start.day}/${_selectedRange!.start.month} (${_formatTimeOfDay(_startTime)}) → ${_selectedRange!.end.day}/${_selectedRange!.end.month} (${_formatTimeOfDay(_endTime)})'
            : (isEn ? 'Date & Time Range' : 'ចន្លោះថ្ងៃ & ម៉ោង');

    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          isEn ? 'Sales Invoices' : 'ប្រវត្តិវិក្កយបត្រ',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: isEn
                ? 'Print Cashier Register Report'
                : 'បោះពុម្ពរបាយការណ៍បេឡាករ',
            icon: const Icon(Icons.print_outlined, color: Colors.white),
            onPressed: () => _printSummaryReport(filtered),
          ),
          IconButton(
            tooltip: isEn ? 'Export CSV / Totals' : 'ទាញយករបាយការណ៍សរុប',
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () => _showExportTotalsModal(filtered),
          ),
          IconButton(
            tooltip: isEn ? 'Refresh' : 'ផ្ទុកឡើងវិញ',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search & Date / Payment Filter Control Bar
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
                        ? 'Search invoice #, customer, cashier, or item...'
                        : 'ស្វែងរកលេខវិក្កយបត្រ, អតិថិជន, បេឡាករ ឬទំនិញ...',
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
                      _buildDateChip(
                        value: 'today',
                        label: isEn ? 'Today' : 'ថ្ងៃនេះ',
                        icon: Icons.today,
                        onTap: () => setState(() => _dateFilter = 'today'),
                      ),
                      const SizedBox(width: 6),
                      _buildDateChip(
                        value: 'all',
                        label: isEn ? 'All Dates' : 'ទាំងអស់',
                        icon: Icons.calendar_month,
                        onTap: () => setState(() => _dateFilter = 'all'),
                      ),
                      const SizedBox(width: 6),
                      _buildDateChip(
                        value: 'custom_date',
                        label: customDateLabel,
                        icon: Icons.event_available,
                        onTap: _pickSingleDate,
                      ),
                      const SizedBox(width: 6),
                      _buildDateChip(
                        value: 'custom_range',
                        label: customRangeLabel,
                        icon: Icons.date_range,
                        onTap: _pickDateRange,
                      ),
                      Container(
                        height: 20,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.grey.shade300,
                      ),
                      _buildTypeChip(
                        'all',
                        isEn ? 'All Types' : 'គ្រប់ប្រភេទ',
                        AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      _buildTypeChip(
                        'cash',
                        isEn ? 'Cash' : 'សាច់ប្រាក់',
                        AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      _buildTypeChip(
                        'khqr',
                        isEn ? 'Bakong KHQR' : 'បាគង KHQR',
                        AppColors.khqrBakongRed,
                      ),
                      const SizedBox(width: 6),
                      _buildTypeChip(
                        'voided',
                        isEn ? 'Voided' : 'បានបោះបង់',
                        AppColors.danger,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Cashier Live Summary Strip + Export / Print Totals Controls
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
                      label: isEn ? 'Active Bills' : 'វិក្កយបត្រសរុប',
                      value: '${activeFiltered.length}',
                      subValue: isEn
                          ? '${filtered.length - activeFiltered.length} voided'
                          : 'បោះបង់ ${filtered.length - activeFiltered.length}',
                      color: AppColors.textPrimary,
                    ),
                    _buildVerticalDivider(),
                    _buildSummaryMetric(
                      label: isEn ? 'Cash Sales' : 'សាច់ប្រាក់',
                      value: _martService.formatUsd(cashUsd),
                      subValue: _martService
                          .formatKhr(cashUsd * _martService.exchangeRate),
                      color: AppColors.success,
                    ),
                    _buildVerticalDivider(),
                    _buildSummaryMetric(
                      label: isEn ? 'KHQR Sales' : 'បាគង KHQR',
                      value: _martService.formatUsd(khqrUsd),
                      subValue: _martService
                          .formatKhr(khqrUsd * _martService.exchangeRate),
                      color: AppColors.khqrBakongRed,
                    ),
                    _buildVerticalDivider(),
                    _buildSummaryMetric(
                      label: isEn ? 'Net Total' : 'ចំណូលសរុប',
                      value: _martService.formatUsd(totalUsd),
                      subValue: _martService.formatKhr(totalKhr),
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
                        '📅 ${_activePeriodLabel(isEn)}',
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
                          onTap: () => _printSummaryReport(filtered),
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
                                  isEn ? 'Print Report' : 'បោះពុម្ពរបាយការណ៍',
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
                          onTap: () => _exportFilteredCsv(filtered),
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

          // 3. Invoice List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              isEn
                                  ? 'No matching sales invoices found'
                                  : 'មិនមានវិក្កយបត្រត្រូវនឹងការស្វែងរកទេ',
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final order = filtered[index];
                            return _buildInvoiceCard(order, isEn);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip({
    required String value,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool selected = _dateFilter == value;
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

  Widget _buildTypeChip(String value, String label, Color activeColor) {
    final bool selected = _typeFilter == value;
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
      onSelected: (_) => setState(() => _typeFilter = value),
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

  Widget _buildInvoiceCard(OrderModel order, bool isEn) {
    final bool isKhqr = order.isKhqr;
    final bool isVoided = order.isVoided;
    final int totalQty =
        order.items.fold(0, (sum, item) => sum + item.quantity);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isVoided
            ? BorderSide(color: AppColors.danger.withValues(alpha: 0.35))
            : BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _showReceiptDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Invoice No + Status / Payment badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isVoided ? Icons.receipt_long : Icons.receipt,
                        size: 16,
                        color: isVoided ? AppColors.danger : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order.invoiceNo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color:
                              isVoided ? AppColors.danger : AppColors.primary,
                          decoration:
                              isVoided ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (isVoided) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isEn ? 'VOIDED' : 'បានបោះបង់',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isKhqr
                              ? AppColors.khqrBakongRed.withValues(alpha: 0.12)
                              : AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _paymentLabel(order.paymentMethod, isEn),
                          style: TextStyle(
                            color: isKhqr
                                ? AppColors.khqrBakongRed
                                : AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Date, Cashier & Customer info
              Wrap(
                spacing: 10,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        order.createdAt,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        order.cashierName ?? (isEn ? 'Cashier' : 'បេឡាករ'),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (order.customerName != null &&
                      order.customerName!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '👤 ${order.customerName}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                ],
              ),

              // Quick item preview pills
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...order.items.take(3).map(
                          (it) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '${it.productName} ×${it.quantity}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                    if (order.items.length > 3)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '+${order.items.length - 3} ${isEn ? 'more' : 'ទៀត'}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],

              const Divider(height: 16),

              // Bottom row: Item count + Quick Cashier Buttons (Print, Copy, Void) + Totals
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        isEn
                            ? '${order.items.length} items ($totalQty)'
                            : '${order.items.length} មុខ ($totalQty)',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      // Quick Print Invoice button
                      InkWell(
                        onTap: () => _printSingleInvoice(order),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.print,
                                  size: 13, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text(
                                isEn ? 'Print' : 'បោះពុម្ព',
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
                      // Quick Copy button
                      InkWell(
                        onTap: () => _copyInvoiceText(order, isEn),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      // Quick Void button (only if not voided)
                      if (!isVoided)
                        InkWell(
                          onTap: () => _confirmVoidOrder(order),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 3),
                            child: Text(
                              isEn ? 'Void' : 'បោះបង់',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _martService.formatUsd(order.totalUsd),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isVoided
                              ? AppColors.textSecondary
                              : AppColors.primary,
                          decoration:
                              isVoided ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Text(
                        _martService.formatKhr(order.totalKhr),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isVoided
                              ? AppColors.textSecondary
                              : AppColors.secondary,
                          decoration:
                              isVoided ? TextDecoration.lineThrough : null,
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

  void _showReceiptDetails(OrderModel order) {
    final bool isEn = AppLanguage.isEnglish;
    final setting = _martService.getSettings();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (order.isVoided)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isEn
                            ? 'VOIDED INVOICE (STOCK RESTORED)'
                            : 'វិក្កយបត្រត្រូវបានបោះបង់ (បានបង្វិលស្តុកវិញ)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Text(setting.martNameKh,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  Text(setting.martNameEn,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  Text(setting.branchName,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  const Divider(height: 20),

                  // Receipt metadata
                  _buildReceiptMetaRow(
                    isEn ? 'Invoice No:' : 'លេខវិក្កយបត្រ:',
                    order.invoiceNo,
                    isBold: true,
                  ),
                  _buildReceiptMetaRow(
                    isEn ? 'Date:' : 'កាលបរិច្ឆេទ:',
                    order.createdAt,
                  ),
                  _buildReceiptMetaRow(
                    isEn ? 'Cashier:' : 'បេឡាករ:',
                    order.cashierName ?? '-',
                  ),
                  if (order.customerName != null &&
                      order.customerName!.isNotEmpty)
                    _buildReceiptMetaRow(
                      isEn ? 'Customer:' : 'អតិថិជន:',
                      order.customerName!,
                    ),
                  _buildReceiptMetaRow(
                    isEn ? 'Payment Method:' : 'ទូទាត់តាម:',
                    _paymentLabel(order.paymentMethod, isEn),
                    isBold: true,
                  ),
                  const Divider(height: 20),

                  // Items header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEn ? 'Item / Qty' : 'មុខទំនិញ / ចំនួន',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary),
                      ),
                      Text(
                        isEn ? 'Subtotal' : 'សរុប',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...order.items.map((it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it.productName,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${_martService.formatUsd(it.unitPriceUsd)} × ${it.quantity}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _martService.formatUsd(it.subtotalUsd),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 20),

                  // Totals & Cash / Change Breakdown
                  if (order.discountUsd > 0)
                    _buildReceiptMetaRow(
                      isEn ? 'Discount:' : 'បញ្ចុះតម្លៃ:',
                      '-${_martService.formatUsd(order.discountUsd)}',
                    ),
                  if (order.taxUsd > 0)
                    _buildReceiptMetaRow(
                      isEn ? 'Tax:' : 'ពន្ធ:',
                      _martService.formatUsd(order.taxUsd),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEn ? 'Total USD:' : 'សរុបដុល្លារ:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _martService.formatUsd(order.totalUsd),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEn ? 'Total KHR:' : 'សរុបរៀល:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _martService.formatKhr(order.totalKhr),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Cash Received & Change Given Box for Cashier Verification
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (order.receivedUsd > 0 || order.isKhqr)
                          _buildReceiptMetaRow(
                            isEn ? 'Received (USD):' : 'ប្រាក់ទទួល (\$):',
                            _martService.formatUsd(order.receivedUsd),
                          ),
                        if (order.receivedKhr > 0 && !order.isKhqr)
                          _buildReceiptMetaRow(
                            isEn ? 'Received (KHR):' : 'ប្រាក់ទទួល (៛):',
                            _martService.formatKhr(order.receivedKhr),
                          ),
                        if (!order.isKhqr) ...[
                          _buildReceiptMetaRow(
                            isEn ? 'Change (USD):' : 'ប្រាក់អាប់ (\$):',
                            _martService.formatUsd(order.changeUsd),
                            isBold: true,
                          ),
                          _buildReceiptMetaRow(
                            isEn ? 'Change (KHR):' : 'ប្រាក់អាប់ (៛):',
                            _martService.formatKhr(order.changeKhr),
                            isBold: true,
                          ),
                        ],
                        if (order.pointsEarned > 0)
                          _buildReceiptMetaRow(
                            isEn ? 'Points Earned:' : 'ពិន្ទុទទួលបាន:',
                            '+${order.pointsEarned} pts',
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
                      onPressed: () => _printSingleInvoice(order),
                      icon: const Icon(Icons.print,
                          size: 18, color: Colors.white),
                      label: Text(
                        isEn
                            ? 'Print Invoice (${order.invoiceNo})'
                            : 'បោះពុម្ពវិក្កយបត្រ (${order.invoiceNo})',
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
                          onPressed: () => _copyInvoiceText(order, isEn),
                          icon: const Icon(Icons.copy, size: 15),
                          label: Text(
                            isEn ? 'Copy' : 'ចម្លង',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      if (!order.isVoided) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                            ),
                            onPressed: () => _confirmVoidOrder(
                              order,
                              closeReceiptDialog: true,
                            ),
                            icon: const Icon(Icons.cancel_outlined, size: 15),
                            label: Text(
                              isEn ? 'Void Bill' : 'បោះបង់',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
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
        );
      },
    );
  }

  Widget _buildReceiptMetaRow(String label, String value,
      {bool isBold = false}) {
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
