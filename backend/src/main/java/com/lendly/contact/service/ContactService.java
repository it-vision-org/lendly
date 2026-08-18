package com.lendly.contact.service;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.lendly.common.api.ApiException;
import com.lendly.contact.api.dto.ContactRequest;
import com.lendly.contact.api.dto.ContactResponse;
import com.lendly.contact.domain.Contact;
import com.lendly.contact.mapper.ContactMapper;
import com.lendly.contact.repository.ContactRepository;
import com.lendly.identity.domain.User;
import com.lendly.transaction.domain.TransactionType;
import com.lendly.transaction.repository.TransactionRepository;

@Service
public class ContactService {

    private static final BigDecimal ZERO = BigDecimal.ZERO.setScale(2);

    private final ContactRepository contactRepository;
    private final TransactionRepository transactionRepository;
    private final ContactMapper mapper;

    public ContactService(ContactRepository contactRepository, TransactionRepository transactionRepository, ContactMapper mapper) {
        this.contactRepository = contactRepository;
        this.transactionRepository = transactionRepository;
        this.mapper = mapper;
    }

    @Transactional(readOnly = true)
    public List<ContactResponse> list(User user) {
        Map<UUID, BigDecimal> owedToMe = balancesByContact(user, TransactionType.LENT);
        Map<UUID, BigDecimal> iOwe = balancesByContact(user, TransactionType.BORROWED);

        return contactRepository.findAllByUserIdOrderByNameAsc(user.getId()).stream()
            .map(contact -> mapper.toResponse(
                contact,
                owedToMe.getOrDefault(contact.getId(), ZERO),
                iOwe.getOrDefault(contact.getId(), ZERO)
            ))
            .toList();
    }

    @Transactional(readOnly = true)
    public ContactResponse get(User user, UUID id) {
        Contact contact = requireOwned(user, id);
        BigDecimal owedToMe = transactionRepository.sumRemainingByContactAndType(user.getId(), TransactionType.LENT).stream()
            .filter(b -> b.getContactId().equals(id)).findFirst().map(TransactionRepository.ContactBalance::getTotal).orElse(ZERO);
        BigDecimal iOwe = transactionRepository.sumRemainingByContactAndType(user.getId(), TransactionType.BORROWED).stream()
            .filter(b -> b.getContactId().equals(id)).findFirst().map(TransactionRepository.ContactBalance::getTotal).orElse(ZERO);
        return mapper.toResponse(contact, owedToMe, iOwe);
    }

    @Transactional
    public ContactResponse create(User user, ContactRequest request) {
        Contact contact = new Contact(user, request.name(), request.phone(), request.email(), request.notes());
        contactRepository.saveAndFlush(contact);
        return mapper.toResponse(contact, ZERO, ZERO);
    }

    @Transactional
    public ContactResponse update(User user, UUID id, ContactRequest request) {
        Contact contact = requireOwned(user, id);
        contact.setName(request.name());
        contact.setPhone(request.phone());
        contact.setEmail(request.email());
        contact.setNotes(request.notes());
        return get(user, id);
    }

    @Transactional
    public void delete(User user, UUID id) {
        Contact contact = requireOwned(user, id);
        contactRepository.delete(contact);
    }

    private Map<UUID, BigDecimal> balancesByContact(User user, TransactionType type) {
        Map<UUID, BigDecimal> map = new HashMap<>();
        transactionRepository.sumRemainingByContactAndType(user.getId(), type)
            .forEach(balance -> map.put(balance.getContactId(), balance.getTotal()));
        return map;
    }

    private Contact requireOwned(User user, UUID id) {
        return contactRepository.findByIdAndUserId(id, user.getId())
            .orElseThrow(() -> ApiException.notFound("CONTACT_NOT_FOUND", "Contact not found"));
    }
}
