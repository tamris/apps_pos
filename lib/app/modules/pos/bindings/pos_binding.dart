import 'package:get/get.dart';
import '../controllers/pos_controller.dart';
import '../controllers/cart_controller.dart';
import '../../shift/controllers/shift_controller.dart';

class PosBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PosController>(() => PosController());
    Get.lazyPut<CartController>(() => CartController());
    Get.lazyPut<ShiftController>(() => ShiftController());
  }
}
