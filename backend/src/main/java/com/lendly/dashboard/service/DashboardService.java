package com.lendly.dashboard.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.lendly.dashboard.api.dto.DashboardResponse;
import com.lendly.identity.domain.User;
import com.lendly.transaction.domain.TransactionStatus;
import com.lendly.transaction.domain.TransactionType;
import com.lendly.transaction.mapper.TransactionMapper;
import com.lendly.transaction.repository.TransactionRepository;

@Service
public class DashboardService {

    private final TransactionRepository transactionRepository;
    private final TransactionMapper mapper;

    public DashboardService(TransactionRepository transactionRepository, TransactionMapper mapper) {
        this.transactionRepository = transactionRepository;
        this.mapper = mapper;
    }

    @Transactional(readOnly = true)
    public DashboardResponse get(User user) {
        var totalOwedToMe = transactionRepository.sumRemainingByUserIdAndType(user.getId(), TransactionType.LENT);
        var totalIOwe = transactionRepository.sumRemainingByUserIdAndType(user.getId(), TransactionType.BORROWED);

        var recentTransactions = transactionRepository
            .findTop5ByUserIdOrderByTransactionDateDescCreatedAtDesc(user.getId())
            .stream()
            .map(mapper::toResponse)
            .toList();

        return new DashboardResponse(
            totalOwedToMe,
            totalIOwe,
            totalOwedToMe.subtract(totalIOwe),
            transactionRepository.countByUserIdAndTypeAndStatusNot(user.getId(), TransactionType.LENT, TransactionStatus.PAID),
            transactionRepository.countByUserIdAndTypeAndStatusNot(user.getId(), TransactionType.BORROWED, TransactionStatus.PAID),
            recentTransactions
        );
    }
}
