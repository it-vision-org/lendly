package com.lendly.transaction.api.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record RepaymentRequest(
    @NotNull @Positive BigDecimal amount,
    @NotNull LocalDate paymentDate,
    @Size(max = 500) String notes
) {
}
