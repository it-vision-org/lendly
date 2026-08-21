package com.lendly.email;

import com.lendly.common.api.ApiException;

import org.springframework.http.HttpStatus;

/**
 * Thrown when the outbound email provider fails, times out, or is
 * misconfigured. Carries only a safe, generic message — never the provider's
 * raw error body, which could leak configuration details.
 */
public class EmailDeliveryException extends ApiException {

    public EmailDeliveryException(String message, Throwable cause) {
        super(HttpStatus.SERVICE_UNAVAILABLE, "EMAIL_DELIVERY_FAILED", message);
        initCause(cause);
    }
}
