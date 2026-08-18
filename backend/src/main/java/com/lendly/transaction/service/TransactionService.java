package com.lendly.transaction.service;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.lendly.common.api.ApiException;
import com.lendly.contact.domain.Contact;
import com.lendly.contact.repository.ContactRepository;
import com.lendly.identity.domain.User;
import com.lendly.transaction.api.dto.RepaymentRequest;
import com.lendly.transaction.api.dto.RepaymentResponse;
import com.lendly.transaction.api.dto.TransactionRequest;
import com.lendly.transaction.api.dto.TransactionResponse;
import com.lendly.transaction.domain.Repayment;
import com.lendly.transaction.domain.Transaction;
import com.lendly.transaction.domain.TransactionStatus;
import com.lendly.transaction.domain.TransactionType;
import com.lendly.transaction.mapper.TransactionMapper;
import com.lendly.transaction.repository.RepaymentRepository;
import com.lendly.transaction.repository.TransactionRepository;

@Service
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final RepaymentRepository repaymentRepository;
    private final ContactRepository contactRepository;
    private final TransactionMapper mapper;

    public TransactionService(
        TransactionRepository transactionRepository,
        RepaymentRepository repaymentRepository,
        ContactRepository contactRepository,
        TransactionMapper mapper
    ) {
        this.transactionRepository = transactionRepository;
        this.repaymentRepository = repaymentRepository;
        this.contactRepository = contactRepository;
        this.mapper = mapper;
    }

    @Transactional(readOnly = true)
    public List<TransactionResponse> list(User user, TransactionType type, TransactionStatus status, UUID contactId) {
        return transactionRepository.search(user.getId(), type, status, contactId).stream()
            .map(mapper::toResponse)
            .toList();
    }

    @Transactional(readOnly = true)
    public TransactionResponse get(User user, UUID id) {
        return mapper.toResponse(requireOwnedTransaction(user, id));
    }

    @Transactional
    public TransactionResponse create(User user, TransactionRequest request) {
        Contact contact = requireOwnedContact(user, request.contactId());
        String currency = request.currency() == null || request.currency().isBlank() ? "TND" : request.currency();

        Transaction transaction = new Transaction(
            user,
            contact,
            request.type(),
            request.amount(),
            currency,
            request.description(),
            request.transactionDate()
        );

        return mapper.toResponse(transactionRepository.saveAndFlush(transaction));
    }

    @Transactional
    public TransactionResponse update(User user, UUID id, TransactionRequest request) {
        Transaction transaction = requireOwnedTransaction(user, id);
        Contact contact = requireOwnedContact(user, request.contactId());

        BigDecimal totalPaid = transaction.getOriginalAmount().subtract(transaction.getRemainingAmount());
        BigDecimal newRemaining = request.amount().subtract(totalPaid);
        if (newRemaining.signum() < 0) {
            throw ApiException.badRequest(
                "AMOUNT_BELOW_REPAID_TOTAL",
                "The new amount cannot be less than the total already repaid"
            );
        }

        transaction.setContact(contact);
        transaction.setType(request.type());
        transaction.setOriginalAmount(request.amount());
        transaction.setRemainingAmount(newRemaining);
        transaction.setCurrency(request.currency() == null || request.currency().isBlank() ? "TND" : request.currency());
        transaction.setDescription(request.description());
        transaction.setTransactionDate(request.transactionDate());
        transaction.setStatus(statusFor(newRemaining, request.amount()));

        return mapper.toResponse(transactionRepository.saveAndFlush(transaction));
    }

    @Transactional
    public void delete(User user, UUID id) {
        Transaction transaction = requireOwnedTransaction(user, id);
        transactionRepository.delete(transaction);
    }

    @Transactional(readOnly = true)
    public List<RepaymentResponse> listRepayments(User user, UUID transactionId) {
        requireOwnedTransaction(user, transactionId);
        return repaymentRepository.findAllByTransactionIdOrderByPaymentDateDesc(transactionId).stream()
            .map(mapper::toResponse)
            .toList();
    }

    @Transactional
    public RepaymentResponse addRepayment(User user, UUID transactionId, RepaymentRequest request) {
        Transaction transaction = requireOwnedTransaction(user, transactionId);

        if (request.amount().compareTo(transaction.getRemainingAmount()) > 0) {
            throw ApiException.badRequest(
                "REPAYMENT_EXCEEDS_REMAINING",
                "Repayment amount cannot exceed the remaining balance of " + transaction.getRemainingAmount()
            );
        }

        Repayment repayment = new Repayment(transaction, request.amount(), request.paymentDate(), request.notes());
        repaymentRepository.saveAndFlush(repayment);

        BigDecimal newRemaining = transaction.getRemainingAmount().subtract(request.amount());
        transaction.setRemainingAmount(newRemaining);
        transaction.setStatus(statusFor(newRemaining, transaction.getOriginalAmount()));

        return mapper.toResponse(repayment);
    }

    @Transactional
    public void deleteRepayment(User user, UUID transactionId, UUID repaymentId) {
        Transaction transaction = requireOwnedTransaction(user, transactionId);
        Repayment repayment = repaymentRepository.findByIdAndTransactionId(repaymentId, transactionId)
            .orElseThrow(() -> ApiException.notFound("REPAYMENT_NOT_FOUND", "Repayment not found"));

        BigDecimal newRemaining = transaction.getRemainingAmount().add(repayment.getAmount());
        if (newRemaining.compareTo(transaction.getOriginalAmount()) > 0) {
            newRemaining = transaction.getOriginalAmount();
        }
        transaction.setRemainingAmount(newRemaining);
        transaction.setStatus(statusFor(newRemaining, transaction.getOriginalAmount()));

        repaymentRepository.delete(repayment);
    }

    private TransactionStatus statusFor(BigDecimal remaining, BigDecimal original) {
        if (remaining.signum() <= 0) {
            return TransactionStatus.PAID;
        }
        if (remaining.compareTo(original) < 0) {
            return TransactionStatus.PARTIALLY_PAID;
        }
        return TransactionStatus.ACTIVE;
    }

    private Transaction requireOwnedTransaction(User user, UUID id) {
        return transactionRepository.findByIdAndUserId(id, user.getId())
            .orElseThrow(() -> ApiException.notFound("TRANSACTION_NOT_FOUND", "Transaction not found"));
    }

    private Contact requireOwnedContact(User user, UUID contactId) {
        return contactRepository.findByIdAndUserId(contactId, user.getId())
            .orElseThrow(() -> ApiException.badRequest("CONTACT_NOT_FOUND", "Contact not found"));
    }
}
