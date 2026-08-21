package com.lendly.identity.service;

import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.util.HexFormat;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/**
 * HMAC-SHA256 hashing for 6-digit verification codes. A bare hash of a
 * 6-digit code (1,000,000 possibilities) would be trivially brute-forceable
 * offline if the database leaked; HMAC-ing with a server-only secret prevents
 * that without needing per-code salts.
 */
final class VerificationCodeHasher {

    private VerificationCodeHasher() {
    }

    static String hash(String secret, String code) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] digest = mac.doFinal(code.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("HMAC-SHA256 not available", e);
        }
    }

    static boolean matches(String secret, String code, String expectedHash) {
        String actualHash = hash(secret, code);
        return MessageDigest.isEqual(
            actualHash.getBytes(StandardCharsets.UTF_8),
            expectedHash.getBytes(StandardCharsets.UTF_8)
        );
    }
}
