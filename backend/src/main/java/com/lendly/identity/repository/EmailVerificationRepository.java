package com.lendly.identity.repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.lendly.identity.domain.EmailVerification;
import com.lendly.identity.domain.VerificationPurpose;

public interface EmailVerificationRepository extends JpaRepository<EmailVerification, UUID> {

    Optional<EmailVerification> findFirstByUserIdAndPurposeOrderByCreatedAtDesc(UUID userId, VerificationPurpose purpose);

    long countByUserIdAndPurposeAndCreatedAtAfter(UUID userId, VerificationPurpose purpose, Instant since);

    long countByIpAddressAndCreatedAtAfter(String ipAddress, Instant since);

    Optional<EmailVerification> findByResetTokenHash(String resetTokenHash);

    /**
     * Invalidates any still-usable codes for this user+purpose by expiring
     * them immediately, so a newer code (generated right after this call) is
     * the only one that can succeed. A resend for one purpose never touches
     * an unrelated purpose's active code. Rows are kept (not deleted) so
     * hourly send-rate counting stays accurate.
     */
    @Modifying
    @Query("""
        update EmailVerification e
        set e.expiresAt = :now
        where e.user.id = :userId and e.purpose = :purpose and e.verifiedAt is null and e.expiresAt > :now
        """)
    void expireActiveForUser(@Param("userId") UUID userId, @Param("purpose") VerificationPurpose purpose, @Param("now") Instant now);

    void deleteByCreatedAtBefore(Instant cutoff);
}
