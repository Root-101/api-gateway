package dev.root101.api_gateway.features.addons.maintenance.logic.model;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.OffsetDateTime;

/**
 * The maintenance add-on of the gateway or of a route, as the admin sets it (the `config` of its row). In maintenance
 * only when `enabled`: turned off, the message and the time are kept for the next time.
 *
 * @param enabled    every request gets a `503` instead of reaching the service
 * @param message    the `detail` of the `503`; a default translated text when missing
 * @param retryAfter when the service is expected back: the `Retry-After` header while it is in the future. It never
 *                   turns the maintenance off by itself
 */
public record Maintenance(
        @NotNull Boolean enabled,
        @Size(max = 500) String message,
        OffsetDateTime retryAfter
) {

    /**
     * Its `type` in the `addon` table and its key in `addons`
     */
    public static final String TYPE = "maintenance";

    /**
     * Whether the requests are stopped
     */
    public boolean on() {
        return Boolean.TRUE.equals(enabled);
    }
}
