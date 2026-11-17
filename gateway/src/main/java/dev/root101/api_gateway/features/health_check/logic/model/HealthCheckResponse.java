package dev.root101.api_gateway.features.health_check.logic.model;

/**
 * A health check as answered: what the admin set, plus the read-only `state` (ignored on writes)
 *
 * @param state the last result, never null (its fields null until the first call)
 */
public record HealthCheckResponse(
        Boolean enabled,
        String path,
        Integer intervalSeconds,
        HealthCheckState state
) {
}
