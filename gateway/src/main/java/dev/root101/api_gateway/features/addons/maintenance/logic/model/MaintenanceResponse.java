package dev.root101.api_gateway.features.addons.maintenance.logic.model;

import java.time.OffsetDateTime;

/**
 * A maintenance as answered: what the admin set, plus two read-only fields (ignored on writes)
 *
 * @param defaultMessage the `detail` of the `503` when there is no `message`, in the request's language
 * @param state          when it was last turned on and off, never null
 */
public record MaintenanceResponse(
        Boolean enabled,
        String message,
        OffsetDateTime retryAfter,
        String defaultMessage,
        MaintenanceState state
) {
}
