package com.lendly.identity.service;

import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.lendly.common.api.ApiException;
import com.lendly.common.security.AppSecurityProperties;
import com.lendly.common.security.SecureTokens;
import com.lendly.email.EmailService;
import com.lendly.identity.api.dto.EmailVerificationChallengeResponse;
import com.lendly.identity.domain.EmailVerification;
import com.lendly.identity.domain.User;
import com.lendly.identity.domain.VerificationPurpose;
import com.lendly.identity.repository.EmailVerificationRepository;
import com.lendly.identity.repository.UserRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EmailVerificationServiceTest {

    private static final String SECRET = "test-secret";

    @Mock
    private EmailVerificationRepository repository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private EmailService emailService;

    private EmailVerificationService service;
    private User user;

    @BeforeEach
    void setUp() {
        AppSecurityProperties securityProperties = new AppSecurityProperties(
            Duration.ofMinutes(15), Duration.ofDays(30), "access-secret", "refresh-secret", SECRET
        );
        service = new EmailVerificationService(repository, userRepository, emailService, securityProperties);

        // Real Hibernate assigns GenerationType.UUID ids synchronously at
        // persist() time, before save() returns; simulate that here since the
        // mocked repository otherwise leaves newly-constructed entities' ids null.
        lenient().when(repository.save(any(EmailVerification.class))).thenAnswer(invocation -> {
            EmailVerification saved = invocation.getArgument(0);
            if (saved.getId() == null) {
                saved.setId(UUID.randomUUID());
            }
            return saved;
        });

        user = new User("Ahmed Zouaghi", "ahmed@example.com", "hashed-password");
        user.setId(UUID.randomUUID());
    }

    private EmailVerification fixture(
        VerificationPurpose purpose, String code, Instant expiresAt, int attempts, Instant verifiedAt, Instant createdAt
    ) {
        EmailVerification verification = new EmailVerification(
            user, purpose, VerificationCodeHasher.hash(SECRET, code), expiresAt, "127.0.0.1"
        );
        verification.setId(UUID.randomUUID());
        verification.setAttempts(attempts);
        verification.setVerifiedAt(verifiedAt);
        verification.setCreatedAt(createdAt);
        return verification;
    }

    @Test
    void correctCodeSucceedsAndMarksUserVerified() {
        EmailVerification verification = fixture(
            VerificationPurpose.EMAIL_VERIFICATION, "482193", Instant.now().plusSeconds(600), 0, null, Instant.now()
        );
        when(repository.findById(verification.getId())).thenReturn(Optional.of(verification));

        User result = service.verifyCode(verification.getId(), "482193");

        assertNotNull(result.getEmailVerifiedAt());
        assertNotNull(verification.getVerifiedAt());
        verify(userRepository).save(user);
    }

    @Test
    void incorrectCodeFailsAndIncrementsAttempts() {
        EmailVerification verification = fixture(
            VerificationPurpose.EMAIL_VERIFICATION, "482193", Instant.now().plusSeconds(600), 0, null, Instant.now()
        );
        when(repository.findById(verification.getId())).thenReturn(Optional.of(verification));

        ApiException exception = assertThrows(ApiException.class, () -> service.verifyCode(verification.getId(), "000000"));

        assertEquals("INVALID_CODE", exception.getCode());
        assertEquals(1, verification.getAttempts());
    }

    @Test
    void expiredCodeFails() {
        EmailVerification verification = fixture(
            VerificationPurpose.EMAIL_VERIFICATION, "482193", Instant.now().minusSeconds(1), 0, null, Instant.now()
        );
        when(repository.findById(verification.getId())).thenReturn(Optional.of(verification));

        ApiException exception = assertThrows(ApiException.class, () -> service.verifyCode(verification.getId(), "482193"));

        assertEquals("CODE_EXPIRED", exception.getCode());
    }

    @Test
    void reusedAlreadyVerifiedCodeFails() {
        EmailVerification verification = fixture(
            VerificationPurpose.EMAIL_VERIFICATION, "482193", Instant.now().plusSeconds(600), 0, Instant.now(), Instant.now()
        );
        when(repository.findById(verification.getId())).thenReturn(Optional.of(verification));

        ApiException exception = assertThrows(ApiException.class, () -> service.verifyCode(verification.getId(), "482193"));

        assertEquals("ALREADY_VERIFIED", exception.getCode());
    }

    @Test
    void tooManyAttemptsBlocksEvenTheCorrectCode() {
        EmailVerification verification = fixture(
            VerificationPurpose.EMAIL_VERIFICATION, "482193", Instant.now().plusSeconds(600), 5, null, Instant.now()
        );
        when(repository.findById(verification.getId())).thenReturn(Optional.of(verification));

        ApiException exception = assertThrows(ApiException.class, () -> service.verifyCode(verification.getId(), "482193"));

        assertEquals("TOO_MANY_ATTEMPTS", exception.getCode());
    }

    @Test
    void aPasswordResetCodeCannotBeUsedToVerifyEmail() {
        EmailVerification verification = fixture(
            VerificationPurpose.PASSWORD_RESET, "482193", Instant.now().plusSeconds(600), 0, null, Instant.now()
        );
        when(repository.findById(verification.getId())).thenReturn(Optional.of(verification));

        ApiException exception = assertThrows(ApiException.class, () -> service.verifyCode(verification.getId(), "482193"));

        assertEquals("INVALID_CODE", exception.getCode());
    }

    @Test
    void startVerificationWithNoPriorSendSendsACode() {
        when(repository.findFirstByUserIdAndPurposeOrderByCreatedAtDesc(user.getId(), VerificationPurpose.EMAIL_VERIFICATION))
            .thenReturn(Optional.empty());

        EmailVerificationChallengeResponse response =
            service.startVerification(user, VerificationPurpose.EMAIL_VERIFICATION, "127.0.0.1");

        assertNotNull(response.verificationId());
        verify(repository).expireActiveForUser(eq(user.getId()), eq(VerificationPurpose.EMAIL_VERIFICATION), any());
        verify(emailService).send(eq(user.getEmail()), anyString(), anyString(), anyString());
    }

    @Test
    void startVerificationWithinCooldownReturnsExistingChallengeWithoutSendingAgain() {
        EmailVerification recent = fixture(
            VerificationPurpose.EMAIL_VERIFICATION, "111111", Instant.now().plusSeconds(600), 0, null, Instant.now()
        );
        when(repository.findFirstByUserIdAndPurposeOrderByCreatedAtDesc(user.getId(), VerificationPurpose.EMAIL_VERIFICATION))
            .thenReturn(Optional.of(recent));

        EmailVerificationChallengeResponse response =
            service.startVerification(user, VerificationPurpose.EMAIL_VERIFICATION, "127.0.0.1");

        assertEquals(recent.getId(), response.verificationId());
        verifyNoInteractions(emailService);
        verify(repository, never()).expireActiveForUser(any(), any(), any());
    }

    @Test
    void startVerificationAfterCooldownExpiresInvalidatesOldCodeAndSendsANewOne() {
        EmailVerification old = fixture(
            VerificationPurpose.EMAIL_VERIFICATION, "111111", Instant.now().plusSeconds(600), 0, null,
            Instant.now().minusSeconds(120)
        );
        when(repository.findFirstByUserIdAndPurposeOrderByCreatedAtDesc(user.getId(), VerificationPurpose.EMAIL_VERIFICATION))
            .thenReturn(Optional.of(old));

        EmailVerificationChallengeResponse response =
            service.startVerification(user, VerificationPurpose.EMAIL_VERIFICATION, "127.0.0.1");

        assertNotNull(response.verificationId());
        verify(repository).expireActiveForUser(eq(user.getId()), eq(VerificationPurpose.EMAIL_VERIFICATION), any());
        verify(emailService).send(eq(user.getEmail()), anyString(), anyString(), anyString());
    }

    @Test
    void resendingForOnePurposeDoesNotInvalidateAnUnrelatedActivePurpose() {
        // A resend for PASSWORD_RESET must only ever touch PASSWORD_RESET rows.
        when(repository.findFirstByUserIdAndPurposeOrderByCreatedAtDesc(user.getId(), VerificationPurpose.PASSWORD_RESET))
            .thenReturn(Optional.empty());

        service.startVerification(user, VerificationPurpose.PASSWORD_RESET, "127.0.0.1");

        verify(repository).expireActiveForUser(eq(user.getId()), eq(VerificationPurpose.PASSWORD_RESET), any());
        verify(repository, never()).expireActiveForUser(any(), eq(VerificationPurpose.EMAIL_VERIFICATION), any());
    }

    @Test
    void verifyPasswordResetCodeSucceedsAndReturnsAResetToken() {
        EmailVerification verification = fixture(
            VerificationPurpose.PASSWORD_RESET, "482193", Instant.now().plusSeconds(600), 0, null, Instant.now()
        );
        when(userRepository.findByEmail(user.getEmail())).thenReturn(Optional.of(user));
        when(repository.findFirstByUserIdAndPurposeOrderByCreatedAtDesc(user.getId(), VerificationPurpose.PASSWORD_RESET))
            .thenReturn(Optional.of(verification));

        String resetToken = service.verifyPasswordResetCode(user.getEmail(), "482193");

        assertNotNull(resetToken);
        assertNotNull(verification.getResetTokenHash());
        assertNotEquals(resetToken, verification.getResetTokenHash());
        assertNotNull(verification.getVerifiedAt());
    }

    @Test
    void verifyPasswordResetCodeForAnUnknownEmailFailsLikeAWrongCode() {
        when(userRepository.findByEmail("nobody@example.com")).thenReturn(Optional.empty());

        ApiException exception =
            assertThrows(ApiException.class, () -> service.verifyPasswordResetCode("nobody@example.com", "482193"));

        assertEquals("INVALID_CODE", exception.getCode());
        assertEquals(400, exception.getStatus().value());
    }

    @Test
    void anEmailVerificationCodeCannotBeUsedToResetPassword() {
        EmailVerification verification = fixture(
            VerificationPurpose.EMAIL_VERIFICATION, "482193", Instant.now().plusSeconds(600), 0, null, Instant.now()
        );
        when(userRepository.findByEmail(user.getEmail())).thenReturn(Optional.of(user));
        when(repository.findFirstByUserIdAndPurposeOrderByCreatedAtDesc(user.getId(), VerificationPurpose.PASSWORD_RESET))
            .thenReturn(Optional.of(verification));

        ApiException exception =
            assertThrows(ApiException.class, () -> service.verifyPasswordResetCode(user.getEmail(), "482193"));

        assertEquals("INVALID_CODE", exception.getCode());
    }

    @Test
    void consumeResetTokenSucceedsOnceAndFailsOnASecondAttempt() {
        EmailVerification verification = fixture(
            VerificationPurpose.PASSWORD_RESET, "482193", Instant.now().plusSeconds(600), 0, Instant.now(), Instant.now()
        );
        verification.setResetTokenHash(SecureTokens.hash("plain-token"));
        verification.setResetTokenExpiresAt(Instant.now().plusSeconds(600));
        when(repository.findByResetTokenHash(SecureTokens.hash("plain-token")))
            .thenReturn(Optional.of(verification));

        User result = service.consumeResetToken("plain-token");

        assertEquals(user.getId(), result.getId());
        assertNotNull(verification.getResetTokenConsumedAt());

        // A second attempt against the same (now-consumed) row must fail.
        ApiException exception = assertThrows(ApiException.class, () -> service.consumeResetToken("plain-token"));
        assertEquals("INVALID_RESET_TOKEN", exception.getCode());
    }

    @Test
    void consumeResetTokenFailsForAnExpiredToken() {
        EmailVerification verification = fixture(
            VerificationPurpose.PASSWORD_RESET, "482193", Instant.now().plusSeconds(600), 0, Instant.now(), Instant.now()
        );
        verification.setResetTokenHash(SecureTokens.hash("plain-token"));
        verification.setResetTokenExpiresAt(Instant.now().minusSeconds(1));
        when(repository.findByResetTokenHash(SecureTokens.hash("plain-token")))
            .thenReturn(Optional.of(verification));

        ApiException exception = assertThrows(ApiException.class, () -> service.consumeResetToken("plain-token"));

        assertEquals("INVALID_RESET_TOKEN", exception.getCode());
    }

    @Test
    void consumeResetTokenFailsForAnUnknownToken() {
        when(repository.findByResetTokenHash(any())).thenReturn(Optional.empty());

        ApiException exception = assertThrows(ApiException.class, () -> service.consumeResetToken("random-unknown-token"));

        assertEquals("INVALID_RESET_TOKEN", exception.getCode());
    }
}
