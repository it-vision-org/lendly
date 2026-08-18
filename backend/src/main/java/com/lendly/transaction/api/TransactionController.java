package com.lendly.transaction.api;

import java.util.List;
import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.lendly.common.security.CurrentUserProvider;
import com.lendly.identity.domain.User;
import com.lendly.transaction.api.dto.RepaymentRequest;
import com.lendly.transaction.api.dto.RepaymentResponse;
import com.lendly.transaction.api.dto.TransactionRequest;
import com.lendly.transaction.api.dto.TransactionResponse;
import com.lendly.transaction.domain.TransactionStatus;
import com.lendly.transaction.domain.TransactionType;
import com.lendly.transaction.service.TransactionService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/transactions")
public class TransactionController {

    private final TransactionService transactionService;
    private final CurrentUserProvider currentUserProvider;

    public TransactionController(TransactionService transactionService, CurrentUserProvider currentUserProvider) {
        this.transactionService = transactionService;
        this.currentUserProvider = currentUserProvider;
    }

    @GetMapping
    public List<TransactionResponse> list(
        @AuthenticationPrincipal Jwt jwt,
        @RequestParam(required = false) TransactionType type,
        @RequestParam(required = false) TransactionStatus status,
        @RequestParam(required = false) UUID contactId
    ) {
        return transactionService.list(currentUserProvider.require(jwt), type, status, contactId);
    }

    @GetMapping("/{id}")
    public TransactionResponse get(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        return transactionService.get(currentUserProvider.require(jwt), id);
    }

    @PostMapping
    public TransactionResponse create(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody TransactionRequest request) {
        return transactionService.create(currentUserProvider.require(jwt), request);
    }

    @PutMapping("/{id}")
    public TransactionResponse update(
        @AuthenticationPrincipal Jwt jwt,
        @PathVariable UUID id,
        @Valid @RequestBody TransactionRequest request
    ) {
        return transactionService.update(currentUserProvider.require(jwt), id, request);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        transactionService.delete(currentUserProvider.require(jwt), id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/repayments")
    public List<RepaymentResponse> listRepayments(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        return transactionService.listRepayments(currentUserProvider.require(jwt), id);
    }

    @PostMapping("/{id}/repayments")
    public RepaymentResponse addRepayment(
        @AuthenticationPrincipal Jwt jwt,
        @PathVariable UUID id,
        @Valid @RequestBody RepaymentRequest request
    ) {
        return transactionService.addRepayment(currentUserProvider.require(jwt), id, request);
    }

    @DeleteMapping("/{id}/repayments/{repaymentId}")
    public ResponseEntity<Void> deleteRepayment(
        @AuthenticationPrincipal Jwt jwt,
        @PathVariable UUID id,
        @PathVariable UUID repaymentId
    ) {
        transactionService.deleteRepayment(currentUserProvider.require(jwt), id, repaymentId);
        return ResponseEntity.noContent().build();
    }
}
