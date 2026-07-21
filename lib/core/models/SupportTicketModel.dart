class SupportTicketModel {
  SupportTicketModel({
    required this.id,
    required this.ticketNo,
    required this.userId,
    this.bookingId,
    required this.category,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    this.createdAt,
  });

  final int id;
  final String ticketNo;
  final int userId;
  final int? bookingId;
  final String category;
  final String subject;
  final String message;
  final String status;
  final String priority;
  final String? createdAt;

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] as int? ?? 0,
      ticketNo: json['ticket_no']?.toString() ?? '',
      userId: json['user_id'] as int? ?? 0,
      bookingId: json['booking_id'] as int?,
      category: json['category']?.toString() ?? 'General Query',
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      priority: json['priority']?.toString() ?? 'medium',
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_no': ticketNo,
      'user_id': userId,
      'booking_id': bookingId,
      'category': category,
      'subject': subject,
      'message': message,
      'status': status,
      'priority': priority,
      'created_at': createdAt,
    };
  }
}
