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
          : (rawStatus.toString() == 'true' || rawStatus.toString() == 'success'),
      message: json['message']?.toString() ?? '',
      data: data is Map<String, dynamic>
          ? BookingDataModel.fromJson(data)
          : null,
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
    this.driverName,
    this.vehicleNumber,
    this.vehicleName,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropLatitude,
    this.dropLongitude,
    this.categoryName,
    this.driverLatitude,
    this.driverLongitude,
    required this.requiresDropLocation,
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
  final String? driverName;
  final String? vehicleNumber;
  final String? vehicleName;
  final String? pickupLatitude;
  final String? pickupLongitude;
  final String? dropLatitude;
  final String? dropLongitude;
  final String? categoryName;
  final String? driverLatitude;
  final String? driverLongitude;
  final bool requiresDropLocation;

  factory BookingDataModel.fromJson(Map<String, dynamic> json) {
    final requiresDrop = json['requires_drop_location'] is bool
        ? json['requires_drop_location'] as bool
        : (json['requires_drop_location']?.toString() == 'true' || json['drop_location'] != null);

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
      pickupAddress: json['pickup_address']?.toString(),
      dropAddress: json['drop_address']?.toString(),
      startOtp: json['start_otp']?.toString(),
      endOtp: json['end_otp']?.toString(),
      estimatedAmount: json['estimated_amount'] != null
          ? double.tryParse(json['estimated_amount'].toString())
          : null,
      driverName: json['driver'] is Map<String, dynamic>
          ? (json['driver']['name']?.toString())
          : null,
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
      categoryName: json['category_name']?.toString() ??
          (json['category'] is Map<String, dynamic>
              ? json['category']['name']?.toString()
              : null),
      driverLatitude: json['driver'] is Map<String, dynamic>
          ? json['driver']['latitude']?.toString()
          : null,
      driverLongitude: json['driver'] is Map<String, dynamic>
          ? json['driver']['longitude']?.toString()
          : null,
      requiresDropLocation: requiresDrop,
    );
  }

  static String? _getLocationField(Map<String, dynamic> json, String relationKey, String fieldKey) {
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

  static String? _joinParts(List<String?> parts) {
    final values = parts
        .where((part) => part != null && part!.trim().isNotEmpty)
        .map((part) => part!.trim())
        .toList();

    if (values.isEmpty) {
      return null;
    }

    return values.join(' ');
  }
}
