import 'package:flutter_test/flutter_test.dart';
import 'package:noli_apps/app/data/models/admin_dashboard_model.dart';
import 'package:noli_apps/app/data/models/admin_shift_model.dart';
import 'package:noli_apps/app/data/models/admin_transaction_model.dart';
import 'package:noli_apps/app/data/models/admin_open_bill_model.dart';

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
  });
}
