import 'package:get/get.dart';
import 'en.dart';
import 'ta.dart';

class LocalizationService extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': en,
    'ta_IN': ta,
  };
}
