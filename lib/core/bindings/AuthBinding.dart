import 'package:get/get.dart';
import 'package:indicab/modules/auth/AuthController.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}
