class BookingResponseModel {
  BookingResponseModel({
    required this.status,
    required this.message,
    required this.data,
  });

  final bool status;
  final String message;
  final BookingDataModel? data;

  factory BookingResponseModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    final data = json['data'];

    return BookingResponseModel(
      status: rawStatus is bool
          ? rawStatus
          : (rawStatus.toString() == 'true' ||
                rawStatus.toString() == 'success'),
      message: json['message']?.toString() ?? '',
      data: data is Map<String, dynamic>
          ? BookingDataModel.fromJson(data)
          : null,
    );
  }
}

class FareBreakdown {
  final double baseFare;
  final double distanceCharge;
  final double timeCharge;
  final double waitingCharge;
  final double extraCharge;
  final double discount;
  final double subtotal;
  final double taxPercentage;
  final double taxAmount;
  final double userTotal;
  final String commissionType;
  final double commissionValue;
  final double commissionAmount;
  final double driverEarnings;

  const FareBreakdown({
    this.baseFare = 0.0,
    this.distanceCharge = 0.0,
    this.timeCharge = 0.0,
    this.waitingCharge = 0.0,
    this.extraCharge = 0.0,
    this.discount = 0.0,
    this.subtotal = 0.0,
    this.taxPercentage = 0.0,
    this.taxAmount = 0.0,
    this.userTotal = 0.0,
    this.commissionType = 'percentage',
    this.commissionValue = 0.0,
    this.commissionAmount = 0.0,
    this.driverEarnings = 0.0,
  });

  factory FareBreakdown.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) =>
        val != null ? double.tryParse(val.toString()) ?? 0.0 : 0.0;

    return FareBreakdown(
      baseFare:          parse(json['base_fare']),
      distanceCharge:    parse(json['distance_charge']),
      timeCharge:        parse(json['time_charge']),
      waitingCharge:     parse(json['waiting_charge']),
      extraCharge:       parse(json['extra_charge']),
      discount:          parse(json['discount']),
      subtotal:          parse(json['subtotal']),
      taxPercentage:     parse(json['tax_percentage']),
      taxAmount:         parse(json['tax_amount']),
      userTotal:         parse(json['user_total'] ?? json['total_amount']),
      commissionType:    json['commission_type']?.toString() ?? 'percentage',
      commissionValue:   parse(json['commission_value']),
      commissionAmount:  parse(json['commission_amount']),
      driverEarnings:    parse(json['driver_earnings']),
    );
  }
}

class BookingDataModel {
  BookingDataModel({
    required this.id,
    required this.bookingNo,
    required this.status,
    required this.bookingMode,
    required this.vehicleCategoryId,
    this.driverId,
    this.vehicleId,
    this.scheduledAt,
    this.pickupAddress,
    this.dropAddress,
    this.startOtp,
    this.endOtp,
    this.estimatedAmount,
    this.finalAmount,
    this.driverName,
    this.driverPhone,
    this.vehicleNumber,
    this.vehicleName,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropLatitude,
    this.dropLongitude,
    this.categoryName,
    this.categoryIcon,
    this.categoryImage,
    this.driverLatitude,
    this.driverLongitude,
    required this.requiresDropLocation,
    this.fareBreakdown,
  });

  final int? id;
  final String? bookingNo;
  final String? status;
  final String? bookingMode;
  final int? driverId;
  final int? vehicleId;
  final int? vehicleCategoryId;
  final String? scheduledAt;
  final String? pickupAddress;
  final String? dropAddress;
  final String? startOtp;
  final String? endOtp;
  final double? estimatedAmount;
  final double? finalAmount;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleNumber;
  final String? vehicleName;
  final String? pickupLatitude;
  final String? pickupLongitude;
  final String? dropLatitude;
  final String? dropLongitude;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryImage;
  final String? driverLatitude;
  final String? driverLongitude;
  final bool requiresDropLocation;
  final FareBreakdown? fareBreakdown;

  String? get effectiveCategoryIconUrl {
    final icon = categoryIcon?.trim();
    if (icon != null && icon.isNotEmpty) {
      return icon;
    }
    final img = categoryImage?.trim();
    if (img != null && img.isNotEmpty) {
      return img;
    }
    return null;
  }

