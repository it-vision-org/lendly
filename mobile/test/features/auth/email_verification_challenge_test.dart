import 'package:lendly/features/auth/data/models/email_verification_challenge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmailVerificationChallenge.fromJson', () {
    test('parses the backend response shape', () {
      final challenge = EmailVerificationChallenge.fromJson({
        'verificationId': 'b3ca4dcc-3f0a-460d-9190-05d27d85763b',
        'expiresInSeconds': 600,
        'resendCooldownSeconds': 60,
      });

      expect(challenge.verificationId, 'b3ca4dcc-3f0a-460d-9190-05d27d85763b');
      expect(challenge.expiresInSeconds, 600);
      expect(challenge.resendCooldownSeconds, 60);
    });
  });
}
