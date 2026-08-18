package com.lendly.contact.api;

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
import org.springframework.web.bind.annotation.RestController;

import com.lendly.common.security.CurrentUserProvider;
import com.lendly.contact.api.dto.ContactRequest;
import com.lendly.contact.api.dto.ContactResponse;
import com.lendly.contact.service.ContactService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/contacts")
public class ContactController {

    private final ContactService contactService;
    private final CurrentUserProvider currentUserProvider;

    public ContactController(ContactService contactService, CurrentUserProvider currentUserProvider) {
        this.contactService = contactService;
        this.currentUserProvider = currentUserProvider;
    }

    @GetMapping
    public List<ContactResponse> list(@AuthenticationPrincipal Jwt jwt) {
        return contactService.list(currentUserProvider.require(jwt));
    }

    @GetMapping("/{id}")
    public ContactResponse get(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        return contactService.get(currentUserProvider.require(jwt), id);
    }

    @PostMapping
    public ContactResponse create(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody ContactRequest request) {
        return contactService.create(currentUserProvider.require(jwt), request);
    }

    @PutMapping("/{id}")
    public ContactResponse update(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id, @Valid @RequestBody ContactRequest request) {
        return contactService.update(currentUserProvider.require(jwt), id, request);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        contactService.delete(currentUserProvider.require(jwt), id);
        return ResponseEntity.noContent().build();
    }
}
