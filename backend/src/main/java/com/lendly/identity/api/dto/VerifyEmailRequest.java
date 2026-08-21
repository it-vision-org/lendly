package com.lendly.identity.api.dto;

import java.util.UUID;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

public record VerifyEmailRequest(
    @NotNull UUID verificationId,
    @NotBlank @Pattern(regexp = "\\d{6}", message = "Code must be exactly 6 digits") String code,
    String deviceInfo
) {
}
