class NearbyVehicle {
  final int driverId;
  final int vehicleId;
  final int vehicleCategoryId;
  final String? vehicleNumber;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String? iconUrl;
  final DateTime? locationUpdatedAt;

  NearbyVehicle({
    required this.driverId,
    required this.vehicleId,
    required this.vehicleCategoryId,
    this.vehicleNumber,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.iconUrl,
    this.locationUpdatedAt,
  });

  factory NearbyVehicle.fromJson(Map<String, dynamic> json) {
    return NearbyVehicle(
      driverId: json['driver_id'] ?? 0,
      vehicleId: json['vehicle_id'] ?? 0,
      vehicleCategoryId: json['vehicle_category_id'] ?? 0,
      vehicleNumber: json['vehicle_number'],
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? '0.0') ?? 0.0,
      iconUrl: json['icon_url'],
      locationUpdatedAt: json['location_updated_at'] != null
          ? DateTime.tryParse(json['location_updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'vehicle_category_id': vehicleCategoryId,
      'vehicle_number': vehicleNumber,
      'latitude': latitude,
      'longitude': longitude,
      'distance_km': distanceKm,
      'icon_url': iconUrl,
      'location_updated_at': locationUpdatedAt?.toIso8601String(),
    };
  }
}
