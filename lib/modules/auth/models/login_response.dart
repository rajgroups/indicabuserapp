import 'user_model.dart';

class LoginResponse {

  final String status;
  final String message;
  final LoginData data;

  LoginResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory LoginResponse.fromJson(
    Map<String, dynamic> json,
  ) {

    return LoginResponse(
      status: json['status'],
      message: json['message'],
      data: LoginData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {

    return {
      'status': status,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class LoginData {

  final String token;
  final UserModel user;

  LoginData({
    required this.token,
    required this.user,
  });

  factory LoginData.fromJson(
    Map<String, dynamic> json,
  ) {

    return LoginData(
      token: json['token'],
      user: UserModel.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {

    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}