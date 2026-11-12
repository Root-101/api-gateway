package dev.root101.api_gateway.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.headers.HttpHeadersFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsConfigurationSource;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;
import org.springframework.web.server.ServerWebExchange;

import java.util.List;

/**
 * CORS of every path: the admin API (the console calls it from another origin) and the proxied routes.
 * The gateway answers the CORS preflights itself (WebFlux never forwards them to a route), so without
 * this a browser can't send a JSON request to a proxied service.
 * Allowed origins come from `CORS_ALLOWED_ORIGINS` (comma separated origin patterns), default `*` (allow all).
 * No credentials: the console sends its token as a header, never a cookie.
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
        corsConfiguration.setAllowCredentials(false);                             // Bearer header, no cookies

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", corsConfiguration);

        return source;
    }

    /**
     * Drops the `Access-Control-*` headers of the upstream responses: the gateway's CORS headers are already
     * set, the upstream's would be added next to them (two `Access-Control-Allow-Origin` = blocked by the browser).
     */
    @Bean
    public HttpHeadersFilter upstreamCorsHeadersFilter() {
        return new HttpHeadersFilter() {
            @Override
            public HttpHeaders filter(HttpHeaders input, ServerWebExchange exchange) {
                HttpHeaders filtered = new HttpHeaders();
                input.forEach((name, values) -> {
                    if (!name.regionMatches(true, 0, "Access-Control-", 0, "Access-Control-".length())) {
                        filtered.addAll(name, values);
                    }
                });
                return filtered;
            }

            @Override
            public boolean supports(Type type) {
                return type == Type.RESPONSE;
            }
        };
    }
}
