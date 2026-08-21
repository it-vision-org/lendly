package com.lendly.identity.api.dto;

/**
 * Exactly one of {@code auth}/{@code verification} is populated. A correct
 * password against an unverified account returns {@code verification}
 * instead of {@code auth} — no tokens are issued until the email is
 * confirmed.
 */
public record LoginResponse(
    AuthResponse auth,
    EmailVerificationChallengeResponse verification
) {
    public static LoginResponse authenticated(AuthResponse auth) {
        return new LoginResponse(auth, null);
    }

    public static LoginResponse verificationRequired(EmailVerificationChallengeResponse verification) {
        return new LoginResponse(null, verification);
    }
}
