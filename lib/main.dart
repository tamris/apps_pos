import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/services/storage_service.dart';
import 'app/data/providers/api_provider.dart';
import 'app/data/services/offline_sync_service.dart';
import 'app/data/services/esc_pos_printer_service.dart';
import 'app/data/services/online_order_polling_service.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale formatting Bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  // Set preferensi orientasi sistem
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Inisialisasi Service Global
  final storageService = await Get.putAsync<StorageService>(() => StorageService().init());
  Get.put<ApiProvider>(ApiProvider());
  Get.put<OfflineSyncService>(OfflineSyncService());
  Get.put<EscPosPrinterService>(EscPosPrinterService());
  Get.put<OnlineOrderPollingService>(OnlineOrderPollingService());

  // Tentukan rute awal (jika token tersimpan maka langsung ke POS)
  final String initialRoute = storageService.hasToken ? AppRoutes.pos : AppRoutes.pinLogin;

  runApp(MainApp(initialRoute: initialRoute));
}

class MainApp extends StatelessWidget {
  final String initialRoute;

  const MainApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Noli POS Kasir',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      defaultTransition: Transition.fade,
    );
  }
}
