package com.lendly.identity.api;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.lendly.common.security.ClientIpResolver;
import com.lendly.common.security.CurrentUserProvider;
import com.lendly.identity.api.dto.AuthResponse;
import com.lendly.identity.api.dto.ChangePasswordRequest;
import com.lendly.identity.api.dto.EmailVerificationChallengeResponse;
import com.lendly.identity.api.dto.LoginRequest;
import com.lendly.identity.api.dto.LoginResponse;
import com.lendly.identity.api.dto.LogoutRequest;
import com.lendly.identity.api.dto.RefreshRequest;
import com.lendly.identity.api.dto.RegisterRequest;
import com.lendly.identity.api.dto.UpdateProfileRequest;
import com.lendly.identity.api.dto.UserSummary;
import com.lendly.identity.domain.User;
import com.lendly.identity.service.AuthService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final CurrentUserProvider currentUserProvider;

    public AuthController(AuthService authService, CurrentUserProvider currentUserProvider) {
        this.authService = authService;
        this.currentUserProvider = currentUserProvider;
    }

    @PostMapping("/register")
    public EmailVerificationChallengeResponse register(@Valid @RequestBody RegisterRequest request, HttpServletRequest httpRequest) {
        return authService.register(
            request.fullName(),
            request.email(),
            request.password(),
            ClientIpResolver.resolve(httpRequest)
        );
    }

    @PostMapping("/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest request, HttpServletRequest httpRequest) {
        return authService.login(request.email(), request.password(), request.deviceInfo(), ClientIpResolver.resolve(httpRequest));
    }

    @PostMapping("/refresh")
    public AuthResponse refresh(@Valid @RequestBody RefreshRequest request) {
        return authService.refresh(request.refreshToken(), request.deviceInfo());
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@Valid @RequestBody LogoutRequest request) {
        authService.logout(request.refreshToken());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/me")
    public UserSummary me(@AuthenticationPrincipal Jwt jwt) {
        return UserSummary.from(currentUserProvider.require(jwt));
    }

    @PatchMapping("/me")
    public UserSummary updateProfile(@Valid @RequestBody UpdateProfileRequest request, @AuthenticationPrincipal Jwt jwt) {
        User user = currentUserProvider.require(jwt);
        return authService.updateProfile(user, request.fullName());
    }

    @PatchMapping("/me/password")
    public ResponseEntity<Void> changePassword(@Valid @RequestBody ChangePasswordRequest request, @AuthenticationPrincipal Jwt jwt) {
        User user = currentUserProvider.require(jwt);
        authService.changePassword(user, request.currentPassword(), request.newPassword());
        return ResponseEntity.noContent().build();
    }
}
