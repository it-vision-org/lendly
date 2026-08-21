package com.lendly.identity.api;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.lendly.common.security.ClientIpResolver;
import com.lendly.identity.api.dto.AuthResponse;
import com.lendly.identity.api.dto.EmailVerificationChallengeResponse;
import com.lendly.identity.api.dto.ResendVerificationRequest;
import com.lendly.identity.api.dto.VerifyEmailRequest;
import com.lendly.identity.domain.User;
import com.lendly.identity.service.AuthService;
import com.lendly.identity.service.EmailVerificationService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/auth/email-verification")
public class EmailVerificationController {

    private final EmailVerificationService emailVerificationService;
    private final AuthService authService;

    public EmailVerificationController(EmailVerificationService emailVerificationService, AuthService authService) {
        this.emailVerificationService = emailVerificationService;
        this.authService = authService;
    }

    @PostMapping("/verify")
    public AuthResponse verify(@Valid @RequestBody VerifyEmailRequest request) {
        User user = emailVerificationService.verifyCode(request.verificationId(), request.code());
        return authService.completeVerifiedLogin(user, request.deviceInfo());
    }

    @PostMapping("/resend")
    public EmailVerificationChallengeResponse resend(@Valid @RequestBody ResendVerificationRequest request, HttpServletRequest httpRequest) {
        return emailVerificationService.resend(request.verificationId(), ClientIpResolver.resolve(httpRequest));
    }
}
