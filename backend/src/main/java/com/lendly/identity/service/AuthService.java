package com.lendly.identity.service;

import java.time.Instant;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.lendly.common.api.ApiException;
import com.lendly.common.security.AppSecurityProperties;
import com.lendly.common.security.JwtTokenService;
import com.lendly.common.security.SecureTokens;
import com.lendly.identity.api.dto.AuthResponse;
import com.lendly.identity.api.dto.EmailVerificationChallengeResponse;
import com.lendly.identity.api.dto.LoginResponse;
import com.lendly.identity.api.dto.UserSummary;
import com.lendly.identity.domain.RefreshToken;
import com.lendly.identity.domain.User;
import com.lendly.identity.domain.VerificationPurpose;
import com.lendly.identity.repository.RefreshTokenRepository;
import com.lendly.identity.repository.UserRepository;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenService jwtTokenService;
    private final AppSecurityProperties securityProperties;
    private final EmailVerificationService emailVerificationService;

    public AuthService(
        UserRepository userRepository,
        RefreshTokenRepository refreshTokenRepository,
        PasswordEncoder passwordEncoder,
        JwtTokenService jwtTokenService,
        AppSecurityProperties securityProperties,
        EmailVerificationService emailVerificationService
    ) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenService = jwtTokenService;
        this.securityProperties = securityProperties;
        this.emailVerificationService = emailVerificationService;
    }

    @Transactional
    public EmailVerificationChallengeResponse register(String fullName, String email, String password, String ipAddress) {
        String normalizedEmail = email.trim().toLowerCase();
        User user = userRepository.findByEmail(normalizedEmail).orElse(null);

        if (user != null && user.getEmailVerifiedAt() != null) {
            throw ApiException.conflict("EMAIL_ALREADY_USED", "An account with this email already exists");
        }

        if (user == null) {
            user = new User(fullName.trim(), normalizedEmail, passwordEncoder.encode(password));
        } else {
            // Abandoned/unverified signup for this email: update the pending
            // account instead of creating a duplicate user row.
            user.setFullName(fullName.trim());
            user.setPasswordHash(passwordEncoder.encode(password));
        }
        userRepository.save(user);

        return emailVerificationService.startVerification(user, VerificationPurpose.EMAIL_VERIFICATION, ipAddress);
    }

    @Transactional
    public UserSummary updateProfile(User user, String fullName) {
        user.setFullName(fullName.trim());
        userRepository.save(user);
        return UserSummary.from(user);
    }

    @Transactional
    public void changePassword(User user, String currentPassword, String newPassword) {
        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            throw ApiException.badRequest("INVALID_CURRENT_PASSWORD", "Current password is incorrect");
        }
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    @Transactional
    public LoginResponse login(String email, String password, String deviceInfo, String ipAddress) {
        User user = userRepository.findByEmail(email.trim().toLowerCase())
            .orElseThrow(() -> ApiException.unauthorized("INVALID_CREDENTIALS", "Invalid email or password"));

        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            throw ApiException.unauthorized("INVALID_CREDENTIALS", "Invalid email or password");
        }

        if (user.getEmailVerifiedAt() == null) {
            EmailVerificationChallengeResponse challenge =
                emailVerificationService.startVerification(user, VerificationPurpose.EMAIL_VERIFICATION, ipAddress);
            return LoginResponse.verificationRequired(challenge);
        }

        return LoginResponse.authenticated(issueTokenPair(user, deviceInfo));
    }

    @Transactional
    public AuthResponse completeVerifiedLogin(User user, String deviceInfo) {
        return issueTokenPair(user, deviceInfo);
    }

    /**
     * Starts (or restarts) a password-reset code for {@code email}. Silently
     * does nothing if no account matches, so callers must always return the
     * same generic response regardless of whether an account exists.
     */
    @Transactional
    public void requestPasswordReset(String email, String ipAddress) {
        userRepository.findByEmail(email.trim().toLowerCase())
            .ifPresent(user -> emailVerificationService.startVerification(user, VerificationPurpose.PASSWORD_RESET, ipAddress));
    }

    @Transactional
    public AuthResponse completePasswordReset(String resetTokenPlain, String newPassword, String confirmPassword) {
        if (!newPassword.equals(confirmPassword)) {
            throw ApiException.badRequest("PASSWORD_MISMATCH", "The passwords don't match.");
        }

        User user = emailVerificationService.consumeResetToken(resetTokenPlain);

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        if (user.getEmailVerifiedAt() == null) {
            user.setEmailVerifiedAt(Instant.now());
        }
        userRepository.save(user);

        refreshTokenRepository.revokeAllForUser(user.getId(), Instant.now());

        return issueTokenPair(user, "password-reset");
    }

    @Transactional
    public AuthResponse refresh(String refreshTokenPlain, String deviceInfo) {
        String hash = SecureTokens.hash(refreshTokenPlain);
        RefreshToken token = refreshTokenRepository.findByTokenHash(hash)
            .filter(t -> t.isActive(Instant.now()))
            .orElseThrow(() -> ApiException.unauthorized("INVALID_REFRESH_TOKEN", "Refresh token invalid or expired"));

        token.setRevokedAt(Instant.now());
        return issueTokenPair(token.getUser(), deviceInfo);
    }

    @Transactional
    public void logout(String refreshTokenPlain) {
        refreshTokenRepository.findByTokenHash(SecureTokens.hash(refreshTokenPlain))
            .ifPresent(token -> token.setRevokedAt(Instant.now()));
    }

    private AuthResponse issueTokenPair(User user, String deviceInfo) {
        String accessToken = jwtTokenService.issueAccessToken(user.getId(), user.getEmail(), user.getFullName());

        String refreshPlain = SecureTokens.generate();
        Instant now = Instant.now();

        RefreshToken refreshToken = new RefreshToken(
            user,
            SecureTokens.hash(refreshPlain),
            deviceInfo,
            now,
            now.plus(securityProperties.refreshTokenExpiration())
        );
        refreshTokenRepository.save(refreshToken);

        return new AuthResponse(
            accessToken,
            refreshPlain,
            securityProperties.accessTokenExpiration().toSeconds(),
            UserSummary.from(user)
        );
    }
}
