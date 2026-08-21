class VerifyEmailArgs {
  const VerifyEmailArgs({
    required this.verificationId,
    required this.email,
    required this.resendCooldownSeconds,
  });

  final String verificationId;
  final String email;
  final int resendCooldownSeconds;
}
