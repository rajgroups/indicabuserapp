class LoginRequest {
  final String mobile;
  final String? referralCode;

  LoginRequest({
    required this.mobile,
    this.referralCode,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      "mobile": mobile,
    };
    if (referralCode != null && referralCode!.trim().isNotEmpty) {
      map["referral_code"] = referralCode!.trim();
    }
    return map;
  }
}