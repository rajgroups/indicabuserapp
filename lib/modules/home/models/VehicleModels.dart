import 'package:flutter/material.dart';

enum VehicleType { bike, car, jeep, van, bus, tractor }

class VehicleSubCategory {
  const VehicleSubCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.description,
    required this.eta,
    this.seats,
    this.estimatedFare,
    this.basePrice,
    this.perKmPrice,
    this.perHourPrice,
    this.priceType,
  });

  final int id;
  final String name;
  final String slug;
  final String price;
  final String description;
  final String eta;
  final int? seats;
  final String? estimatedFare;
  final double? basePrice;
  final double? perKmPrice;
  final double? perHourPrice;
  final String? priceType;

  double get ratePerKm {
    if (perKmPrice != null && perKmPrice! > 0) {
      return perKmPrice!;
    }
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(price);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '') ?? 0.0;
    }
    return 0.0;
  }

  String getHighlightFare({
    required bool hasDropLocation,
    required double distanceKm,
  }) {
    // 1. If explicit estimated fare string came from API response (and is NOT per-km string):
    if (hasDropLocation &&
        estimatedFare != null &&
        estimatedFare!.trim().isNotEmpty &&
        !estimatedFare!.toLowerCase().contains('/km') &&
        !estimatedFare!.toLowerCase().contains('per')) {
      final fareStr = estimatedFare!.trim();
      final parsed = double.tryParse(fareStr.replaceAll(RegExp(r'[^\d.]'), ''));
      if (parsed != null && parsed > 0) {
        return '₹${parsed.toStringAsFixed(0)}';
      }
      if (fareStr.startsWith('₹') || fareStr.toLowerCase().contains('rs')) {
        return fareStr;
      }
    }

    // 2. When Drop Location is SET & Distance is available (distanceKm > 0):
    if (hasDropLocation && distanceKm > 0) {
      final rate = ratePerKm;
      final base = basePrice ?? 0.0;
      if (rate > 0) {
        final total = base + (distanceKm * rate);
        return '₹${total.toStringAsFixed(0)}';
      }
    }

    // 3. When NO Drop Location (Destination NOT set):
    if (!hasDropLocation) {
      if (perHourPrice != null && perHourPrice! > 0) {
        return '₹${perHourPrice!.toStringAsFixed(0)}/hr';
      }
      if (basePrice != null && basePrice! > 0) {
        return '₹${basePrice!.toStringAsFixed(0)} base';
      }
    }

    final p = price.trim();
    if (p.isNotEmpty) {
      return p;
    }
    return 'Est. TBD';
  }

  String getFareBasisText({
    required bool hasDropLocation,
    required double distanceKm,
  }) {
    final rate = ratePerKm;
    if (hasDropLocation && distanceKm > 0 && rate > 0) {
      return '${distanceKm.toStringAsFixed(1)} km @ ₹${rate.toStringAsFixed(0)}/km';
    }
    if (hasDropLocation && distanceKm > 0) {
      return '${distanceKm.toStringAsFixed(1)} km trip';
    }
    if (rate > 0) {
      return 'Base rate ₹${rate.toStringAsFixed(0)}/km';
    }
    return 'Rate per trip';
  }

  String get displayFare {
    return getHighlightFare(hasDropLocation: false, distanceKm: 0.0);
  }
}


class VehicleOption {
  const VehicleOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.sheetGradient,
    required this.tagline,
    required this.startingFare,
    required this.subCategories,
  });

  final int id;
  final String label;
  final IconData icon;
  final Color accentColor;
  final List<Color> sheetGradient;
  final String tagline;
  final String startingFare;
  final List<VehicleSubCategory> subCategories;
}
