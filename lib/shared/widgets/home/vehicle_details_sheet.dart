import 'package:flutter/material.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/modules/home/models/VehicleModels.dart';

class VehicleDetailsSheet extends StatelessWidget {
  const VehicleDetailsSheet({
    super.key,
    required this.option,
    required this.scrollController,
    required this.onSelect,
    this.onMapTap, // 2. Add to constructor
  });

  final VehicleOption option;
  final ScrollController scrollController;
  final ValueChanged<VehicleSubCategory> onSelect;
  final Function(VehicleSubCategory)? onMapTap; // 1. Add this variable

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 54,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SheetHeader(option: option),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          SheetStatChip(
                            icon: Icons.bolt_rounded,
                            label: 'Priority dispatch',
                            color: option.accentColor,
                          ),
                          const SizedBox(width: 10),
                          SheetStatChip(
                            icon: Icons.workspace_premium_rounded,
                            label: 'Verified fleet',
                            color: option.accentColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Vehicle Types',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...option.subCategories.map(
                        (subCategory) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SubCategoryCard(
                            accentColor: option.accentColor,
                            subCategory: subCategory,
                            icon: option.icon,
                            onTap: () => onSelect(subCategory),
                            onMapTap: onMapTap != null
                                ? () => onMapTap!(subCategory)
                                : null,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.option});

  final VehicleOption option;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 380;

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: option.sheetGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 56 : 64,
            height: compact ? 56 : 64,
            decoration: BoxDecoration(
              color: option.accentColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              option.icon,
              color: AppColors.white,
              size: compact ? 28 : 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${option.label} options',
                  style: TextStyle(
                    fontSize: compact ? 20 : 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose the right subtype for fare, space and arrival time.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SubCategoryCard extends StatelessWidget {
  const SubCategoryCard({
    super.key,
    required this.subCategory,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.onMapTap,
  });

  final VehicleSubCategory subCategory;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback? onMapTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 380;

    return Material(
      color: const Color(0xFFFCFCFD),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.all(compact ? 14 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compact ? 46 : 52,
                    height: compact ? 46 : 52,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subCategory.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subCategory.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        subCategory.price,
                        style: TextStyle(
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subCategory.eta,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (subCategory.seats != null)
                    InfoPill(
                      icon: Icons.event_seat_rounded,
                      label: '${subCategory.seats} seats',
                    ),
                  const InfoPill(
                    icon: Icons.payments_outlined,
                    label: 'Transparent fare',
                  ),
                  if (onMapTap != null)
                    InkWell(
                      onTap: onMapTap,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map_rounded,
                              size: 16,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Map',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor,
                            Color.lerp(accentColor, Colors.black, 0.2)!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 16,
                            color: AppColors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Book Now',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SheetStatChip extends StatelessWidget {
  const SheetStatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
