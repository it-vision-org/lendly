package com.lendly.contact.api.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record ContactResponse(
    UUID id,
    String name,
    String phone,
    String email,
    String notes,
    BigDecimal totalOwedToMe,
    BigDecimal totalIOwe,
    BigDecimal netBalance,
    Instant createdAt,
    Instant updatedAt
) {
}
