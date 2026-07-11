import 'package:get/get.dart';
import 'package:indicab/modules/auth/AuthController.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Add your controllers or providers here
    Get.lazyPut<AuthController>(() => AuthController());
  }
}
