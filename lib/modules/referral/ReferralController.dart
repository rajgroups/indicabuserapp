import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:indicab/core/utils/Helpers.dart';
import 'ReferralService.dart';

class ReferralController extends GetxController {
  final ReferralService _service = ReferralService();

  var isLoading = true.obs;

  var totalInvites = 0.obs;
  var pendingReferrals = 0.obs;
  var successfulReferrals = 0.obs;
  var totalEarned = 0.0.obs;

  var referralCode = ''.obs;
  var referralLink = ''.obs;
  var shareMessage = ''.obs;

  var history = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;

    // Run concurrently for faster load
    final results = await Future.wait([
      _service.getSummary(),
      _service.getReferralCode(),
      _service.getHistory(),
    ]);

    final summary = results[0] as Map<String, dynamic>;
    final codeData = results[1] as Map<String, dynamic>;
    final histData = results[2] as List<dynamic>;

    totalInvites.value = summary['total_invites'] ?? 0;
    pendingReferrals.value = summary['pending_referrals'] ?? 0;
    successfulReferrals.value = summary['successful_referrals'] ?? 0;
    totalEarned.value = (summary['total_earned'] ?? 0).toDouble();

    referralCode.value = codeData['referral_code'] ?? '';
    referralLink.value = codeData['referral_link'] ?? '';
    shareMessage.value = codeData['share_message'] ?? '';

    history.assignAll(histData);

    isLoading.value = false;
  }

  void copyCode() {
    Clipboard.setData(ClipboardData(text: referralCode.value));
    Helpers.showToast('Referral code copied to clipboard!');
  }

  void shareCode() {
    // Usually share_plus is used here. For simplicity, we just copy to clipboard
    // If share_plus is added to pubspec, we would do: Share.share(shareMessage.value);
    Clipboard.setData(ClipboardData(text: shareMessage.value));
    Helpers.showToast('Share message copied! Paste it anywhere to share.');
  }
}
