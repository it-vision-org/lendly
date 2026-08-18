package com.lendly.transaction.api.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

import com.lendly.transaction.domain.TransactionStatus;
import com.lendly.transaction.domain.TransactionType;

public record TransactionResponse(
    UUID id,
    UUID contactId,
    String contactName,
    TransactionType type,
    BigDecimal originalAmount,
    BigDecimal remainingAmount,
    String currency,
    String description,
    LocalDate transactionDate,
    TransactionStatus status,
    Instant createdAt,
    Instant updatedAt
) {
}
