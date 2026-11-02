package dev.root101.api_gateway.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsConfigurationSource;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * Global cors config for the api-gateway.
 * Allowed origins come from `CORS_ALLOWED_ORIGINS` (comma separated origin patterns), default `*` (allow all).
 * <br/>
 * Exposed as a `CorsConfigurationSource` so Spring Security applies it inside its own filter chain
 * (`http.cors(...)` in `SecurityConfig`), otherwise 401/403 responses don't get the CORS headers.
 */
@Configuration
public class CorsConfig {

    //TODO: maybe in a far-far-far away version, add the cors customizable via api
    @Bean
    public CorsConfigurationSource corsConfigurationSource(@Value("${app.cors.allowed-origins}") List<String> allowedOrigins) {
        CorsConfiguration corsConfiguration = new CorsConfiguration();
        corsConfiguration.setAllowedOriginPatterns(allowedOrigins.stream().map(String::trim).toList());
        corsConfiguration.setAllowedMethods(List.of("*"));                    // Allow any method
        corsConfiguration.setAllowedHeaders(List.of("*"));                    // Allow any header
        corsConfiguration.setExposedHeaders(List.of("*"));                    // Expose all headers
        corsConfiguration.setAllowCredentials(true);                              // Allow credentials

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", corsConfiguration);

        return source;
    }
}
