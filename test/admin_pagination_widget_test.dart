import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/common/admin_load_more_footer.dart';


void main() {
  group('AdminLoadMoreFooter Widget Tests', () {
    testWidgets('Displays loading indicator and message when isLoadingMore is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminLoadMoreFooter(
              isLoadingMore: true,
              hasMore: true,
              itemCount: 20,
              itemName: 'transaksi',
            ),
          ),
        ),
      );

      expect(find.text('Memuat transaksi berikutnya...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Semua transaksi telah ditampilkan'), findsNothing);
    });

    testWidgets('Displays end-of-list message when hasMore is false and itemCount >= threshold',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminLoadMoreFooter(
              isLoadingMore: false,
              hasMore: false,
              itemCount: 25,
              threshold: 20,
              itemName: 'transaksi',
            ),
          ),
        ),
      );

      expect(find.text('Semua transaksi telah ditampilkan'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Renders empty spacer when idle and more items exist', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminLoadMoreFooter(
              isLoadingMore: false,
              hasMore: true,
              itemCount: 15,
              threshold: 20,
              itemName: 'produk',
            ),
          ),
        ),
      );

      expect(find.text('Memuat produk berikutnya...'), findsNothing);
      expect(find.text('Semua produk telah ditampilkan'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('Custom itemName is rendered correctly for shifts, products, and cash flow',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AdminLoadMoreFooter(
                  isLoadingMore: true,
                  hasMore: true,
                  itemCount: 20,
                  itemName: 'produk',
                ),
                AdminLoadMoreFooter(
                  isLoadingMore: false,
                  hasMore: false,
                  itemCount: 20,
                  itemName: 'shift',
                ),
                AdminLoadMoreFooter(
                  isLoadingMore: false,
                  hasMore: false,
                  itemCount: 20,
                  itemName: 'arus kas',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Memuat produk berikutnya...'), findsOneWidget);
      expect(find.text('Semua shift telah ditampilkan'), findsOneWidget);
      expect(find.text('Semua arus kas telah ditampilkan'), findsOneWidget);
    });
  });
}
