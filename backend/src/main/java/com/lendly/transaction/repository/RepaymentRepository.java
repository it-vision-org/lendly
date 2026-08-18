package com.lendly.transaction.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.lendly.transaction.domain.Repayment;

public interface RepaymentRepository extends JpaRepository<Repayment, UUID> {

    List<Repayment> findAllByTransactionIdOrderByPaymentDateDesc(UUID transactionId);

    Optional<Repayment> findByIdAndTransactionId(UUID id, UUID transactionId);
}
