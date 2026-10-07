class DistrictUser {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? dateOfBirth;
  final String? bloodGroup;
  final String? profilePhotoUrl;
  final bool isBlocked;

  const DistrictUser({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.dateOfBirth,
    this.bloodGroup,
    this.profilePhotoUrl,
    this.isBlocked = false,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'phoneNumber': phoneNumber,
    'displayName': displayName,
    'dateOfBirth': dateOfBirth,
    'bloodGroup': bloodGroup,
    'profilePhotoUrl': profilePhotoUrl,
    'isBlocked': isBlocked,
  };

  factory DistrictUser.fromMap(Map<String, dynamic> map) => DistrictUser(
    uid: map['uid'] as String? ?? '',
    email: map['email'] as String?,
    phoneNumber: map['phoneNumber'] as String?,
    displayName: map['displayName'] as String? ?? map['name'] as String?,
    dateOfBirth: map['dateOfBirth'] as String?,
    bloodGroup: map['bloodGroup'] as String?,
    profilePhotoUrl: map['profilePhotoUrl'] as String?,
    isBlocked: map['isBlocked'] as bool? ?? false,
  );
}
