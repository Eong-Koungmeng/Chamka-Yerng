class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? profilePicture;
  final String? phoneNumber;

  UserModel({required this.uid, required this.username, required this.email, this.profilePicture, this.phoneNumber});

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'profilePicture': profilePicture,
      'phoneNumber': phoneNumber,
    };
  }

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      profilePicture: map['profilePicture'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }
}
