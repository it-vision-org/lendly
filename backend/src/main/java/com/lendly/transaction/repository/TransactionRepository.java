package com.lendly.transaction.repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.lendly.transaction.domain.Transaction;
import com.lendly.transaction.domain.TransactionStatus;
import com.lendly.transaction.domain.TransactionType;

public interface TransactionRepository extends JpaRepository<Transaction, UUID> {

    Optional<Transaction> findByIdAndUserId(UUID id, UUID userId);

    @Query("""
        select t from Transaction t
        where t.user.id = :userId
        and (:type is null or t.type = :type)
        and (:status is null or t.status = :status)
        and (:contactId is null or t.contact.id = :contactId)
        order by t.transactionDate desc, t.createdAt desc
        """)
    List<Transaction> search(
        @Param("userId") UUID userId,
        @Param("type") TransactionType type,
        @Param("status") TransactionStatus status,
        @Param("contactId") UUID contactId
    );

    List<Transaction> findTop5ByUserIdOrderByTransactionDateDescCreatedAtDesc(UUID userId);

    @Query("""
        select coalesce(sum(t.remainingAmount), 0) from Transaction t
        where t.user.id = :userId and t.type = :type and t.status <> com.lendly.transaction.domain.TransactionStatus.PAID
        """)
    BigDecimal sumRemainingByUserIdAndType(@Param("userId") UUID userId, @Param("type") TransactionType type);

    long countByUserIdAndTypeAndStatusNot(UUID userId, TransactionType type, TransactionStatus status);

    interface ContactBalance {
        UUID getContactId();
        BigDecimal getTotal();
    }

    @Query("""
        select t.contact.id as contactId, coalesce(sum(t.remainingAmount), 0) as total
        from Transaction t
        where t.user.id = :userId and t.type = :type and t.status <> com.lendly.transaction.domain.TransactionStatus.PAID
        group by t.contact.id
        """)
    List<ContactBalance> sumRemainingByContactAndType(@Param("userId") UUID userId, @Param("type") TransactionType type);
}
