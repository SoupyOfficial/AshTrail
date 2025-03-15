class UserProfile {
  final String uid;
  final String email;
  final String firstName;
  final String? lastName;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  UserProfile({
    required this.uid,
    required this.email,
    required this.firstName,
    this.lastName,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      email: data['email'] as String,
      firstName: data['firstName'] as String? ?? 'User',
      lastName: data['lastName'] as String?,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as dynamic).toDate()
          : null,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'isActive': isActive,
    };
  }

  UserProfile copyWith({
    String? email,
    String? firstName,
    String? lastName,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return UserProfile(
      uid: uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
