class VehicleTypeResponse {
  final bool status;
  final String message;
  final List<ApiVehicleType> data;

  VehicleTypeResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory VehicleTypeResponse.fromJson(Map<String, dynamic> json) {
    return VehicleTypeResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => ApiVehicleType.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class ApiVehicleType {
  final int id;
  final String typeKey;
  final String label;
  final String slug;
  final String icon;
  final String accentColor;
  final List<String> sheetGradient;
  final String tagline;
  final String startingFare;
  final String? description;
  final String? iconUrl;
  final String? imageUrl;
  final List<ApiSubCategory> subCategories;

  ApiVehicleType({
    required this.id,
    required this.typeKey,
    required this.label,
    required this.slug,
    required this.icon,
    required this.accentColor,
    required this.sheetGradient,
    required this.tagline,
    required this.startingFare,
    this.description,
    this.iconUrl,
    this.imageUrl,
    required this.subCategories,
  });

  factory ApiVehicleType.fromJson(Map<String, dynamic> json) {
    return ApiVehicleType(
      id: json['id'] ?? 0,
      typeKey: json['type_key'] ?? '',
      label: json['label'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'] ?? '',
      accentColor: json['accent_color'] ?? '',
      sheetGradient:
          List<String>.from(json['sheet_gradient'] ?? []),
      tagline: json['tagline'] ?? '',
      startingFare: json['starting_fare'] ?? '',
      description: json['description'],
      iconUrl: json['icon_url']?.toString(),
      imageUrl: json['image_url']?.toString(),
      subCategories: (json['sub_categories'] as List<dynamic>?)
              ?.map((e) => ApiSubCategory.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type_key': typeKey,
      'label': label,
      'slug': slug,
      'icon': icon,
      'accent_color': accentColor,
      'sheet_gradient': sheetGradient,
      'tagline': tagline,
      'starting_fare': startingFare,
      'description': description,
      'sub_categories':
          subCategories.map((e) => e.toJson()).toList(),
    };
  }
}

class ApiSubCategory {
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

  ApiSubCategory({
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

  factory ApiSubCategory.fromJson(Map<String, dynamic> json) {
    final pricings = json['vehicle_category_pricings'] ??
        json['pricings'] ??
        json['pricing'];

    Map<String, dynamic>? pricingMap;
    if (pricings is Map<String, dynamic>) {
      pricingMap = pricings;
    } else if (pricings is List &&
        pricings.isNotEmpty &&
        pricings.first is Map<String, dynamic>) {
      pricingMap = pricings.first as Map<String, dynamic>;
    }

    final rawFare = json['estimated_fare'] ??
        json['estimated_amount'] ??
        json['calculated_fare'] ??
        json['total_fare'] ??
        json['fare_amount'] ??
        json['fare'] ??
        pricingMap?['estimated_fare'] ??
        pricingMap?['calculated_fare'] ??
        pricingMap?['total_fare'] ??
        '';

    final fareStr = rawFare.toString();

    double? parseNum(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString().replaceAll(RegExp(r'[^\d.]'), ''));
    }

    final baseP = parseNum(
      json['base_price'] ??
          json['base_fare'] ??
          json['min_price'] ??
          pricingMap?['base_price'] ??
          pricingMap?['base_fare'],
    );
    final perKmP = parseNum(
      json['per_km_price'] ??
          json['per_km_rate'] ??
          json['price_per_km'] ??
          json['per_km'] ??
          pricingMap?['per_km_price'] ??
          pricingMap?['per_km_rate'] ??
          pricingMap?['price_per_km'] ??
          pricingMap?['per_km'],
    );
    final perHourP = parseNum(
      json['per_hour_price'] ??
          json['per_hour_rate'] ??
          json['hourly_price'] ??
          json['price_per_hour'] ??
          json['hourly_charge'] ??
          json['per_hour'] ??
          pricingMap?['per_hour_price'] ??
          pricingMap?['per_hour_rate'] ??
          pricingMap?['hourly_price'] ??
          pricingMap?['hourly_charge'],
    );
    final pType = (json['price_type'] ??
            json['pricing_type'] ??
            json['charge_type'] ??
            pricingMap?['price_type'] ??
            pricingMap?['pricing_type'])
        ?.toString();

    return ApiSubCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      price: json['price']?.toString() ?? fareStr,
      description: json['description'] ?? '',
      eta: json['eta'] ?? '',
      seats: json['seats'],
      estimatedFare: fareStr.isNotEmpty ? fareStr : null,
      basePrice: baseP,
      perKmPrice: perKmP,
      perHourPrice: perHourP,
      priceType: pType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'price': price,
      'description': description,
      'eta': eta,
      'seats': seats,
      'estimated_fare': estimatedFare,
      'base_price': basePrice,
      'per_km_price': perKmPrice,
      'per_hour_price': perHourPrice,
      'price_type': priceType,
    };
  }
}

