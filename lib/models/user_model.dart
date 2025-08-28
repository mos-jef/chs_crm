class UserModel {
  final String uid;
  final String email;
  final bool isAdmin;
  final bool isApproved;
  final String preferredTheme;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.isAdmin = false,
    this.isApproved = false,
    this.preferredTheme = 'athlete_dark',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'isAdmin': isAdmin,
      'isApproved': isApproved,
      'preferredTheme': preferredTheme,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      isApproved: map['isApproved'] ?? false,
      preferredTheme: map['preferredTheme'] ?? 'athlete_dark',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}
