class UserProfileModel {
  UserProfileModel({
    required this.id,
    this.uuid,
    this.name,
    this.firstName,
    this.lastName,
    this.email,
    this.mobile,
    this.countryCode,
    this.gender,
    this.dateOfBirth,
    this.profileImage,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.emergencyContactName,
    this.emergencyContactMobile,
    this.emergencyContactRelation,
    required this.walletBalance,
    required this.rating,
  });

  final int id;
  final String? uuid;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? mobile;
  final String? countryCode;
  final String? gender;
  final String? dateOfBirth;
  final String? profileImage;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? emergencyContactName;
  final String? emergencyContactMobile;
  final String? emergencyContactRelation;
  final double walletBalance;
  final double rating;

  String get displayName {
    if (name != null && name!.trim().isNotEmpty) {
      return name!.trim();
    }
    final combined = [firstName, lastName]
        .where((element) => element != null && element.trim().isNotEmpty)
        .join(' ');
    if (combined.isNotEmpty) {
      return combined;
    }
    return 'User #$id';
  }

  String get displayPhone {
    if (mobile == null || mobile!.isEmpty) return '';
    final code = countryCode ?? '+91';
    return '$code ${mobile!}';
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as int? ?? 0,
      uuid: json['uuid']?.toString(),
      name: json['name']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString(),
      countryCode: json['country_code']?.toString(),
      gender: json['gender']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      profileImage: json['profile_image']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      postalCode: json['postal_code']?.toString(),
      emergencyContactName: json['emergency_contact_name']?.toString(),
      emergencyContactMobile: json['emergency_contact_mobile']?.toString(),
      emergencyContactRelation: json['emergency_contact_relation']?.toString(),
      walletBalance: json['wallet_balance'] != null
          ? double.tryParse(json['wallet_balance'].toString()) ?? 0.0
          : 0.0,
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString()) ?? 4.85
          : 4.85,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
      'country_code': countryCode,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'profile_image': profileImage,
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_mobile': emergencyContactMobile,
      'emergency_contact_relation': emergencyContactRelation,
      'wallet_balance': walletBalance,
      'rating': rating,
    };
  }
}
