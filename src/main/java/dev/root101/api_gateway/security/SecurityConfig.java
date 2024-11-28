package dev.root101.api_gateway.security;

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
            AdminAuthenticationWebFilter adminAuthenticationWebFilter
    ) {
        return http
                .csrf(ServerHttpSecurity.CsrfSpec::disable) // Disable CSRF (this is a stateless api, don't need csrf)
                .authorizeExchange(
                        exchange -> exchange
                                //if the admin route changes, change it in dev.root101.api_gateway.feature.controller.RoutesController:@RequestMapping("/_admin/routes")
                                //if this role value changes, change it in app.yml:app.admin.role
                                .pathMatchers("/_admin/**").hasRole("GATEWAY_ADMIN") // Admin routes
                                .anyExchange().permitAll() // Any others, processed as public, the redirected service is the one that handles its own auth
                )
                .addFilterAt(adminAuthenticationWebFilter, SecurityWebFiltersOrder.AUTHENTICATION) //Add admin filter
                .build();
    }
}
