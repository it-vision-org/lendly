package com.lendly.contact.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.lendly.contact.domain.Contact;

public interface ContactRepository extends JpaRepository<Contact, UUID> {

    List<Contact> findAllByUserIdOrderByNameAsc(UUID userId);

    Optional<Contact> findByIdAndUserId(UUID id, UUID userId);
}
