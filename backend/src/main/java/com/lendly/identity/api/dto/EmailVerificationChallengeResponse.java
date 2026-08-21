package com.lendly.identity.api.dto;

import java.util.UUID;

public record EmailVerificationChallengeResponse(
    UUID verificationId,
    long expiresInSeconds,
    long resendCooldownSeconds
) {
}
