class SosAlertModel {
  final int id;
  final int bookingId;
  final String type;
  final String status;
  final String? message;
  final double? latitude;
  final double? longitude;
  final String? createdAt;

  const SosAlertModel({
    required this.id,
    required this.bookingId,
    required this.type,
    required this.status,
    this.message,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory SosAlertModel.fromJson(Map<String, dynamic> json) {
    return SosAlertModel(
      id: json['sos_id'] as int? ?? json['id'] as int? ?? 0,
      bookingId: json['booking_id'] as int? ?? 0,
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      message: json['message']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'booking_id': bookingId,
        'type': type,
        'status': status,
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': createdAt,
      };
}