  factory BookingDataModel.fromJson(Map<String, dynamic> json) {
    final requiresDrop = json['requires_drop_location'] is bool
        ? json['requires_drop_location'] as bool
        : (json['requires_drop_location']?.toString() == 'true' ||
              json['drop_location'] != null);

    String? categoryIcon;
    String? categoryImage;

    if (json['category'] is Map<String, dynamic>) {
      final cat = json['category'] as Map<String, dynamic>;
      categoryIcon =
          cat['icon_url']?.toString() ??
          cat['icon']?.toString() ??
          cat['category_icon']?.toString();
      categoryImage =
          cat['image_url']?.toString() ??
          cat['image']?.toString() ??
          cat['category_image']?.toString();
    }

    categoryIcon ??=
        json['category_icon']?.toString() ??
        json['icon_url']?.toString() ??
        json['icon']?.toString();
    categoryImage ??=
        json['category_image']?.toString() ??
        json['image_url']?.toString() ??
        json['image']?.toString();

    if (json['vehicle'] is Map<String, dynamic>) {
      final veh = json['vehicle'] as Map<String, dynamic>;
      categoryIcon ??=
          veh['category_icon']?.toString() ??
          veh['icon_url']?.toString() ??
          veh['icon']?.toString();
      categoryImage ??=
          veh['category_image']?.toString() ??
          veh['image_url']?.toString() ??
          veh['image']?.toString();
    }

    return BookingDataModel(
      id: json['id'] as int?,
      bookingNo: json['booking_no']?.toString(),
      status: json['status']?.toString(),
      bookingMode:
          json['booking_mode']?.toString() ?? json['service_mode']?.toString(),
      driverId: json['driver_id'] as int?,
      vehicleId: json['vehicle_id'] as int?,
      vehicleCategoryId: json['vehicle_category_id'] as int?,
      scheduledAt: json['scheduled_at']?.toString(),
      pickupAddress: _sanitizeAddress(json['pickup_address']?.toString()),
      dropAddress: _sanitizeAddress(json['drop_address']?.toString()),
      startOtp: json['start_otp']?.toString(),
      endOtp: json['end_otp']?.toString(),
      estimatedAmount: json['estimated_amount'] != null
          ? double.tryParse(json['estimated_amount'].toString())
          : null,
      finalAmount: json['final_amount'] != null
          ? double.tryParse(json['final_amount'].toString())
          : null,
      driverName: json['driver'] is Map<String, dynamic>
          ? (json['driver']['name']?.toString())
          : null,
      driverPhone: json['driver'] is Map<String, dynamic>
          ? json['driver']['phone']?.toString()
          : json['driver_phone']?.toString(),
      vehicleNumber: json['vehicle'] is Map<String, dynamic>
          ? (json['vehicle']['vehicle_number']?.toString())
          : null,
      vehicleName: json['vehicle'] is Map<String, dynamic>
          ? _joinParts([
              json['vehicle']['brand']?.toString(),
              json['vehicle']['model']?.toString(),
            ])
          : null,
      pickupLatitude: _getLocationField(json, 'pickup_location', 'latitude'),
      pickupLongitude: _getLocationField(json, 'pickup_location', 'longitude'),
      dropLatitude: _getLocationField(json, 'drop_location', 'latitude'),
      dropLongitude: _getLocationField(json, 'drop_location', 'longitude'),
      categoryName:
          json['category_name']?.toString() ??
          (json['category'] is Map<String, dynamic>
              ? json['category']['name']?.toString()
              : null),
      categoryIcon: categoryIcon,
      categoryImage: categoryImage,
      driverLatitude: json['driver'] is Map<String, dynamic>
          ? json['driver']['latitude']?.toString()
          : null,
      driverLongitude: json['driver'] is Map<String, dynamic>
          ? json['driver']['longitude']?.toString()
          : null,
      requiresDropLocation: requiresDrop,
      fareBreakdown: json['fare'] is Map<String, dynamic>
          ? FareBreakdown.fromJson(json['fare'] as Map<String, dynamic>)
          : null,
    );
  }

  static String? _getLocationField(
    Map<String, dynamic> json,
    String relationKey,
    String fieldKey,
  ) {
    final loc = json[relationKey];
    if (loc is Map<String, dynamic>) {
      if (loc.containsKey(fieldKey)) {
        return loc[fieldKey]?.toString();
      }
      final data = loc['data'];
      if (data is Map<String, dynamic> && data.containsKey(fieldKey)) {
        return data[fieldKey]?.toString();
      }
    }
    return null;
  }

  static String? _sanitizeAddress(String? address) {
    if (address == null || address.trim().isEmpty) {
      return null;
    }
    final trimmed = address.trim();
    if (trimmed.startsWith('Location (') ||
        trimmed.startsWith('Enable GOOGLE_')) {
      return 'Pickup Location';
    }
    return trimmed;
  }

  static String? _joinParts(List<String?> parts) {
    final values = parts
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .toList();

    if (values.isEmpty) {
      return null;
    }

    return values.join(' ');
  }
}
