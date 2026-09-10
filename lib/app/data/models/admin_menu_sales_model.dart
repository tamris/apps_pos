class AdminMenuSalesSummaryModel {
  final int totalQuantitySold;
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final double profitMargin;
  final int totalUniqueItemsSold;
  final TopSellingProductInfo? topSellingProduct;

  AdminMenuSalesSummaryModel({
    required this.totalQuantitySold,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.profitMargin,
    required this.totalUniqueItemsSold,
    this.topSellingProduct,
  });

  factory AdminMenuSalesSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminMenuSalesSummaryModel(
      totalQuantitySold: (json['total_quantity_sold'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (json['total_profit'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (json['profit_margin'] as num?)?.toDouble() ?? 0.0,
      totalUniqueItemsSold: (json['total_unique_items_sold'] as num?)?.toInt() ?? 0,
      topSellingProduct: json['top_selling_product'] != null
          ? TopSellingProductInfo.fromJson(json['top_selling_product'])
          : null,
    );
  }

  factory AdminMenuSalesSummaryModel.empty() {
    return AdminMenuSalesSummaryModel(
      totalQuantitySold: 0,
      totalRevenue: 0.0,
      totalCost: 0.0,
      totalProfit: 0.0,
      profitMargin: 0.0,
      totalUniqueItemsSold: 0,
      topSellingProduct: null,
    );
  }
}

class TopSellingProductInfo {
  final int id;
  final String name;
  final int quantitySold;
  final double totalRevenue;

  TopSellingProductInfo({
    required this.id,
    required this.name,
    required this.quantitySold,
    required this.totalRevenue,
  });

  factory TopSellingProductInfo.fromJson(Map<String, dynamic> json) {
    return TopSellingProductInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '-',
      quantitySold: (json['quantity_sold'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AdminMenuSalesPeriodModel {
  final String range;
  final String label;
  final String startDate;
  final String endDate;

  AdminMenuSalesPeriodModel({
    required this.range,
    required this.label,
    required this.startDate,
    required this.endDate,
  });

  factory AdminMenuSalesPeriodModel.fromJson(Map<String, dynamic> json) {
    return AdminMenuSalesPeriodModel(
      range: json['range']?.toString() ?? 'this_month',
      label: json['label']?.toString() ?? 'Bulan Ini',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
    );
  }

  factory AdminMenuSalesPeriodModel.empty() => AdminMenuSalesPeriodModel(
        range: 'this_month',
        label: 'Bulan Ini',
        startDate: '',
        endDate: '',
      );
}

class AdminMenuSalesItemModel {
  final int rank;
  final int productId;
  final String productName;
  final String sku;
  final int? categoryId;
  final String categoryName;
  final String? imageUrl;
  final bool isActive;
  final bool isDeleted;
  final double unitPrice;
  final double costPrice;
  final int quantitySold;
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final double profitMargin;
  final double salesSharePercentage;
  final double revenueSharePercentage;
  final int transactionsCount;

  AdminMenuSalesItemModel({
    required this.rank,
    required this.productId,
    required this.productName,
    required this.sku,
    this.categoryId,
    required this.categoryName,
    this.imageUrl,
    required this.isActive,
    required this.isDeleted,
    required this.unitPrice,
    required this.costPrice,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.profitMargin,
    required this.salesSharePercentage,
    required this.revenueSharePercentage,
    required this.transactionsCount,
  });

  factory AdminMenuSalesItemModel.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as Map<String, dynamic>?;

    return AdminMenuSalesItemModel(
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      productName: json['product_name']?.toString() ?? '-',
      sku: json['sku']?.toString() ?? '',
      categoryId: cat != null
          ? (cat['id'] as num?)?.toInt()
          : (json['category_id'] as num?)?.toInt(),
      categoryName: cat != null
          ? (cat['name']?.toString() ?? 'Tanpa Kategori')
          : (json['category_name']?.toString() ?? 'Tanpa Kategori'),
      imageUrl: json['image_url']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      isDeleted: json['is_deleted'] == true || json['is_deleted'] == 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      quantitySold: (json['quantity_sold'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (json['total_profit'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (json['profit_margin'] as num?)?.toDouble() ?? 0.0,
      salesSharePercentage:
          (json['sales_share_percentage'] as num?)?.toDouble() ?? 0.0,
      revenueSharePercentage:
          (json['revenue_share_percentage'] as num?)?.toDouble() ?? 0.0,
      transactionsCount: (json['transactions_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminMenuSalesCategoryModel {
  final int? categoryId;
  final String categoryName;
  final int uniqueProductsCount;
  final int quantitySold;
  final double totalRevenue;
  final double totalProfit;
  final double quantitySharePercentage;
  final double revenueSharePercentage;

  AdminMenuSalesCategoryModel({
    this.categoryId,
    required this.categoryName,
    required this.uniqueProductsCount,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalProfit,
    required this.quantitySharePercentage,
    required this.revenueSharePercentage,
  });

  factory AdminMenuSalesCategoryModel.fromJson(Map<String, dynamic> json) {
    return AdminMenuSalesCategoryModel(
      categoryId: (json['category_id'] as num?)?.toInt(),
      categoryName: json['category_name']?.toString() ?? 'Tanpa Kategori',
      uniqueProductsCount:
          (json['unique_products_count'] as num?)?.toInt() ?? 0,
      quantitySold: (json['quantity_sold'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (json['total_profit'] as num?)?.toDouble() ?? 0.0,
      quantitySharePercentage:
          (json['quantity_share_percentage'] as num?)?.toDouble() ?? 0.0,
      revenueSharePercentage:
          (json['revenue_share_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AdminMenuDailyTrendModel {
  final String date;
  final String dateFormatted;
  final int quantity;
  final double revenue;
  final double profit;

  AdminMenuDailyTrendModel({
    required this.date,
    required this.dateFormatted,
    required this.quantity,
    required this.revenue,
    required this.profit,
  });

  factory AdminMenuDailyTrendModel.fromJson(Map<String, dynamic> json) {
    return AdminMenuDailyTrendModel(
      date: json['date']?.toString() ?? '',
      dateFormatted: json['date_formatted']?.toString() ??
          json['date']?.toString() ??
          '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AdminMenuAddonStatModel {
  final String addonName;
  final int count;
  final double totalRevenue;

  AdminMenuAddonStatModel({
    required this.addonName,
    required this.count,
    required this.totalRevenue,
  });

  factory AdminMenuAddonStatModel.fromJson(Map<String, dynamic> json) {
    return AdminMenuAddonStatModel(
      addonName: json['addon_name']?.toString() ??
          json['name']?.toString() ??
          '-',
      count: (json['count'] as num?)?.toInt() ??
          (json['quantity'] as num?)?.toInt() ??
          0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AdminMenuRecentOrderModel {
  final int transactionId;
  final String invoiceNumber;
  final String customerName;
  final String tableNumber;
  final String orderType;
  final String orderSource;
  final String paymentMethod;
  final int quantity;
  final double price;
  final double subtotal;
  final List<dynamic> addons;
  final String createdAt;
  final String timeFormatted;

  AdminMenuRecentOrderModel({
    required this.transactionId,
    required this.invoiceNumber,
    required this.customerName,
    required this.tableNumber,
    required this.orderType,
    required this.orderSource,
    required this.paymentMethod,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.addons,
    required this.createdAt,
    required this.timeFormatted,
  });

  factory AdminMenuRecentOrderModel.fromJson(Map<String, dynamic> json) {
    return AdminMenuRecentOrderModel(
      transactionId: (json['transaction_id'] as num?)?.toInt() ?? 0,
      invoiceNumber: json['invoice_number']?.toString() ?? '-',
      customerName: json['customer_name']?.toString() ?? 'Pelanggan',
      tableNumber: json['table_number']?.toString() ?? '-',
      orderType: json['order_type']?.toString() ?? 'dine_in',
      orderSource: json['order_source']?.toString() ?? 'pos',
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      addons: json['addons'] is List ? (json['addons'] as List) : [],
      createdAt: json['created_at']?.toString() ?? '',
      timeFormatted: json['time_formatted']?.toString() ?? '-',
    );
  }
}

class AdminMenuSalesDetailModel {
  final int id;
  final String name;
  final String sku;
  final String description;
  final double unitPrice;
  final double costPrice;
  final String categoryName;
  final String? imageUrl;
  final bool isActive;
  final int quantitySold;
  final double totalRevenue;
  final double totalProfit;
  final double profitMargin;
  final int transactionsCount;
  final List<AdminMenuDailyTrendModel> dailyTrend;
  final List<AdminMenuAddonStatModel> popularAddons;
  final List<AdminMenuRecentOrderModel> recentOrders;
  final AdminMenuSalesPeriodModel? period;

  AdminMenuSalesDetailModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.description,
    required this.unitPrice,
    required this.costPrice,
    required this.categoryName,
    this.imageUrl,
    required this.isActive,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalProfit,
    required this.profitMargin,
    required this.transactionsCount,
    required this.dailyTrend,
    required this.popularAddons,
    required this.recentOrders,
    this.period,
  });

  factory AdminMenuSalesDetailModel.fromJson(Map<String, dynamic> json) {
    final prod = json['product'] as Map<String, dynamic>? ?? {};
    final summary = json['sales_summary'] as Map<String, dynamic>? ?? {};
    final cat = prod['category'] as Map<String, dynamic>?;

    final trendList = (json['daily_trend'] as List<dynamic>?)
            ?.map((e) => AdminMenuDailyTrendModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final addonList = (json['popular_addons'] as List<dynamic>?)
            ?.map((e) => AdminMenuAddonStatModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final orderList = (json['recent_orders'] as List<dynamic>?)
            ?.map((e) => AdminMenuRecentOrderModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return AdminMenuSalesDetailModel(
      id: (prod['id'] as num?)?.toInt() ?? 0,
      name: prod['name']?.toString() ?? '-',
      sku: prod['sku']?.toString() ?? '',
      description: prod['description']?.toString() ?? '',
      unitPrice: (prod['unit_price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (prod['cost_price'] as num?)?.toDouble() ?? 0.0,
      categoryName: cat?['name']?.toString() ?? 'Tanpa Kategori',
      imageUrl: prod['image_url']?.toString(),
      isActive: prod['is_active'] == true || prod['is_active'] == 1,
      quantitySold: (summary['quantity_sold'] as num?)?.toInt() ?? 0,
      totalRevenue: (summary['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (summary['total_profit'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (summary['profit_margin'] as num?)?.toDouble() ?? 0.0,
      transactionsCount:
          (summary['transactions_count'] as num?)?.toInt() ?? 0,
      dailyTrend: trendList,
      popularAddons: addonList,
      recentOrders: orderList,
      period: json['period'] != null
          ? AdminMenuSalesPeriodModel.fromJson(json['period'])
          : null,
    );
  }
}
