import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../HelpController.dart';

const _kNavy   = Color(0xFF1A1A2E);
const _kGreen  = Color(0xFF00C853);
const _kBg     = Color(0xFFF5F6FA);
const _kBorder = Color(0xFFEEEFF3);
const _kMuted  = Color(0xFFB0B3C1);

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _showSubmitTicketSheet(
      BuildContext context, HelpController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _kBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Submit Support Query',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _kNavy,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Describe your issue — we\'ll get back to you shortly.',
                  style: TextStyle(fontSize: 13, color: _kMuted),
                ),
                const SizedBox(height: 20),

                // Category
                _FieldLabel(label: 'Category'),
                const SizedBox(height: 6),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.ticketCategory.value,
                        isExpanded: true,
                        icon: const Icon(Icons.expand_more_rounded,
                            color: _kNavy),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kNavy),
                        items: const [
                          DropdownMenuItem(
                              value: 'General Query',
                              child: Text('General Query')),
                          DropdownMenuItem(
                              value: 'Rides & Bookings',
                              child: Text('Rides & Bookings')),
                          DropdownMenuItem(
                              value: 'Payments & Refunds',
                              child: Text('Payments & Refunds')),
                          DropdownMenuItem(
                              value: 'Safety & Emergency',
                              child: Text('Safety & Emergency')),
                        ],
                        onChanged: (val) {
                          if (val != null)
                            controller.ticketCategory.value = val;
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Subject
                _FieldLabel(label: 'Subject'),
                const SizedBox(height: 6),
                _SheetInput(
                  controller: controller.subjectController,
                  hint: 'e.g. Payment deducted twice',
                ),
                const SizedBox(height: 14),

                // Message
                _FieldLabel(label: 'Message'),
                const SizedBox(height: 6),
                _SheetInput(
                  controller: controller.messageController,
                  hint: 'Write your message details...',
                  maxLines: 4,
                ),
                const SizedBox(height: 22),

                // Submit
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isSubmitting.value
                          ? null
                          : () async {
                              final success =
                                  await controller.submitTicket();
                              if (success && context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: controller.isSubmitting.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white),
                            )
                          : const Text(
                              'Submit Ticket',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final HelpController controller = Get.put(HelpController());
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Rapido-style top bar ──────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _CircleBtn(
                    icon: Icons.arrow_back_rounded, onTap: Get.back),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Help & Support',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kNavy,
                      ),
                    ),
                    Text(
                      'We\'re here for you 24/7',
                      style: TextStyle(fontSize: 12, color: _kMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await controller.fetchFaqs();
                await controller.fetchTickets();
              },
              color: _kGreen,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                children: [
                  // ── Contact us ──────────────────────────────────────
                  const _SectionLabel(label: 'Contact Us'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ContactCard(
                          icon: Icons.support_agent_rounded,
                          iconColor: _kNavy,
                          title: 'Call Support',
                          subtitle: '24/7 Available',
                          onTap: () => Get.snackbar(
                            'Calling',
                            'Dialing: +91 1800-123-4567',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ContactCard(
                          icon: Icons.chat_rounded,
                          iconColor: _kGreen,
                          title: 'Submit Ticket',
                          subtitle: 'Create a Query',
                          onTap: () => _showSubmitTicketSheet(
                              context, controller),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── FAQs ─────────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(
                        child: _SectionLabel(label: 'Frequently Asked Questions'),
                      ),
                      _CircleBtn(
                        icon: Icons.refresh_rounded,
                        onTap: controller.fetchFaqs,
                        size: 36,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(color: _kNavy),
                        ),
                      );
                    }

                    if (controller.faqs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _kBorder),
                        ),
                        child: const Center(
                          child: Text('No FAQs available.',
                              style: TextStyle(color: _kMuted)),
                        ),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: List.generate(
                          controller.faqs.length,
                          (index) {
                            final faq = controller.faqs[index];
                            return Column(
                              children: [
                                if (index > 0)
                                  const Divider(
                                      height: 1, color: _kBorder, indent: 16, endIndent: 16),
                                _FaqTile(
                                  question: faq.question,
                                  answer: faq.answer,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 28),

                  // ── Support tickets ───────────────────────────────────
                  Obx(() {
                    if (controller.tickets.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel(label: 'My Support Tickets'),
                        const SizedBox(height: 12),
                        ...controller.tickets.map(
                          (ticket) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _kBorder),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Ticket # pill
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _kNavy.withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(50),
                                      ),
                                      child: Text(
                                        ticket.ticketNo,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _kNavy,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    // Status pill
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4),
                                      decoration: BoxDecoration(
                                        color: ticket.status == 'resolved'
                                            ? _kGreen.withValues(alpha: 0.12)
                                            : const Color(0xFF1565C0)
                                                .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(50),
                                      ),
                                      child: Text(
                                        ticket.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: ticket.status ==
                                                  'resolved'
                                              ? _kGreen
                                              : const Color(0xFF1565C0),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  ticket.subject,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _kNavy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ticket.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13, color: _kMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _CircleBtn(
      {required this.icon, required this.onTap, this.size = 42});

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFFF3F4F6),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
                child: Icon(icon, size: 20, color: _kNavy)),
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _kGreen,
          letterSpacing: 0.7,
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _kNavy,
        ),
      );
}

class _SheetInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _SheetInput(
      {required this.controller,
      required this.hint,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: _kNavy),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _kMuted),
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kGreen, width: 1.5),
          ),
        ),
      );
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ContactCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                ),
                const SizedBox(height: 14),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _kNavy)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 12, color: _kMuted)),
              ],
            ),
          ),
        ),
      );
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
          iconColor: _kGreen,
          collapsedIconColor: _kMuted,
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedAlignment: Alignment.centerLeft,
          children: [
            Text(
              answer,
              style: const TextStyle(
                  fontSize: 13, color: _kMuted, height: 1.5),
            ),
          ],
        ),
      );
}