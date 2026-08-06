import 'package:get/get.dart';
import 'package:indicab/modules/home/HomeController.dart';
import 'package:indicab/core/controller/BookingController.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeController>()) {
      Get.put<HomeController>(HomeController(), permanent: true);
    }
    if (!Get.isRegistered<BookingController>()) {
      Get.put<BookingController>(BookingController());
    }
  }
}
