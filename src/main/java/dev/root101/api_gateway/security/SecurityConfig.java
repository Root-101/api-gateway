package dev.root101.api_gateway.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableReactiveMethodSecurity;
import org.springframework.security.config.web.server.SecurityWebFiltersOrder;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;

@Configuration
@EnableReactiveMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(
            ServerHttpSecurity http,
            AdminAuthenticationWebFilter adminAuthenticationWebFilter,
            @Value("${app.admin.base-path}") String adminBasePath,
            @Value("${app.admin.role}") String adminRole
    ) {
        String adminPathMatchers = "/%s/**".formatted(adminBasePath);
        String loginPathMatcher = "/%s/auth/login".formatted(adminBasePath);
        String adminCleanRole = adminRole.replaceFirst("ROLE_", "");
        return http
                .csrf(ServerHttpSecurity.CsrfSpec::disable) // Disable CSRF (this is a stateless api, don't need csrf)
                .authorizeExchange(
                        exchange -> exchange
                                .pathMatchers(adminPathMatchers).hasRole(adminCleanRole) // Admin routes, need admin role
                                .pathMatchers(loginPathMatcher).permitAll()//login route, allow all
                                .anyExchange().permitAll() // Any others, processed as public, the redirected service is the one that handles its own auth
                )
                .addFilterAt(adminAuthenticationWebFilter, SecurityWebFiltersOrder.AUTHENTICATION) //Add admin filter
                .build();
    }
}
