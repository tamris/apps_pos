import 'package:flutter_test/flutter_test.dart';
import 'package:noli_apps/app/data/models/admin_dashboard_model.dart';
import 'package:noli_apps/app/data/models/admin_shift_model.dart';
import 'package:noli_apps/app/data/models/admin_transaction_model.dart';
import 'package:noli_apps/app/data/models/admin_open_bill_model.dart';
import 'package:noli_apps/app/data/models/admin_ingredient_model.dart';

void main() {
  group('Admin Models Parsing & Business Logic', () {
    test('AdminDashboardModel parses API response correctly', () {
      final json = {
        'date': '2026-09-05',
        'summary': {
          'total_revenue': 1500000,
          'total_transactions': 25,
          'average_per_transaction': 60000,
        },
        'payment_breakdown': {
          'cash': {'count': 10, 'total': 500000},
          'qris': {'count': 10, 'total': 700000},
          'transfer': {'count': 5, 'total': 300000},
        },
        'order_source_breakdown': {
          'pos': {'count': 20, 'total': 1200000, 'label': 'Kasir POS'},
          'self_order': {'count': 5, 'total': 300000, 'label': 'Self-Order (Online)'},
        },
        'order_type_breakdown': {
          'dine_in': {'count': 18, 'total': 1000000, 'label': 'Dine In'},
          'takeaway': {'count': 7, 'total': 500000, 'label': 'Take Away'},
        },
        'active_shift': {
          'shift_id': 12,
          'cashier_id': 3,
          'cashier_name': 'Kasir Budi',
          'starting_cash': 200000,
          'cash_sales': 500000,
          'expected_cash': 700000,
        },
        'open_bills_summary': {
          'count': 3,
          'potential_revenue': 250000,
        },
        'cancellations_summary': {
          'count': 1,
          'total_nominal': 50000,
        },
      };

      final model = AdminDashboardModel.fromJson(json);

      expect(model.date, '2026-09-05');
      expect(model.summary.totalRevenue, 1500000);
      expect(model.summary.totalTransactions, 25);
      expect(model.paymentBreakdown.cash.total, 500000);
      expect(model.paymentBreakdown.qris.total, 700000);
      expect(model.activeShift?.cashierName, 'Kasir Budi');
      expect(model.activeShift?.expectedCash, 700000);
      expect(model.openBillsSummary.count, 3);
      expect(model.cancellationsSummary.count, 1);
    });

    test('AdminShiftModel computes discrepancy correctly', () {
      final jsonShortage = {
        'id': 1,
        'user_id': 3,
        'cashier_name': 'Kasir Budi',
        'start_time': '2026-09-05 08:00:00',
        'end_time': '2026-09-05 16:00:00',
        'starting_cash': 200000,
        'actual_cash': 650000,
        'expected_cash': 700000,
        'difference': -50000,
        'discrepancy_status': 'shortage',
        'status': 'closed',
        'total_sales': 800000,
      };

      final shift = AdminShiftModel.fromJson(jsonShortage);
      expect(shift.isShortage, true);
      expect(shift.isOverage, false);
      expect(shift.isBalanced, false);
      expect(shift.isOpen, false);
      expect(shift.difference, -50000);
    });

    test('AdminTransactionModel handles cancellation and self-order', () {
      final json = {
        'id': 101,
        'invoice_number': 'INV-20260905-001',
        'customer_name': 'Pak Joko',
        'table_number': '5',
        'cashier_name': 'Kasir Budi',
        'order_source': 'self_order',
        'order_type': 'dine_in',
        'payment_method': 'qris',
        'status': 'cancelled',
        'total': 75000,
        'cancelled_info': {
          'cancelled_by_name': 'Owner Anton',
          'cancelled_at': '2026-09-05 12:30:00',
          'cancelled_reason': 'Pesanan dobel',
        },
      };

      final trx = AdminTransactionModel.fromJson(json);
      expect(trx.isCancelled, true);
      expect(trx.isSelfOrder, true);
      expect(trx.cancelledInfo?.cancelledByName, 'Owner Anton');
      expect(trx.cancelledInfo?.cancelledReason, 'Pesanan dobel');
    });

    test('AdminTransactionModel defaults cancelledByName to Sistem when null (e.g. QRIS Expired)', () {
      final json = {
        'id': 102,
        'invoice_number': 'INV-20260905-002',
        'customer_name': 'Pelanggan Online',
        'order_source': 'self_order',
        'order_type': 'dine_in',
        'payment_method': 'qris',
        'payment_status': 'failed',
        'status': 'cancelled',
        'total': 50000,
        'paid': 0,
        'cancelled_info': {
          'cancelled_at': '2026-09-05 12:30:00',
          'cancelled_reason': 'Batas waktu pembayaran QRIS telah kadaluarsa.',
        },
      };

      final trx = AdminTransactionModel.fromJson(json);
      expect(trx.isCancelled, true);
      expect(trx.isSelfOrder, true);
      expect(trx.paymentStatus, 'failed');
      expect(trx.cancelledInfo?.cancelledByName, 'Sistem');
      expect(trx.cancelledInfo?.cancelledReason, contains('kadaluarsa'));
    });

    test('AdminOpenBillModel computes elapsed minutes and items', () {
      final json = {
        'id': 12,
        'invoice_number': 'INV-OPEN-01',
        'customer_name': 'Siti',
        'table_number': '4',
        'cashier_name': 'Kasir Budi',
        'order_source': 'pos',
        'order_type': 'dine_in',
        'total': 120000,
        'elapsed_minutes': 45,
        'items_count': 3,
      };

      final bill = AdminOpenBillModel.fromJson(json);
      expect(bill.tableNumber, '4');
      expect(bill.elapsedMinutes, 45);
      expect(bill.itemsCount, 3);
      expect(bill.total, 120000);
    });

    test('AdminIngredientModel correctly evaluates Aktif, Nonaktif (Jeda), and Arsip lifecycle states', () {
      // 1. Active Ingredient
      final activeJson = {
        'id': 1,
        'name': 'Biji Kopi Arabika',
        'category': 'Kopi',
        'stock': 2500,
        'unit': 'gram',
        'min_stock': 500,
        'cost_per_unit': 200,
        'buy_price': 200000,
        'buy_amount': 1000,
        'buy_unit': 'gram',
        'is_active': true,
        'is_archived': false,
        'deleted_at': null,
      };
      final activeIng = AdminIngredientModel.fromJson(activeJson);
      expect(activeIng.isActive, true);
      expect(activeIng.isArchived, false);
      expect(activeIng.isInactive, false);
      expect(activeIng.isAvailable, true);

      // 2. Inactive Ingredient (Paused / Musiman / Supplier Kosong)
      final inactiveJson = {
        'id': 2,
        'name': 'Sirup Pandan Musiman',
        'category': 'Sirup',
        'stock': 500,
        'unit': 'ml',
        'min_stock': 200,
        'cost_per_unit': 80,
        'buy_price': 80000,
        'buy_amount': 1000,
        'buy_unit': 'ml',
        'is_active': false,
        'is_archived': false,
        'deleted_at': null,
      };
      final inactiveIng = AdminIngredientModel.fromJson(inactiveJson);
      expect(inactiveIng.isActive, false);
      expect(inactiveIng.isArchived, false);
      expect(inactiveIng.isInactive, true);
      expect(inactiveIng.isAvailable, false);

      // 3. Archived Ingredient (Soft-deleted)
      final archivedJson = {
        'id': 3,
        'name': 'Boba Brown Sugar Pensiun',
        'category': 'Topping',
        'stock': 0,
        'unit': 'gram',
        'min_stock': 100,
        'cost_per_unit': 50,
        'buy_price': 50000,
        'buy_amount': 1000,
        'buy_unit': 'gram',
        'is_active': false,
        'is_archived': true,
        'deleted_at': '2026-09-20T08:00:00Z',
      };
      final archivedIng = AdminIngredientModel.fromJson(archivedJson);
      expect(archivedIng.isActive, false);
      expect(archivedIng.isArchived, true);
      expect(archivedIng.isInactive, false);
      expect(archivedIng.isAvailable, false);
    });

    test('AdminIngredientSummaryModel parses server aggregate summary correctly', () {
      final json = {
        'total_ingredients': 350,
        'low_stock_count': 25,
        'out_of_stock_count': 10,
        'debt_count': 3,
        'safe_stock_count': 315,
        'total_inventory_value': 12500000.50,
      };

      final summary = AdminIngredientSummaryModel.fromJson(json);
      expect(summary.totalIngredients, 350);
      expect(summary.lowStockCount, 25);
      expect(summary.outOfStockCount, 10);
      expect(summary.debtCount, 3);
      expect(summary.safeStockCount, 315);
      expect(summary.totalInventoryValue, 12500000.50);

      // Fallback when safe_stock_count is omitted
      final jsonNoSafe = {
        'total_ingredients': 100,
        'low_stock_count': 10,
        'out_of_stock_count': 5,
        'debt_count': 0,
        'total_inventory_value': 500000.0,
      };
      final summaryFallback = AdminIngredientSummaryModel.fromJson(jsonNoSafe);
      expect(summaryFallback.safeStockCount, 85);
    });
  });
}
