import 'package:get/get.dart';
import 'package:indicab/core/controller/BookingController.dart';

class BookingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingController>(() => BookingController());
  }
}
