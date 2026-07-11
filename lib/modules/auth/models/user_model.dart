class UserModel {

  final int id;
  final String name;
  final String? email;
  final String mobile;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.mobile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {

    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      mobile: json['mobile'],
      
    );
  }

  Map<String, dynamic> toJson() {

    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
    };
  }
}