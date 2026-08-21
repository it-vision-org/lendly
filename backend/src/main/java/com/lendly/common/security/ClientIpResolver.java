package com.lendly.common.security;

import jakarta.servlet.http.HttpServletRequest;

/**
 * Best-effort client IP resolution for rate limiting. Checks {@code
 * X-Forwarded-For} first (the app is typically deployed behind a platform
 * load balancer/proxy) and falls back to the raw socket address.
 */
public final class ClientIpResolver {

    private ClientIpResolver() {
    }

    public static String resolve(HttpServletRequest request) {
        String forwardedFor = request.getHeader("X-Forwarded-For");
        if (forwardedFor != null && !forwardedFor.isBlank()) {
            return forwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
