package com.lendly.identity.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CompletePasswordResetRequest(
    @NotBlank String resetToken,
    @NotBlank @Size(min = 8, message = "Password must be at least 8 characters") String newPassword,
    @NotBlank String confirmPassword
) {
}
