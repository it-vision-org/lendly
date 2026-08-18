package com.lendly.identity.api.dto;

import jakarta.validation.constraints.NotBlank;

public record RefreshRequest(
    @NotBlank String refreshToken,
    String deviceInfo
) {
}
