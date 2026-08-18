package com.lendly.identity.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.lendly.common.api.ApiException;
import com.lendly.common.security.AppSecurityProperties;
import com.lendly.common.security.JwtTokenService;
import com.lendly.identity.api.dto.AuthResponse;
import com.lendly.identity.api.dto.UserSummary;
import com.lendly.identity.domain.RefreshToken;
import com.lendly.identity.domain.User;
import com.lendly.identity.repository.RefreshTokenRepository;
import com.lendly.identity.repository.UserRepository;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenService jwtTokenService;
    private final AppSecurityProperties securityProperties;
    private final SecureRandom secureRandom = new SecureRandom();

    public AuthService(
        UserRepository userRepository,
        RefreshTokenRepository refreshTokenRepository,
        PasswordEncoder passwordEncoder,
        JwtTokenService jwtTokenService,
        AppSecurityProperties securityProperties
    ) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenService = jwtTokenService;
        this.securityProperties = securityProperties;
    }

    @Transactional
    public AuthResponse register(String firstName, String lastName, String email, String password, String deviceInfo) {
        String normalizedEmail = email.trim().toLowerCase();
        if (userRepository.existsByEmail(normalizedEmail)) {
            throw ApiException.conflict("EMAIL_ALREADY_USED", "An account with this email already exists");
        }

        User user = new User(firstName.trim(), lastName.trim(), normalizedEmail, passwordEncoder.encode(password));
        userRepository.save(user);

        return issueTokenPair(user, deviceInfo);
    }

    @Transactional
    public AuthResponse login(String email, String password, String deviceInfo) {
        User user = userRepository.findByEmail(email.trim().toLowerCase())
            .orElseThrow(() -> ApiException.unauthorized("INVALID_CREDENTIALS", "Invalid email or password"));

        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            throw ApiException.unauthorized("INVALID_CREDENTIALS", "Invalid email or password");
        }

        return issueTokenPair(user, deviceInfo);
    }

    @Transactional
    public AuthResponse refresh(String refreshTokenPlain, String deviceInfo) {
        String hash = hash(refreshTokenPlain);
        RefreshToken token = refreshTokenRepository.findByTokenHash(hash)
            .filter(t -> t.isActive(Instant.now()))
            .orElseThrow(() -> ApiException.unauthorized("INVALID_REFRESH_TOKEN", "Refresh token invalid or expired"));

        token.setRevokedAt(Instant.now());
        return issueTokenPair(token.getUser(), deviceInfo);
    }

    @Transactional
    public void logout(String refreshTokenPlain) {
        refreshTokenRepository.findByTokenHash(hash(refreshTokenPlain))
            .ifPresent(token -> token.setRevokedAt(Instant.now()));
    }

    private AuthResponse issueTokenPair(User user, String deviceInfo) {
        String accessToken = jwtTokenService.issueAccessToken(user.getId(), user.getEmail(), user.getFullName());

        String refreshPlain = generateOpaqueToken();
        Instant now = Instant.now();

        RefreshToken refreshToken = new RefreshToken(
            user,
            hash(refreshPlain),
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

    private String generateOpaqueToken() {
        byte[] bytes = new byte[32];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hash(String value) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }
}
