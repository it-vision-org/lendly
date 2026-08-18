package com.lendly.identity.api.dto;

public record AuthResponse(
    String accessToken,
    String refreshToken,
    long expiresInSeconds,
    UserSummary user
) {
}
