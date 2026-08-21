package com.lendly.identity.repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.lendly.identity.domain.EmailVerification;

public interface EmailVerificationRepository extends JpaRepository<EmailVerification, UUID> {

    Optional<EmailVerification> findFirstByUserIdOrderByCreatedAtDesc(UUID userId);

    long countByUserIdAndCreatedAtAfter(UUID userId, Instant since);

    long countByIpAddressAndCreatedAtAfter(String ipAddress, Instant since);

    /**
     * Invalidates any still-usable codes for this user by expiring them
     * immediately, so a newer code (generated right after this call) is the
     * only one that can succeed. Rows are kept (not deleted) so hourly
     * send-rate counting stays accurate.
     */
    @Modifying
    @Query("""
        update EmailVerification e
        set e.expiresAt = :now
        where e.user.id = :userId and e.verifiedAt is null and e.expiresAt > :now
        """)
    void expireActiveForUser(@Param("userId") UUID userId, @Param("now") Instant now);

    void deleteByCreatedAtBefore(Instant cutoff);
}
