import 'package:lendly/features/auth/data/models/email_verification_challenge.dart';
import 'package:lendly/features/auth/data/models/login_result.dart';
import 'package:lendly/features/auth/data/models/user_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginResult', () {
    test(
      'authenticated result carries the user and does not require verification',
      () {
        const user = UserSummary(
          id: 'u-1',
          fullName: 'Ahmed Zouaghi',
          email: 'ahmed@example.com',
        );

        const result = LoginResult.authenticated(user);

        expect(result.user, user);
        expect(result.verification, isNull);
        expect(result.requiresVerification, isFalse);
      },
    );

    test('verificationRequired result carries the challenge and no user', () {
      const challenge = EmailVerificationChallenge(
        verificationId: 'v-1',
        expiresInSeconds: 600,
        resendCooldownSeconds: 60,
      );

      const result = LoginResult.verificationRequired(challenge);

      expect(result.user, isNull);
      expect(result.verification, challenge);
      expect(result.requiresVerification, isTrue);
    });
  });
}
