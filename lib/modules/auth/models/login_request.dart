class LoginRequest {
  final String mobile;

  LoginRequest({
    required this.mobile,
  });

  Map<String, dynamic> toJson() => {
    "mobile": mobile,
  };
}