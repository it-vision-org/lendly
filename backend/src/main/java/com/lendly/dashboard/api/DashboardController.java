package com.lendly.dashboard.api;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.lendly.common.security.CurrentUserProvider;
import com.lendly.dashboard.api.dto.DashboardResponse;
import com.lendly.dashboard.service.DashboardService;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private final DashboardService dashboardService;
    private final CurrentUserProvider currentUserProvider;

    public DashboardController(DashboardService dashboardService, CurrentUserProvider currentUserProvider) {
        this.dashboardService = dashboardService;
        this.currentUserProvider = currentUserProvider;
    }

    @GetMapping
    public DashboardResponse get(@AuthenticationPrincipal Jwt jwt) {
        return dashboardService.get(currentUserProvider.require(jwt));
    }
}
