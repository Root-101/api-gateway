package dev.root101.api_gateway.features.addons.logic.model;

import dev.root101.api_gateway.features.maintenance.logic.model.MaintenanceResponse;

/**
 * The add-ons of the gateway or of a route, as answered: every type this version knows, `null` when not configured.
 * A new type is a new field here.
 */
public record Addons(MaintenanceResponse maintenance) {
}
