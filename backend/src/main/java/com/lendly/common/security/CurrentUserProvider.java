package com.lendly.common.security;

import java.util.UUID;

import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

import com.lendly.common.api.ApiException;
import com.lendly.identity.domain.User;
import com.lendly.identity.repository.UserRepository;

@Component
public class CurrentUserProvider {

    private final UserRepository userRepository;

    public CurrentUserProvider(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User require(Jwt jwt) {
        if (jwt == null) {
            // Should be unreachable in practice (Spring Security would already have
            // rejected the request), but a misconfigured permitAll path must fail
            // as a clean 401 here rather than NPE into a 500.
            throw ApiException.unauthorized("UNAUTHENTICATED", "Authentication is required");
        }

        UUID userId = UUID.fromString(jwt.getSubject());
        return userRepository.findById(userId)
            .orElseThrow(() -> ApiException.unauthorized("USER_NOT_FOUND", "Authenticated user no longer exists"));
    }
}
