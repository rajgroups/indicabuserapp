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
  });

  final int id;
  final String name;
  final String slug;
  final String price;
  final String description;
  final String eta;
  final int? seats;
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
