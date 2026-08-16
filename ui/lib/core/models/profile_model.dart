class Profile {
  final int id;
  final String firstName;
  final String lastName;
  final String userCode;
  final String email;
  final String role;
  final String avatarUrl;

  Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.userCode,
    required this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? 0,
      userCode: json['user_code'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      avatarUrl: json['avatar'],
    );
  }
}
