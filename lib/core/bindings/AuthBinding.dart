import 'package:get/get.dart';
import 'package:indicab/modules/auth/AuthController.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // fenix: true allows GetX to recreate AuthController on demand when navigating back
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
