part of 'mart_service.dart';

extension ShiftService on MartService {
  // ==========================================
  // SHIFTS & CASH DRAWER
  // ==========================================
  ShiftModel? getCurrentShift() => _currentShift;

  Future<ShiftModel> openShift(double openingUsd, double openingKhr) async {
    final shift = ShiftModel(
      id: DateTime.now().millisecondsSinceEpoch,
      cashierId: 1,
      openingCashUsd: openingUsd,
      openingCashKhr: openingKhr,
      status: 'open',
      openedAt: DateTime.now().toString().substring(0, 16),
    );
    _currentShift = shift;
    return shift;
  }

  Future<ShiftModel> closeShift(double closingUsd, double closingKhr) async {
    if (_currentShift != null) {
      _currentShift!.closingCashUsd = closingUsd;
      _currentShift!.closingCashKhr = closingKhr;
      _currentShift!.status = 'closed';
      _currentShift!.closedAt = DateTime.now().toString().substring(0, 16);
    }
    final s = _currentShift!;
    _currentShift = null;
    return s;
  }
}
