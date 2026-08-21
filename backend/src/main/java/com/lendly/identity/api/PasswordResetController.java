package com.lendly.identity.api;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.lendly.common.security.ClientIpResolver;
import com.lendly.identity.api.dto.AuthResponse;
import com.lendly.identity.api.dto.CompletePasswordResetRequest;
import com.lendly.identity.api.dto.MessageResponse;
import com.lendly.identity.api.dto.PasswordResetTokenResponse;
import com.lendly.identity.api.dto.RequestPasswordResetRequest;
import com.lendly.identity.api.dto.VerifyPasswordResetRequest;
import com.lendly.identity.service.AuthService;
import com.lendly.identity.service.EmailVerificationService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;

/**
 * Every response here is deliberately shaped to never reveal whether an
 * email belongs to an account: {@code /request} and {@code /resend} always
 * return the same fixed message, and {@code /verify} throws the exact same
 * error for "no such account" as it does for "wrong code".
 */
@RestController
@RequestMapping("/api/auth/password-reset")
public class PasswordResetController {

    private static final MessageResponse GENERIC_RESPONSE =
        new MessageResponse("If an account exists for this email, a verification code has been sent.");

    private final AuthService authService;
    private final EmailVerificationService emailVerificationService;

    public PasswordResetController(AuthService authService, EmailVerificationService emailVerificationService) {
        this.authService = authService;
        this.emailVerificationService = emailVerificationService;
    }

    @PostMapping("/request")
    public MessageResponse request(@Valid @RequestBody RequestPasswordResetRequest request, HttpServletRequest httpRequest) {
        authService.requestPasswordReset(request.email(), ClientIpResolver.resolve(httpRequest));
        return GENERIC_RESPONSE;
    }

    @PostMapping("/resend")
    public MessageResponse resend(@Valid @RequestBody RequestPasswordResetRequest request, HttpServletRequest httpRequest) {
        authService.requestPasswordReset(request.email(), ClientIpResolver.resolve(httpRequest));
        return GENERIC_RESPONSE;
    }

    @PostMapping("/verify")
    public PasswordResetTokenResponse verify(@Valid @RequestBody VerifyPasswordResetRequest request) {
        String resetToken = emailVerificationService.verifyPasswordResetCode(request.email(), request.code());
        return new PasswordResetTokenResponse(resetToken);
    }

    @PostMapping("/complete")
    public AuthResponse complete(@Valid @RequestBody CompletePasswordResetRequest request) {
        return authService.completePasswordReset(request.resetToken(), request.newPassword(), request.confirmPassword());
    }
}
