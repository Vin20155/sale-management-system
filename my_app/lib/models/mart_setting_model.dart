class MartSettingModel {
  String martNameEn;
  String martNameKh;
  String branchName;
  String phone;
  String addressKh;
  double exchangeRate;
  double taxPercentage;
  String bakongAccountId;
  String bakongMerchantName;
  String receiptFooterKh;
  String language;

  MartSettingModel({
    this.martNameEn = 'Lucky Express Mart',
    this.martNameKh = 'ឡាក់គី អិចប្រេស ម៉ាត',
    this.branchName = 'សាខាទួលគោក, ភ្នំពេញ',
    this.phone = '012 345 678',
    this.addressKh = 'ផ្ទះលេខ 45A, ផ្លូវ 315, ទួលគោក, ភ្នំពេញ',
    this.exchangeRate = 4100.0,
    this.taxPercentage = 0.0,
    this.bakongAccountId = 'lucky_express@aclb',
    this.bakongMerchantName = 'LUCKY EXPRESS MART',
    this.receiptFooterKh = 'សូមអរគុណ! សូមអញ្ជើញមកម្តងទៀត',
    this.language = 'km',
  });

  factory MartSettingModel.fromJson(Map<String, dynamic> json) {
    return MartSettingModel(
      martNameEn: json['mart_name_en'] ?? 'Lucky Express Mart',
      martNameKh: json['mart_name_kh'] ?? 'ឡាក់គី អិចប្រេស ម៉ាត',
      branchName: json['branch_name'] ?? 'សាខាទួលគោក, ភ្នំពេញ',
      phone: json['phone'] ?? '012 345 678',
      addressKh: json['address_kh'] ?? 'រាជធានីភ្នំពេញ',
      exchangeRate: (json['exchange_rate'] ?? 4100.0).toDouble(),
      taxPercentage: (json['tax_percentage'] ?? 0.0).toDouble(),
      bakongAccountId: json['bakong_account_id'] ?? 'lucky_express@aclb',
      bakongMerchantName: json['bakong_merchant_name'] ?? 'LUCKY EXPRESS MART',
      receiptFooterKh:
          json['receipt_footer_kh'] ?? 'សូមអរគុណ! សូមអញ្ជើញមកម្តងទៀត',
      language: json['language'] ?? 'km',
    );
  }

  Map<String, dynamic> toJson() => {
        'mart_name_en': martNameEn,
        'mart_name_kh': martNameKh,
        'branch_name': branchName,
        'phone': phone,
        'address_kh': addressKh,
        'exchange_rate': exchangeRate,
        'tax_percentage': taxPercentage,
        'bakong_account_id': bakongAccountId,
        'bakong_merchant_name': bakongMerchantName,
        'receipt_footer_kh': receiptFooterKh,
        'language': language,
      };
}
