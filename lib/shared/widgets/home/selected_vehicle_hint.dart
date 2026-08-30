import 'package:flutter/material.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/modules/home/models/VehicleModels.dart';

class SelectedVehicleHint extends StatelessWidget {
  const SelectedVehicleHint({
    super.key,
    required this.option,
    this.subCategory,
    required this.onTap,
  });

  final VehicleOption option;
  final VehicleSubCategory? subCategory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 380;

    final displayName = subCategory != null
        ? '${option.label} (${subCategory!.name})'
        : option.label;

    final displayFare = subCategory != null
        ? (subCategory!.estimatedFare ?? subCategory!.price)
        : option.startingFare;

    final displayTagline = subCategory != null
        ? subCategory!.description
        : option.tagline;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: EdgeInsets.all(compact ? 14 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                option.accentColor.withValues(alpha: 0.08),
                option.accentColor.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: option.accentColor.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 48 : 54,
                height: compact ? 48 : 54,
                decoration: BoxDecoration(
                  color: option.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: option.networkIconUrl != null && option.networkIconUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          option.networkIconUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            option.icon,
                            color: option.accentColor,
                            size: compact ? 24 : 28,
                          ),
                        ),
                      )
                    : Icon(
                        option.icon,
                        color: option.accentColor,
                        size: compact ? 24 : 28,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$displayName selected',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayFare,
                      style: TextStyle(
                        fontSize: 12,
                        color: option.accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        displayTagline,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!compact)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.expand_less_rounded,
                        color: option.accentColor,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Open',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Icon(Icons.expand_less_rounded, color: option.accentColor),
            ],
          ),
        ),
      ),
    );
  }
}
