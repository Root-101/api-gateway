package dev.root101.api_gateway.core.feature.addons.cors.logic.model;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import org.springframework.web.cors.CorsConfiguration;

import java.util.List;

/**
 * The CORS add-on of the gateway or of a route, as the admin sets it (the `config` of its row). The gateway's covers
 * the admin API and every route without one of its own (on); a route's covers only that route. Methods, headers and
 * exposed headers are always `*`.
 *
 * @param enabled          a route's is used only when true (else the gateway's); the gateway's is always on
 * @param allowedOrigins   origin patterns: `https://app.com`, `https://*.example.com`, `http://localhost:[*]`, `*`
 * @param allowCredentials sends `Access-Control-Allow-Credentials: true` (cookies); false when missing
 */
public record Cors(
        @NotNull Boolean enabled,
        @NotEmpty List<@NotNull @Pattern(regexp = ORIGIN, message = "{cors.origin.invalid}") String> allowedOrigins,
        Boolean allowCredentials
) {

    /**
     * Its `type` in the `addon` table and its key in `addons`
     */
    public static final String TYPE = "cors";

    /**
     * `*`, or a scheme and a host (with an optional port), no path
     */
    public static final String ORIGIN = "\\*|[a-zA-Z*][a-zA-Z0-9+.*-]*://[^/\\s?#]+";

    public boolean on() {
        return Boolean.TRUE.equals(enabled);
    }

    public boolean credentials() {
        return Boolean.TRUE.equals(allowCredentials);
    }

    /**
     * Whether a pattern lets in origins nobody listed: `*`, or a `*` in the host other than a leading `*.` before a
     * domain with a dot (`https://*`, `https://*:8080`, `https://*.*`, `https://*.com`, `https://a*.com`). The port
     * (`:[*]`) doesn't count.
     */
    public boolean allowsAnyOrigin() {
        return allowedOrigins.stream().anyMatch(origin -> {
            String host = origin.replaceFirst("^[^:]*://", "").replaceFirst(":(\\[[^]]*]|[^:\\]]*)$", "");
            return origin.equals("*") || host.contains("*") && !host.matches("\\*\\.[^*]+\\.[^*]+");
        });
    }

    /**
     * As Spring applies it
     */
    public CorsConfiguration toConfiguration() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(allowedOrigins);
        config.setAllowedMethods(List.of("*"));
        config.setAllowedHeaders(List.of("*"));
        config.setExposedHeaders(List.of("*"));
        config.setAllowCredentials(credentials());
        return config;
    }
}
