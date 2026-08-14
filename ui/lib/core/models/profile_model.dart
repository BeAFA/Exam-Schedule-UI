class Profile {
  final int id;
  final String fullName;
  final String userCode;
  final String email;
  final String role;
  final String? avatarUrl;

  Profile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.userCode,
    this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? 0,
      userCode: json['user_code'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
