class UserSummary {
  const UserSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
    );
  }

  final String id;
  final String firstName;
  final String lastName;
  final String email;

  String get fullName => '$firstName $lastName';
}
