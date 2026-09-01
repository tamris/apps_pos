import 'package:get/get.dart';
import '../controllers/open_bills_controller.dart';

class OpenBillsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OpenBillsController>(() => OpenBillsController());
  }
}
