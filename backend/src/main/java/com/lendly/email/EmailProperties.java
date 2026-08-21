package com.lendly.email;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.email")
public record EmailProperties(
    String resendApiKey,
    String fromEmail,
    String fromName
) {
}
