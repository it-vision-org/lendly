package com.lendly.identity.service;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.lendly.common.api.ApiException;
import com.lendly.common.security.AppSecurityProperties;
import com.lendly.email.EmailService;
import com.lendly.identity.api.dto.EmailVerificationChallengeResponse;
import com.lendly.identity.domain.EmailVerification;
import com.lendly.identity.domain.User;
import com.lendly.identity.repository.EmailVerificationRepository;
import com.lendly.identity.repository.UserRepository;

@Service
public class EmailVerificationService {

    private static final int CODE_LENGTH = 6;
    private static final Duration CODE_TTL = Duration.ofMinutes(10);
    private static final Duration RESEND_COOLDOWN = Duration.ofSeconds(60);
    private static final int MAX_ATTEMPTS = 5;
    private static final int MAX_SENDS_PER_USER_PER_HOUR = 5;
    private static final int MAX_SENDS_PER_IP_PER_HOUR = 10;
    private static final Duration RETENTION = Duration.ofDays(1);

    private final EmailVerificationRepository repository;
    private final UserRepository userRepository;
    private final EmailService emailService;
    private final AppSecurityProperties securityProperties;
    private final SecureRandom secureRandom = new SecureRandom();

    public EmailVerificationService(
        EmailVerificationRepository repository,
        UserRepository userRepository,
        EmailService emailService,
        AppSecurityProperties securityProperties
    ) {
        this.repository = repository;
        this.userRepository = userRepository;
        this.emailService = emailService;
        this.securityProperties = securityProperties;
    }

    @Transactional
    public EmailVerificationChallengeResponse startVerification(User user, String ipAddress) {
        Instant now = Instant.now();
        Optional<EmailVerification> latestOpt = repository.findFirstByUserIdOrderByCreatedAtDesc(user.getId());

        if (latestOpt.isPresent()) {
            EmailVerification latest = latestOpt.get();
            boolean stillCoolingDown = Duration.between(latest.getCreatedAt(), now).compareTo(RESEND_COOLDOWN) < 0;
            boolean stillUsable = latest.getVerifiedAt() == null && latest.getExpiresAt().isAfter(now);
            if (stillCoolingDown && stillUsable) {
                return toChallengeResponse(latest, now);
            }
        }

        enforceHourlyLimits(user, ipAddress, now);
        repository.expireActiveForUser(user.getId(), now);

        String code = generateCode();
        EmailVerification verification = new EmailVerification(
            user,
            VerificationCodeHasher.hash(securityProperties.emailVerificationSecret(), code),
            now.plus(CODE_TTL),
            ipAddress
        );
        // @CreationTimestamp only populates at Hibernate flush time; set it
        // explicitly so toChallengeResponse() below can read it immediately.
        verification.setCreatedAt(now);
        repository.save(verification);

        emailService.send(
            user.getEmail(),
            "Verify your email",
            EmailVerificationTemplate.html(code),
            EmailVerificationTemplate.text(code)
        );

        return toChallengeResponse(verification, now);
    }

    @Transactional
    public User verifyCode(UUID verificationId, String code) {
        EmailVerification verification = repository.findById(verificationId)
            .orElseThrow(() -> ApiException.badRequest("INVALID_CODE", "Incorrect verification code."));

        if (verification.getVerifiedAt() != null) {
            throw ApiException.badRequest("ALREADY_VERIFIED", "This account is already verified.");
        }
        if (verification.getExpiresAt().isBefore(Instant.now())) {
            throw ApiException.badRequest("CODE_EXPIRED", "This verification code has expired. Request a new one.");
        }
        if (verification.getAttempts() >= MAX_ATTEMPTS) {
            throw ApiException.tooManyRequests("TOO_MANY_ATTEMPTS", "Too many incorrect attempts. Request a new code.");
        }

        if (!VerificationCodeHasher.matches(securityProperties.emailVerificationSecret(), code, verification.getCodeHash())) {
            verification.setAttempts(verification.getAttempts() + 1);
            repository.save(verification);
            throw ApiException.badRequest("INVALID_CODE", "Incorrect verification code.");
        }

        verification.setVerifiedAt(Instant.now());
        repository.save(verification);

        User user = verification.getUser();
        user.setEmailVerifiedAt(Instant.now());
        userRepository.save(user);

        return user;
    }

    @Transactional
    public EmailVerificationChallengeResponse resend(UUID verificationId, String ipAddress) {
        EmailVerification current = repository.findById(verificationId)
            .orElseThrow(() -> ApiException.notFound("VERIFICATION_NOT_FOUND", "Verification session not found. Please sign up again."));

        User user = current.getUser();
        if (user.getEmailVerifiedAt() != null) {
            throw ApiException.badRequest("ALREADY_VERIFIED", "This account is already verified.");
        }

        return startVerification(user, ipAddress);
    }

    @Scheduled(cron = "0 0 * * * *")
    @Transactional
    public void cleanupExpired() {
        repository.deleteByCreatedAtBefore(Instant.now().minus(RETENTION));
    }

    private void enforceHourlyLimits(User user, String ipAddress, Instant now) {
        Instant since = now.minus(Duration.ofHours(1));

        if (repository.countByUserIdAndCreatedAtAfter(user.getId(), since) >= MAX_SENDS_PER_USER_PER_HOUR) {
            throw ApiException.tooManyRequests(
                "TOO_MANY_VERIFICATION_EMAILS",
                "Too many verification emails requested. Please try again later."
            );
        }
        if (ipAddress != null && !ipAddress.isBlank()
            && repository.countByIpAddressAndCreatedAtAfter(ipAddress, since) >= MAX_SENDS_PER_IP_PER_HOUR) {
            throw ApiException.tooManyRequests(
                "TOO_MANY_VERIFICATION_EMAILS",
                "Too many verification emails requested. Please try again later."
            );
        }
    }

    private String generateCode() {
        int value = secureRandom.nextInt(1_000_000);
        return String.format("%0" + CODE_LENGTH + "d", value);
    }

    private EmailVerificationChallengeResponse toChallengeResponse(EmailVerification verification, Instant now) {
        long expiresIn = Math.max(0, Duration.between(now, verification.getExpiresAt()).toSeconds());
        long resendCooldown = Math.max(0, RESEND_COOLDOWN.toSeconds() - Duration.between(verification.getCreatedAt(), now).toSeconds());
        return new EmailVerificationChallengeResponse(verification.getId(), expiresIn, resendCooldown);
    }
}
