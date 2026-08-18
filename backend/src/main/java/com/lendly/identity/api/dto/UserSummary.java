package com.lendly.identity.api.dto;

import java.util.UUID;

import com.lendly.identity.domain.User;

public record UserSummary(
    UUID id,
    String firstName,
    String lastName,
    String email
) {
    public static UserSummary from(User user) {
        return new UserSummary(user.getId(), user.getFirstName(), user.getLastName(), user.getEmail());
    }
}
