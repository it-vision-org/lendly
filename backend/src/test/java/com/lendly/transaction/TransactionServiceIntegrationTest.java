package com.lendly.transaction;

import java.math.BigDecimal;
import java.time.LocalDate;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.lendly.common.api.ApiException;
import com.lendly.contact.domain.Contact;
import com.lendly.contact.repository.ContactRepository;
import com.lendly.identity.domain.User;
import com.lendly.identity.repository.UserRepository;
import com.lendly.support.IntegrationTestSupport;
import com.lendly.transaction.api.dto.RepaymentRequest;
import com.lendly.transaction.api.dto.RepaymentResponse;
import com.lendly.transaction.api.dto.TransactionRequest;
import com.lendly.transaction.api.dto.TransactionResponse;
import com.lendly.transaction.domain.TransactionStatus;
import com.lendly.transaction.domain.TransactionType;
import com.lendly.transaction.service.TransactionService;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class TransactionServiceIntegrationTest extends IntegrationTestSupport {

    @Autowired
    private TransactionService transactionService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ContactRepository contactRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private User createUser(String email) {
        User user = new User("Test User", email, passwordEncoder.encode("password123"));
        return userRepository.save(user);
    }

    private Contact createContact(User user, String name) {
        return contactRepository.save(new Contact(user, name, null, null, null));
    }

    private static void assertAmountEquals(String expected, BigDecimal actual) {
        assertEquals(0, new BigDecimal(expected).compareTo(actual), () -> "expected " + expected + " but was " + actual);
    }

    @Test
    void repaymentsRecalculateRemainingAmountAndStatus() {
        User user = createUser("owner-" + System.nanoTime() + "@lendly.test");
        Contact contact = createContact(user, "Sami");

        TransactionResponse created = transactionService.create(user, new TransactionRequest(
            contact.getId(), TransactionType.LENT, new BigDecimal("300.00"), "TND", "Restaurant payment", LocalDate.now()
        ));

        assertEquals(TransactionStatus.ACTIVE, created.status());
        assertAmountEquals("300.00", created.remainingAmount());

        RepaymentResponse firstPayment = transactionService.addRepayment(
            user, created.id(), new RepaymentRequest(new BigDecimal("100.00"), LocalDate.now(), null)
        );
        assertAmountEquals("100.00", firstPayment.amount());

        TransactionResponse afterFirstPayment = transactionService.get(user, created.id());
        assertAmountEquals("200.00", afterFirstPayment.remainingAmount());
        assertEquals(TransactionStatus.PARTIALLY_PAID, afterFirstPayment.status());

        transactionService.addRepayment(user, created.id(), new RepaymentRequest(new BigDecimal("200.00"), LocalDate.now(), null));

        TransactionResponse afterFullyPaid = transactionService.get(user, created.id());
        assertAmountEquals("0.00", afterFullyPaid.remainingAmount());
        assertEquals(TransactionStatus.PAID, afterFullyPaid.status());
    }

    @Test
    void repaymentExceedingRemainingAmountIsRejected() {
        User user = createUser("owner-" + System.nanoTime() + "@lendly.test");
        Contact contact = createContact(user, "Youssef");

        TransactionResponse created = transactionService.create(user, new TransactionRequest(
            contact.getId(), TransactionType.BORROWED, new BigDecimal("80.00"), "TND", "Fuel", LocalDate.now()
        ));

        assertThrows(ApiException.class, () ->
            transactionService.addRepayment(user, created.id(), new RepaymentRequest(new BigDecimal("100.00"), LocalDate.now(), null))
        );
    }

    @Test
    void aUserCannotAccessAnotherUsersTransaction() {
        User owner = createUser("owner-" + System.nanoTime() + "@lendly.test");
        User intruder = createUser("intruder-" + System.nanoTime() + "@lendly.test");
        Contact contact = createContact(owner, "Rahma");

        TransactionResponse created = transactionService.create(owner, new TransactionRequest(
            contact.getId(), TransactionType.LENT, new BigDecimal("50.00"), "TND", null, LocalDate.now()
        ));

        assertThrows(ApiException.class, () -> transactionService.get(intruder, created.id()));
    }
}
