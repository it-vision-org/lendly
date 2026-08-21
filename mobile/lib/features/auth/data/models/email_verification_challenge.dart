class EmailVerificationChallenge {
  const EmailVerificationChallenge({
    required this.verificationId,
    required this.expiresInSeconds,
    required this.resendCooldownSeconds,
  });

  factory EmailVerificationChallenge.fromJson(Map<String, dynamic> json) {
    return EmailVerificationChallenge(
      verificationId: json['verificationId'] as String,
      expiresInSeconds: json['expiresInSeconds'] as int,
      resendCooldownSeconds: json['resendCooldownSeconds'] as int,
    );
  }

  final String verificationId;
  final int expiresInSeconds;
  final int resendCooldownSeconds;
}
