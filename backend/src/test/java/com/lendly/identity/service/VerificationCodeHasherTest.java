package com.lendly.identity.service;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class VerificationCodeHasherTest {

    private static final String SECRET = "test-secret";

    @Test
    void hashIsDeterministicForTheSameSecretAndCode() {
        assertEquals(
            VerificationCodeHasher.hash(SECRET, "123456"),
            VerificationCodeHasher.hash(SECRET, "123456")
        );
    }

    @Test
    void differentCodesProduceDifferentHashes() {
        assertFalse(
            VerificationCodeHasher.hash(SECRET, "123456").equals(VerificationCodeHasher.hash(SECRET, "654321"))
        );
    }

    @Test
    void matchesSucceedsForTheCorrectCode() {
        String hash = VerificationCodeHasher.hash(SECRET, "482193");
        assertTrue(VerificationCodeHasher.matches(SECRET, "482193", hash));
    }

    @Test
    void matchesFailsForAnIncorrectCode() {
        String hash = VerificationCodeHasher.hash(SECRET, "482193");
        assertFalse(VerificationCodeHasher.matches(SECRET, "000000", hash));
    }
}
