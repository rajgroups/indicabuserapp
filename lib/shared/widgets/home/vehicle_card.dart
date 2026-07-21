import 'package:flutter/material.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/modules/home/models/VehicleModels.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
    this.onMapTap,
  });

  final VehicleOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onMapTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 380;
    final cardWidth = compact ? 132.0 : 144.0;
    final iconSize = compact ? 56.0 : 66.0;
    final cardGradient = isSelected
        ? [
            option.accentColor,
            Color.lerp(option.accentColor, Colors.black, 0.18)!,
          ]
        : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFC)];
    final textColor = isSelected ? AppColors.white : AppColors.textPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: cardWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isSelected
              ? option.accentColor
              : option.accentColor.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? option.accentColor.withValues(alpha: 0.3)
                : const Color(0x12000000),
            blurRadius: isSelected ? 24 : 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.white.withValues(alpha: 0.18)
                              : option.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isSelected ? 'Book Now' : 'Available',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? AppColors.white
                                : option.accentColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.arrow_outward_rounded,
                      size: compact ? 16 : 18,
                      color: textColor.withValues(alpha: 0.9),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 8 : 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [
                              AppColors.white.withValues(alpha: 0.26),
                              AppColors.white.withValues(alpha: 0.12),
                            ]
                          : [
                              option.accentColor.withValues(alpha: 0.16),
                              option.accentColor.withValues(alpha: 0.06),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.white.withValues(alpha: 0.3)
                          : option.accentColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    option.icon,
                    size: compact ? 28 : 32,
                    color: isSelected ? AppColors.white : option.accentColor,
                  ),
                ),
                SizedBox(height: compact ? 10 : 12),
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 15 : 17,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  option.tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    height: 1.2,
                    color: textColor.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  option.startingFare,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.white.withValues(alpha: 0.92)
                        : option.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
