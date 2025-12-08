class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String userType;
  final String? dob;
  final String? rfc;
  final String? phoneNumber;
  final String? placeOfBirth;
  final String? profilePicture;
  final String? businessName;
  final String? businessAddress;
  final String? address;
  final String? paymentInstructions;
  final bool? receiveEmailNotifications;
  final bool? isDarkModeEnabled;
  final String? bio;
  final String? gender;
  final Map<String, String>? socialMediaLinks;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.userType,
    this.dob,
    this.rfc,
    this.phoneNumber,
    this.placeOfBirth,
    this.profilePicture,
    this.businessName,
    this.businessAddress,
    this.address,
    this.paymentInstructions,
    this.receiveEmailNotifications,
    this.isDarkModeEnabled,
    this.bio,
    this.gender,
    this.socialMediaLinks,
  }); // Corrected: Closing brace for constructor

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      userType: map['userType'] ?? 'Buyer',
      dob: map['dob'],
      rfc: map['rfc'],
      phoneNumber: map['phoneNumber'],
      placeOfBirth: map['placeOfBirth'],
      profilePicture: map['profilePicture'],
      businessName: map['businessName'],
      businessAddress: map['businessAddress'],
      address: map['address'],
      paymentInstructions: map['paymentInstructions'],
      receiveEmailNotifications: map['receiveEmailNotifications'] ?? true,
      isDarkModeEnabled: map['isDarkModeEnabled'] ?? false,
      bio: map['bio'],
      gender: map['gender'],
      socialMediaLinks: (map['socialMediaLinks'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(key, value as String)),
    ); // Corrected: Closing parenthesis and brace for fromMap
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'userType': userType,
      'dob': dob,
      'rfc': rfc,
      'phoneNumber': phoneNumber,
      'placeOfBirth': placeOfBirth,
      'profilePicture': profilePicture,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'address': address,
      'paymentInstructions': paymentInstructions,
      'receiveEmailNotifications': receiveEmailNotifications,
      'isDarkModeEnabled': isDarkModeEnabled,
      'bio': bio,
      'gender': gender,
      'socialMediaLinks': socialMediaLinks,
    }; // Corrected: Closing brace for toMap
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? userType,
    String? dob,
    String? rfc,
    String? phoneNumber,
    String? placeOfBirth,
    String? profilePicture,
    String? businessName,
    String? businessAddress,
    String? address,
    String? paymentInstructions,
    bool? receiveEmailNotifications,
    bool? isDarkModeEnabled,
    String? bio,
    String? gender,
    Map<String, String>? socialMediaLinks,
  }) { // Corrected: Closing parenthesis for copyWith parameters
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      dob: dob ?? this.dob,
      rfc: rfc ?? this.rfc,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      profilePicture: profilePicture ?? this.profilePicture,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      address: address ?? this.address,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      receiveEmailNotifications: receiveEmailNotifications ?? this.receiveEmailNotifications,
      isDarkModeEnabled: isDarkModeEnabled ?? this.isDarkModeEnabled,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
    ); // Corrected: Closing brace for copyWith
  }
}
