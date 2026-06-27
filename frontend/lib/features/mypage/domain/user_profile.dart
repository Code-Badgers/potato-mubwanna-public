class UserProfile {
  const UserProfile({
    required this.userId,
    required this.nickname,
    required this.email,
    required this.profileImage,
    required this.createdAt,
  });

  final int userId;
  final String nickname;
  final String email;
  final String profileImage;
  final DateTime? createdAt;

  bool get hasProfileImage => profileImage.trim().isNotEmpty;

  static UserProfile fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    final createdAtValue = data['createdAt'] as String?;

    return UserProfile(
      userId: data['userId'] as int? ?? 0,
      nickname: data['nickname'] as String? ?? '',
      email: data['email'] as String? ?? '',
      profileImage: data['profileImage'] as String? ?? '',
      createdAt: createdAtValue == null || createdAtValue.isEmpty
          ? null
          : DateTime.parse(createdAtValue),
    );
  }
}
