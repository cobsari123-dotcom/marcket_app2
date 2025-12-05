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
  final bool? receiveEmailNotifications; // New field
  final bool? isDarkModeEnabled; // New field

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
    this.receiveEmailNotifications, // Added to constructor
    this.isDarkModeEnabled, // Added to constructor
  });

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
      receiveEmailNotifications: map['receiveEmailNotifications'] ?? true, // Default to true
      isDarkModeEnabled: map['isDarkModeEnabled'] ?? false, // Default to false
    );
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
    };
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
    bool? receiveEmailNotifications, // Added to copyWith
    bool? isDarkModeEnabled, // Added to copyWith
  }) {
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
    );
  }
}