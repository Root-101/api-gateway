package dev.root101.api_gateway.features.addons.maintenance.logic.model;

import java.time.OffsetDateTime;

/**
 * What the gateway writes of a maintenance (the `state` of its row), never the admin: written only when `enabled`
 * really changes. Only the last cycle.
 *
 * @param enabledAt  the last time it was turned on, null if never
 * @param disabledAt the last time it was turned off, null if never
 */
public record MaintenanceState(OffsetDateTime enabledAt, OffsetDateTime disabledAt) {

    public static final MaintenanceState NONE = new MaintenanceState(null, null);
}
