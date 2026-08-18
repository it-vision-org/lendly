package com.lendly.transaction.api.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record RepaymentResponse(
    UUID id,
    UUID transactionId,
    BigDecimal amount,
    LocalDate paymentDate,
    String notes,
    Instant createdAt
) {
}
