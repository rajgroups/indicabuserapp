import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ReferralController.dart';

class ReferralView extends StatelessWidget {
  const ReferralView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReferralController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Refer & Earn', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.redeem_rounded, color: Color(0xFF00C853), size: 48),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Invite Friends, Earn Rewards!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share your code with friends and both earn rewards on their first completed ride.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.referralCode.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: controller.copyCode,
                            child: const Icon(Icons.copy_rounded, color: Color(0xFF00C853), size: 24),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: controller.shareCode,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    )
                  ],
                ),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Earned',
                        value: '₹${controller.totalEarned.value.toStringAsFixed(0)}',
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF00C853),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Successful',
                        value: '${controller.successfulReferrals.value}',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF6C63FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  'Recent Referrals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: controller.history.isEmpty
                  ? SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Text(
                          'No referrals yet.\nStart inviting your friends!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = controller.history[index];
                          final status = item['status'] ?? 'PENDING';
                          final referred = item['referred'] ?? {};
                          final name = referred['name'] ?? referred['mobile'] ?? 'Unknown User';
                          
                          Color statusColor = Colors.orange;
                          if (status == 'REWARDED' || status == 'QUALIFIED') statusColor = const Color(0xFF00C853);
                          if (status == 'CANCELLED') statusColor = Colors.red;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: statusColor.withValues(alpha: 0.1),
                                child: Icon(Icons.person_outline_rounded, color: statusColor),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text('Status: $status'),
                              trailing: (status == 'REWARDED')
                                  ? Text(
                                      '+₹${item['reward_amount']}',
                                      style: const TextStyle(
                                        color: Color(0xFF00C853),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                        childCount: controller.history.length,
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
