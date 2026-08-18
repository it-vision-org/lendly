package com.lendly.contact.api.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record ContactRequest(
    @NotBlank String name,
    String phone,
    @Email String email,
    String notes
) {
}
