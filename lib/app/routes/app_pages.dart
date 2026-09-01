import 'package:get/get.dart';
import 'app_routes.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/pin_login_view.dart';
import '../modules/pos/bindings/pos_binding.dart';
import '../modules/pos/views/pos_view.dart';
import '../modules/open_bills/bindings/open_bills_binding.dart';
import '../modules/open_bills/views/open_bills_view.dart';
import '../modules/transactions/bindings/transactions_binding.dart';
import '../modules/transactions/views/transactions_view.dart';
import '../modules/online_orders/bindings/online_orders_binding.dart';
import '../modules/online_orders/views/online_orders_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';

class AppPages {
  static const initial = AppRoutes.pinLogin;

  static final routes = [
    GetPage(
      name: AppRoutes.pinLogin,
      page: () => const PinLoginView(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.pos,
      page: () => const PosView(),
      binding: PosBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.openBills,
      page: () => const OpenBillsView(),
      binding: OpenBillsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.transactions,
      page: () => const TransactionsView(),
      binding: TransactionsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.onlineOrders,
      page: () => const OnlineOrdersView(),
      binding: OnlineOrdersBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}
