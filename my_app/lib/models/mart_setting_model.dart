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
  String receiptFooterEn;
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
    this.receiptFooterEn = 'Thank you! Please come again',
    this.language = 'km',
  });
}
