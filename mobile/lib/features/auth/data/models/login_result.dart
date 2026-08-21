import 'email_verification_challenge.dart';
import 'user_summary.dart';

/// Result of a login attempt. Exactly one of [user]/[verification] is set:
/// a correct password against an unverified account returns [verification]
/// instead of a session — no tokens are issued until the email is confirmed.
class LoginResult {
  const LoginResult.authenticated(UserSummary this.user) : verification = null;

  const LoginResult.verificationRequired(
    EmailVerificationChallenge this.verification,
  ) : user = null;

  final UserSummary? user;
  final EmailVerificationChallenge? verification;

  bool get requiresVerification => verification != null;
}
