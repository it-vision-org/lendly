package com.lendly.dashboard.api.dto;

import java.math.BigDecimal;
import java.util.List;

import com.lendly.transaction.api.dto.TransactionResponse;

public record DashboardResponse(
    BigDecimal totalOwedToMe,
    BigDecimal totalIOwe,
    BigDecimal netBalance,
    long activeLentTransactions,
    long activeBorrowedTransactions,
    List<TransactionResponse> recentTransactions
) {
}
