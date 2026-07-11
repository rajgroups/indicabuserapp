class OtpRequest {
  final String mobile;
  final String otp;

  OtpRequest({
    required this.mobile,
    required this.otp,
  });

  Map<String, dynamic> toJson() => {
    "mobile": mobile,
    "otp": otp,
  };
}