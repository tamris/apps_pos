class CafeSettingsModel {
  final String shopName;
  final String address;
  final String phone;
  final String? shopLogoUrl;
  final bool showLogoReceipt;
  final String receiptFooter;
  final bool autoPrintReceipt;
  final bool autoPrintKitchen;
  final String wifiName;
  final String wifiPassword;
  final int printerPaperWidth;

  CafeSettingsModel({
    this.shopName = 'POS Cafe',
    this.address = 'Alamat Toko',
    this.phone = '',
    this.shopLogoUrl,
    this.showLogoReceipt = true,
    this.receiptFooter = 'Terima Kasih Atas Kunjungan Anda!',
    this.autoPrintReceipt = true,
    this.autoPrintKitchen = false,
    this.wifiName = '',
    this.wifiPassword = '',
    this.printerPaperWidth = 58,
  });

  factory CafeSettingsModel.fromJson(Map<String, dynamic> json) {
    return CafeSettingsModel(
      shopName: json['shop_name'] ?? 'POS Cafe',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      shopLogoUrl: json['shop_logo_url']?.toString(),
      showLogoReceipt: json['show_logo_receipt'] == 1 || json['show_logo_receipt'] == true,
      receiptFooter: json['receipt_footer'] ?? 'Terima Kasih Atas Kunjungan Anda!',
      autoPrintReceipt: json['auto_print_receipt'] == 1 || json['auto_print_receipt'] == true,
      autoPrintKitchen: json['auto_print_kitchen'] == 1 || json['auto_print_kitchen'] == true,
      wifiName: json['wifi_name'] ?? '',
      wifiPassword: json['wifi_password'] ?? '',
      printerPaperWidth: json['printer_paper_width'] is int
          ? json['printer_paper_width']
          : int.tryParse(json['printer_paper_width']?.toString() ?? '58') ?? 58,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shop_name': shopName,
      'address': address,
      'phone': phone,
      'shop_logo_url': shopLogoUrl,
      'show_logo_receipt': showLogoReceipt,
      'receipt_footer': receiptFooter,
      'auto_print_receipt': autoPrintReceipt,
      'auto_print_kitchen': autoPrintKitchen,
      'wifi_name': wifiName,
      'wifi_password': wifiPassword,
      'printer_paper_width': printerPaperWidth,
    };
  }
}
