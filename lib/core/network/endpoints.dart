class ApiEndpoints {
  static const login = '/login';
  static const sendOtp = '/send-otp';
  static const verifyOtp = '/verify-otp';
  static const logout = '/logout';
  static const socialLogin = '/social-login';
  static const vehicletype = '/vehicle-types';
  static const vehicletypelist = '/vehicles';
  static const bookings = '/bookings';
  static const bookingActive = '/bookings/check/active';
  static const profile = '/profile';
  static const bookingsHistory = '/bookings';
  static const faqs = '/faqs';
  static const supportTickets = '/support/tickets';
  static String bookingDetails(String bookingNo) => '/bookings/$bookingNo';
  static String bookingSos(String bookingNo) => '/bookings/$bookingNo/sos';
  static String bookingReview(String bookingNo) => '/bookings/$bookingNo/review';
  static const checkUpdate = '/check-update';
  static const updateFcmToken = '/fcm-token';
}
