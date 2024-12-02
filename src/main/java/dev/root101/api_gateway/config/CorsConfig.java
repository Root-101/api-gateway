package dev.root101.api_gateway.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsWebFilter;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * Global cors config for the api-gateway.
 * For the moment is an "Allow all" policy.
 */
@Configuration
public class CorsConfig {

    //TODO: maybe in a far-far-far away version, add the cors customizable via api
    @Bean
    public CorsWebFilter corsWebFilter() {
        CorsConfiguration corsConfiguration = new CorsConfiguration();
        corsConfiguration.setAllowedOriginPatterns(List.of("*"));             // Allow any origin
        corsConfiguration.setAllowedMethods(List.of("*"));                    // Allow any method
        corsConfiguration.setAllowedHeaders(List.of("*"));                    // Allow any header
        corsConfiguration.setExposedHeaders(List.of("*"));                    // Expose all headers
        corsConfiguration.setAllowCredentials(true);                              // Allow credentials

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", corsConfiguration);

        return new CorsWebFilter(source);
    }
}
