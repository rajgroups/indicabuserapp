import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'layout/app.dart';
import 'core/config/Config.dart';
import 'core/services/NotificationService.dart';
import 'core/services/SocketService.dart';
import 'core/services/AppConfigService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await dotenv.load(fileName: '.env');
  debugPrint(
    'ENV loaded: mapsKey=${AppEnv.googleMapsApiKey.isNotEmpty}, '
    'placesKey=${AppEnv.googlePlacesApiKey.isNotEmpty}, '
    'mapsKeyLooksReal=${AppEnv.hasGoogleMapsApiKey}, '
    'placesKeyLooksReal=${AppEnv.hasGooglePlacesApiKey}',
  );
  await Get.putAsync(() => AppConfigService().init(), permanent: true);
  Get.put(SocketService(), permanent: true);
  Get.put(NotificationService(), permanent: true);
  runApp(const IndicabApp());
  unawaited(Get.find<NotificationService>().init());
}
