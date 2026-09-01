import 'package:get/get.dart';
import '../controllers/online_orders_controller.dart';

class OnlineOrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnlineOrdersController>(
      () => OnlineOrdersController(),
    );
  }
}
