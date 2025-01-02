class UserModel {
  final String uid;
  final String username;
  final String email;

  UserModel({required this.uid, required this.username, required this.email});

  // Convert a UserModel object to a map for saving to Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
    };
  }

  // Create a UserModel object from a map (useful when fetching data from Firebase)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
    );
  }
}
