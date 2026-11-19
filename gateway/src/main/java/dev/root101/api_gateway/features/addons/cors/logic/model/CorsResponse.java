package dev.root101.api_gateway.features.addons.cors.logic.model;

import java.util.List;

/**
 * The gateway's CORS as answered: what the admin set, plus one read-only field (ignored on writes, never saved)
 *
 * @param envVar the deprecated `CORS_ALLOWED_ORIGINS`, null when it isn't set (nothing to tell); goes with it in 7.0
 */
public record CorsResponse(
        Boolean enabled,
        List<String> allowedOrigins,
        Boolean allowCredentials,
        @Deprecated(since = "6.1.0", forRemoval = true) EnvVar envVar
) {

    /**
     * The env var still set in the deploy, read at startup
     *
     * @param name    always `CORS_ALLOWED_ORIGINS`
     * @param origins its origins, as set
     * @param matches true when they are the same as `allowedOrigins` (in any order): it can be removed; false when
     *                they differ: it is ignored, the add-on is used
     */
    @Deprecated(since = "6.1.0", forRemoval = true)
    public record EnvVar(String name, List<String> origins, boolean matches) {
    }
}
