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
import com.lendly.common.security.JwtTokenService;
import com.lendly.identity.api.dto.EmailVerificationChallengeResponse;
import com.lendly.identity.api.dto.LoginResponse;
import com.lendly.identity.domain.User;
import com.lendly.identity.repository.RefreshTokenRepository;
import com.lendly.identity.repository.UserRepository;

import org.springframework.security.crypto.password.PasswordEncoder;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private RefreshTokenRepository refreshTokenRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtTokenService jwtTokenService;

    @Mock
    private EmailVerificationService emailVerificationService;

    private AuthService authService;

    @BeforeEach
    void setUp() {
        AppSecurityProperties securityProperties = new AppSecurityProperties(
            Duration.ofMinutes(15), Duration.ofDays(30), "access-secret", "refresh-secret", "verification-secret"
        );
        authService = new AuthService(
            userRepository, refreshTokenRepository, passwordEncoder, jwtTokenService, securityProperties, emailVerificationService
        );
    }

    @Test
    void loginWithCorrectPasswordButUnverifiedEmailDoesNotIssueTokens() {
        User user = new User("Ahmed", "Zouaghi", "ahmed@example.com", "hashed-password");
        user.setId(UUID.randomUUID());

        when(userRepository.findByEmail("ahmed@example.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("correct-password", "hashed-password")).thenReturn(true);
        EmailVerificationChallengeResponse challenge = new EmailVerificationChallengeResponse(UUID.randomUUID(), 600, 60);
        when(emailVerificationService.startVerification(user, "127.0.0.1")).thenReturn(challenge);

        LoginResponse response = authService.login("ahmed@example.com", "correct-password", "flutter-app", "127.0.0.1");

        assertNull(response.auth());
        assertNotNull(response.verification());
        assertEquals(challenge.verificationId(), response.verification().verificationId());
        verify(refreshTokenRepository, never()).save(any());
        verify(jwtTokenService, never()).issueAccessToken(any(), anyString(), anyString());
    }

    @Test
    void loginWithCorrectPasswordAndVerifiedEmailIssuesTokens() {
        User user = new User("Ahmed", "Zouaghi", "ahmed@example.com", "hashed-password");
        user.setId(UUID.randomUUID());
        user.setEmailVerifiedAt(Instant.now());

        when(userRepository.findByEmail("ahmed@example.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("correct-password", "hashed-password")).thenReturn(true);
        when(jwtTokenService.issueAccessToken(eq(user.getId()), eq(user.getEmail()), anyString())).thenReturn("access-token");

        LoginResponse response = authService.login("ahmed@example.com", "correct-password", "flutter-app", "127.0.0.1");

        assertNotNull(response.auth());
        assertNull(response.verification());
        assertEquals("access-token", response.auth().accessToken());
        verify(refreshTokenRepository).save(any());
    }

    @Test
    void loginWithWrongPasswordFailsRegardlessOfVerificationState() {
        User user = new User("Ahmed", "Zouaghi", "ahmed@example.com", "hashed-password");
        when(userRepository.findByEmail("ahmed@example.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("wrong-password", "hashed-password")).thenReturn(false);

        ApiException exception = assertThrows(
            ApiException.class,
            () -> authService.login("ahmed@example.com", "wrong-password", "flutter-app", "127.0.0.1")
        );

        assertEquals("INVALID_CREDENTIALS", exception.getCode());
        verify(refreshTokenRepository, never()).save(any());
    }
}
