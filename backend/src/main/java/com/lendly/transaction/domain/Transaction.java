package com.lendly.transaction.domain;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import com.lendly.contact.domain.Contact;
import com.lendly.identity.domain.User;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "transactions")
@Getter
@Setter
@NoArgsConstructor
public class Transaction {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(optional = false)
    @JoinColumn(name = "contact_id", nullable = false)
    private Contact contact;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 20)
    private TransactionType type;

    @Column(name = "original_amount", nullable = false, precision = 14, scale = 2)
    private BigDecimal originalAmount;

    @Column(name = "remaining_amount", nullable = false, precision = 14, scale = 2)
    private BigDecimal remainingAmount;

    @Column(name = "currency", nullable = false, length = 3)
    private String currency = "TND";

    @Column(name = "description", length = 500)
    private String description;

    @Column(name = "transaction_date", nullable = false)
    private LocalDate transactionDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private TransactionStatus status;

    @Version
    @Column(name = "version", nullable = false)
    private long version;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public Transaction(
        User user,
        Contact contact,
        TransactionType type,
        BigDecimal originalAmount,
        String currency,
        String description,
        LocalDate transactionDate
    ) {
        this.user = user;
        this.contact = contact;
        this.type = type;
        this.originalAmount = originalAmount;
        this.remainingAmount = originalAmount;
        this.currency = currency;
        this.description = description;
        this.transactionDate = transactionDate;
        this.status = TransactionStatus.ACTIVE;
    }
}
