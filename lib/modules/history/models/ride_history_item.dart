import 'package:flutter/material.dart';

class RideHistoryItem {
  const RideHistoryItem({
    required this.id,
    required this.periodTag,
    required this.dateLabel,
    required this.pickup,
    required this.drop,
    required this.type,
    required this.amountLabel,
    required this.amountValue,
    required this.status,
    required this.distance,
    required this.duration,
    required this.rating,
    required this.driverName,
    required this.vehicleNumber,
    required this.paymentMethod,
    required this.bookingId,
    required this.supportNote,
    required this.icon,
    required this.iconColor,
  });

  final String id;
  final String periodTag;
  final String dateLabel;
  final String pickup;
  final String drop;
  final String type;
  final String amountLabel;
  final double amountValue;
  final String status;
  final String distance;
  final String duration;
  final double rating;
  final String driverName;
  final String vehicleNumber;
  final String paymentMethod;
  final String bookingId;
  final String supportNote;
  final IconData icon;
  final Color iconColor;
}
