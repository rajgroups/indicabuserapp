import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/models/FaqModel.dart';
import 'package:indicab/core/models/SupportTicketModel.dart';
import 'HelpService.dart';

class HelpController extends GetxController {
  HelpController();

  final HelpService _helpService = HelpService();

  final RxList<FaqModel> faqs = <FaqModel>[].obs;
  final RxList<SupportTicketModel> tickets = <SupportTicketModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString selectedCategory = 'All'.obs;

  // Form Controllers for ticket creation
  late TextEditingController subjectController;
  late TextEditingController messageController;
  final RxString ticketCategory = 'General Query'.obs;
  int? bookingIdForTicket;

  @override
  void onInit() {
    super.onInit();
    subjectController = TextEditingController();
    messageController = TextEditingController();

    fetchFaqs();
    fetchTickets();
  }

  @override
  void onClose() {
    subjectController.dispose();
    messageController.dispose();
    super.onClose();
  }

  Future<void> fetchFaqs() async {
    isLoading.value = true;
    try {
      final faqList = await _helpService.fetchFaqs(
        category: selectedCategory.value,
      );
      faqs.assignAll(faqList);
    } catch (e) {
      debugPrint('HelpController.fetchFaqs error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTickets() async {
    try {
      final ticketList = await _helpService.fetchSupportTickets();
      tickets.assignAll(ticketList);
    } catch (e) {
      debugPrint('HelpController.fetchTickets error: $e');
    }
  }

  Future<bool> submitTicket({int? bookingId}) async {
    final subject = subjectController.text.trim();
    final message = messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      Get.snackbar(
        'Required',
        'Please fill in both subject and message.',
        backgroundColor: AppColors.surface,
        colorText: Colors.red,
      );
      return false;
    }

    isSubmitting.value = true;

    try {
      final payload = {
        'subject': subject,
        'message': message,
        'category': ticketCategory.value,
        if (bookingId != null || bookingIdForTicket != null)
          'booking_id': bookingId ?? bookingIdForTicket,
      };

      final ticket = await _helpService.submitSupportTicket(payload);
      tickets.insert(0, ticket);

      subjectController.clear();
      messageController.clear();
      bookingIdForTicket = null;

      Get.snackbar(
        'Submitted',
        'Ticket #${ticket.ticketNo} submitted successfully.',
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
      );

      return true;
    } catch (e) {
      debugPrint('HelpController.submitTicket error: $e');
      Get.snackbar(
        'Error',
        'Failed to submit support ticket: $e',
        backgroundColor: AppColors.surface,
        colorText: Colors.red,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
