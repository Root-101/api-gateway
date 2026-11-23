package dev.root101.api_gateway.security;

import dev.root101.api_gateway.config.CorsConfig;
import dev.root101.api_gateway.config.GlobalExceptionHandlerConfig;
import dev.root101.api_gateway.core.feature.addons.cors.logic.usecase.CorsUseCase;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.headers.TrustedProxies;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.web.server.SecurityWebFiltersOrder;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;

@Configuration
public class ApplicationSecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(
            ServerHttpSecurity http,
            AdminAuthenticationManager adminAuthenticationManager,
            AdminTokens adminTokens,
            LoginAttemptsGuard loginAttemptsGuard,
            @Value("${app.admin.base-path}") String adminBasePath,
            @Value("${app.admin.role}") String adminRole,
            GlobalExceptionHandlerConfig errorHandler,
            TrustedProxies trustedProxies,
            CorsUseCase corsUseCase
    ) {
        String loginPathMatcher = "/%s/auth/login".formatted(adminBasePath);
        String healthPathMatcher = "/%s/health".formatted(adminBasePath);
        String adminPathMatchers = "/%s/**".formatted(adminBasePath);
        String adminCleanRole = adminRole.replaceFirst("ROLE_", "");
        //not a bean: as a bean/@Component, WebFlux would also register it in the global chain and run it twice
        AdminAuthenticationWebFilter adminAuthenticationWebFilter = new AdminAuthenticationWebFilter(adminAuthenticationManager, adminTokens, loginAttemptsGuard, adminBasePath, errorHandler, trustedProxies);
        return http
                .csrf(ServerHttpSecurity.CsrfSpec::disable)                                       // Disable CSRF (this is a stateless api, don't need csrf)
                .cors(ServerHttpSecurity.CorsSpec::disable)                                       // Replaced by the admin CORS filter below
                .addFilterAt(CorsConfig.adminCorsFilter(corsUseCase, adminBasePath), SecurityWebFiltersOrder.CORS) // The gateway's CORS add-on on the admin API, so 401/403 also get CORS headers
                .exceptionHandling(exc -> exc
                        // Problem Details, and no `WWW-Authenticate: Basic` header: it makes browsers open the native login popup
                        .authenticationEntryPoint((exchange, e) -> errorHandler.writeProblem(exchange, HttpStatus.UNAUTHORIZED, "auth.required"))
                        .accessDeniedHandler((exchange, e) -> errorHandler.writeProblem(exchange, HttpStatus.FORBIDDEN, "auth.forbidden"))
                )
                .authorizeExchange(
                        exchange -> exchange
                                .pathMatchers(HttpMethod.OPTIONS, "/**").permitAll()            // Allow options request (for preflight cors)
                                .pathMatchers(loginPathMatcher).permitAll()                       // Login route, allow all
                                .pathMatchers(healthPathMatcher).permitAll()                      // Health check, allow all
                                .pathMatchers(adminPathMatchers).hasRole(adminCleanRole)          // Admin routes, need admin role
                                .anyExchange().permitAll()                                        // Any others, processed as public, the redirected service is the one that handles its own auth
                )
                .addFilterAt(adminAuthenticationWebFilter, SecurityWebFiltersOrder.AUTHENTICATION) //Add admin filter
                .build();
    }
}
