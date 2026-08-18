package com.lendly.common.security;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

import javax.crypto.spec.SecretKeySpec;

import org.springframework.stereotype.Service;

import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;

/**
 * Issues short-lived, stateless access tokens (signed JWT, verified by the
 * OAuth2 resource-server JWT decoder). Refresh tokens are opaque and DB-backed
 * (see {@link com.lendly.identity.service.AuthService}) so they can be
 * revoked/rotated, unlike a self-contained JWT.
 */
@Service
public class JwtTokenService {

    private static final String EMAIL_CLAIM = "email";
    private static final String FULL_NAME_CLAIM = "fullName";

    private final AppSecurityProperties properties;

    public JwtTokenService(AppSecurityProperties properties) {
        this.properties = properties;
    }

    public String issueAccessToken(UUID userId, String email, String fullName) {
        Instant now = Instant.now();

        JWTClaimsSet claims = new JWTClaimsSet.Builder()
            .subject(userId.toString())
            .claim(EMAIL_CLAIM, email)
            .claim(FULL_NAME_CLAIM, fullName)
            .issueTime(Date.from(now))
            .expirationTime(Date.from(now.plus(properties.accessTokenExpiration())))
            .build();

        return sign(claims, properties.accessTokenSecret());
    }

    static byte[] derive256BitKey(String secret) {
        try {
            return MessageDigest.getInstance("SHA-256").digest(secret.getBytes(StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }

    private String sign(JWTClaimsSet claims, String secret) {
        try {
            SignedJWT signedJWT = new SignedJWT(new JWSHeader(JWSAlgorithm.HS256), claims);
            signedJWT.sign(new MACSigner(derive256BitKey(secret)));
            return signedJWT.serialize();
        } catch (JOSEException e) {
            throw new IllegalStateException("Unable to sign JWT", e);
        }
    }

    public static SecretKeySpec secretKeySpec(String secret) {
        return new SecretKeySpec(derive256BitKey(secret), "HmacSHA256");
    }
}
