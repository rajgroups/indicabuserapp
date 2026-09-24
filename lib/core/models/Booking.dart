class Booking {
  final int? id;
  final String? bookingNo;
  final String? status;
  final String? startOtp;
  final String? driverName;
  final String? vehicleName;
  final String? vehicleNumber;
  final String? driverPhone;
  final double? estimatedAmount;
  final double? finalAmount;
  final String? pickupAddress;
  final String? dropAddress;

  Booking({
    this.id,
    this.bookingNo,
    this.status,
    this.startOtp,
    this.driverName,
    this.driverPhone,
    this.vehicleName,
    this.vehicleNumber,
    this.estimatedAmount,
    this.finalAmount,
    this.pickupAddress,
    this.dropAddress,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'];
    final vehicle = json['vehicle'];

    return Booking(
      id: json['id'],
      bookingNo: json['booking_no'],
      status: json['status'],
      startOtp: json['start_otp'],
      estimatedAmount: (json['estimated_amount'] as num?)?.toDouble(),
      finalAmount: (json['final_amount'] as num?)?.toDouble(),
      pickupAddress: json['pickup_address'],
      dropAddress: json['drop_address'],
      driverName: driver is Map ? driver['name'] : json['driver_name'],
      driverPhone: driver is Map ? driver['phone'] : json['driver_phone'],
      vehicleName: vehicle is Map ? vehicle['name'] : json['vehicle_name'],
      vehicleNumber:
          vehicle is Map ? vehicle['vehicle_number'] : json['vehicle_number'],
    );
  }

  // It seems your BookingRepository returns a different model.
  // This factory will help convert it to the Booking model used by the UI/Services.
  factory Booking.fromBookingDataModel(dynamic dataModel) {
    return Booking(
      id: dataModel.id,
      bookingNo: dataModel.bookingNo,
      status: dataModel.status,
      startOtp: dataModel.startOtp,
      driverName: dataModel.driverName,
      driverPhone: dataModel.driverPhone,
      vehicleName: dataModel.vehicleName,
      vehicleNumber: dataModel.vehicleNumber,
      estimatedAmount: (dataModel.estimatedAmount as num?)?.toDouble(),
      finalAmount: (dataModel.finalAmount as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'booking_no': bookingNo,
        'status': status,
        'start_otp': startOtp,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'vehicle_name': vehicleName,
        'vehicle_number': vehicleNumber,
        'estimated_amount': estimatedAmount,
        'final_amount': finalAmount,
      };
}