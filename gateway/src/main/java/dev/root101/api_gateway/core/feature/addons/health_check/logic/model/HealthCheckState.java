package dev.root101.api_gateway.core.feature.addons.health_check.logic.model;

import java.time.OffsetDateTime;

/**
 * What the gateway writes of a health check (the `state` of its row), never the admin: the last result only.
 *
 * @param checkedAt when it was last called, null if never
 * @param up        the service answered a `2xx`
 * @param status    the status it answered, null if it didn't answer (unreachable, timeout)
 * @param millis    how long the call took
 */
public record HealthCheckState(OffsetDateTime checkedAt, Boolean up, Integer status, Long millis) {

    public static final HealthCheckState NONE = new HealthCheckState(null, null, null, null);
}
