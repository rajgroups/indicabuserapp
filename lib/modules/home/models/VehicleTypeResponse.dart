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

  ApiSubCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.description,
    required this.eta,
    this.seats,
  });

  factory ApiSubCategory.fromJson(Map<String, dynamic> json) {
    return ApiSubCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      price: json['price'] ?? '',
      description: json['description'] ?? '',
      eta: json['eta'] ?? '',
      seats: json['seats'],
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
    };
  }
}
