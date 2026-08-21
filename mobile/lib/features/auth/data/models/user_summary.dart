class UserSummary {
  const UserSummary({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
    );
  }

  final String id;
  final String fullName;
  final String email;
}
