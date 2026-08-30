import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/network/endpoints.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/core/services/SocketService.dart';

@pragma('vm:entry-point')
Future<void> userFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("User FCM Background Message ID: ${message.messageId} Data: ${message.data}");
}

class NotificationService extends GetxService {
  final RxString fcmToken = ''.obs;

  Future<NotificationService> init() async {
    try {
      await Firebase.initializeApp();
      debugPrint("Firebase Core initialized successfully in User App");

      FirebaseMessaging.onBackgroundMessage(userFirebaseMessagingBackgroundHandler);

      await _requestPermission();
      await fetchFcmToken();

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        fcmToken.value = newToken;
        sendTokenToBackend(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("User FCM Foreground Message: ${message.notification?.title} - ${message.data}");
        _handleIncomingNotification(message, isClicked: false);
      });

      // Handle notification taps from background state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("User FCM Notification Tapped: ${message.data}");
        _handleIncomingNotification(message, isClicked: true);
      });

      // Check if app was launched from a terminated state notification tap
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint("User FCM Terminated App Launch Message: ${initialMessage.data}");
        _handleIncomingNotification(initialMessage, isClicked: true);
      }
    } catch (e) {
      debugPrint("Error initializing User NotificationService: $e");
    }
    return this;
  }

  Future<void> _requestPermission() async {
    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('User granted notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint("Error requesting notification permission: $e");
    }
  }

  Future<String?> fetchFcmToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        fcmToken.value = token;
        debugPrint("User FCM Token retrieved: $token");
        await sendTokenToBackend(token);
      }
      return token;
    } catch (e) {
      debugPrint("Error fetching User FCM token: $e");
      return null;
    }
  }

  Future<void> sendTokenToBackend(String token) async {
    if (token.isEmpty) return;
    try {
      final response = await ApiClient().post(
        ApiEndpoints.updateFcmToken,
        data: {'fcm_token': token},
      );
      debugPrint("User FCM token updated on backend: ${response.data}");
    } catch (e) {
      debugPrint("Failed to send User FCM token to backend: $e");
    }
  }

  void _handleIncomingNotification(RemoteMessage message, {required bool isClicked}) {
    final title = message.notification?.title ?? message.data['title'] ?? 'Ride Update';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    final data = message.data;
    final type = data['type']?.toString();
    final action = data['action']?.toString();
    final bookingNo = data['booking_no']?.toString();

    if (!isClicked) {
      Get.snackbar(
        title,
        body,
        duration: const Duration(seconds: 6),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        onTap: (_) {
          _openFindingDriverScreen(bookingNo);
        },
      );
    }

    if (type == 'scheduled_ride_ready' || action == 'open_finding_driver' || isClicked) {
      _openFindingDriverScreen(bookingNo);
    }
  }

  void _openFindingDriverScreen(String? bookingNo) {
    if (Get.isRegistered<SocketService>()) {
      Get.find<SocketService>().ensureConnected();
    }

    if (bookingNo != null && bookingNo.isNotEmpty) {
      if (Get.currentRoute != RouteNames.findingDriver) {
        Get.offAllNamed(
          RouteNames.findingDriver,
          arguments: {'booking_no': bookingNo},
        );
      }
    }
  }
}
