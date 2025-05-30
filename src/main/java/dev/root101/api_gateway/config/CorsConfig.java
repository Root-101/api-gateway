package dev.root101.api_gateway.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsWebFilter;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;

import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Global cors config for the api-gateway.
 * For the moment is an "Allow all" policy.
 */
@Configuration
public class CorsConfig {

    @Value("${app.cors.additional-headers:}")
    private List<String> additionalHeaders;//empty list by default

    private final List<String> baseHeaders = List.of(
            "Authorization",
            "Content-Type",
            "Accept",
            "Origin",
            "X-Requested-With",
            "Access-Control-Allow-Headers",
            "Access-Control-Request-Method",
            "Access-Control-Request-Headers"
    );

    /**
     * This has the problem that if a web client tries to access a service that passes through the gateway
     * and includes a header that is not allowed in the gateway, the request will fail...
     * <p>
     * To mitigate the problem, a list as generic as possible was provided.
     * In the future, it is planned to give the user the ability to add custom headers
     * according to their needs.
     * <p>
     * For the moment, an intermediate solution is implemented where the most basic headers are predefined
     * and if another extra is needed, it is passed as an environment variable.
     */
    @Bean
    public CorsWebFilter corsWebFilter() {
        CorsConfiguration corsConfiguration = new CorsConfiguration();
        corsConfiguration.setAllowedOriginPatterns(List.of("*"));             // Allow any origin
        corsConfiguration.setAllowedMethods(List.of(                              // Allow all method
                "QUERY",
                "GET",
                "POST",
                "PUT",
                "DELETE",
                "OPTIONS",
                "HEAD",
                "PATCH",
                "TRACE",
                "CONNECT"
        ));

        List<String> allHeaders = Stream.concat(baseHeaders.stream(), additionalHeaders.stream())
                .distinct()
                .collect(Collectors.toList());
        corsConfiguration.setAllowedHeaders(allHeaders);                             // Allow all (known)  header
        corsConfiguration.setExposedHeaders(allHeaders);                             // Expose all (known) headers

        corsConfiguration.setAllowCredentials(true);                                 // Allow credentials

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", corsConfiguration);

        return new CorsWebFilter(source);
    }
}
