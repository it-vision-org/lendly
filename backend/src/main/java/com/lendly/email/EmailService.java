package com.lendly.email;

import java.util.List;
import java.util.Map;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;

import lombok.extern.slf4j.Slf4j;

/**
 * Thin wrapper around Resend's HTTP API (https://api.resend.com/emails). Uses
 * Spring's built-in {@link RestClient} rather than a third-party SDK, since
 * Resend's API is a single JSON POST call.
 *
 * <p>The API key is read once at startup from {@link EmailProperties} (backed
 * by the {@code RESEND_API_KEY} environment variable) and never logged or
 * exposed in any response.
 */
@Slf4j
@Service
@EnableConfigurationProperties(EmailProperties.class)
public class EmailService {

    private final RestClient restClient;
    private final EmailProperties properties;

    public EmailService(EmailProperties properties) {
        this.properties = properties;
        this.restClient = RestClient.builder()
            .baseUrl("https://api.resend.com")
            .build();
    }

    public void send(String toEmail, String subject, String html, String text) {
        if (properties.resendApiKey() == null || properties.resendApiKey().isBlank()) {
            log.error("Resend is not configured (RESEND_API_KEY missing)");
            throw new EmailDeliveryException("Email delivery is not available right now", null);
        }

        String from = properties.fromName() + " <" + properties.fromEmail() + ">";

        try {
            restClient.post()
                .uri("/emails")
                .header("Authorization", "Bearer " + properties.resendApiKey())
                .contentType(MediaType.APPLICATION_JSON)
                .body(Map.of(
                    "from", from,
                    "to", List.of(toEmail),
                    "subject", subject,
                    "html", html,
                    "text", text
                ))
                .retrieve()
                .toBodilessEntity();
        } catch (RestClientResponseException e) {
            log.error("Resend API rejected the email request: status={}", e.getStatusCode().value());
            throw new EmailDeliveryException("We couldn't send the verification email. Please try again.", e);
        } catch (RestClientException e) {
            log.error("Resend API was unreachable or timed out", e);
            throw new EmailDeliveryException("We couldn't send the verification email. Please try again.", e);
        }
    }
}
