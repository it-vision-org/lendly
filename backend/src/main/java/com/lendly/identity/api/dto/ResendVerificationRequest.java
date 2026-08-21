package com.lendly.identity.api.dto;

import java.util.UUID;

import jakarta.validation.constraints.NotNull;

public record ResendVerificationRequest(
    @NotNull UUID verificationId
) {
}
