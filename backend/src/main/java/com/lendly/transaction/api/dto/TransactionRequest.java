package com.lendly.transaction.api.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import com.lendly.transaction.domain.TransactionType;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record TransactionRequest(
    @NotNull UUID contactId,
    @NotNull TransactionType type,
    @NotNull @Positive BigDecimal amount,
    @Size(max = 3) String currency,
    @Size(max = 500) String description,
    @NotNull LocalDate transactionDate
) {
}
