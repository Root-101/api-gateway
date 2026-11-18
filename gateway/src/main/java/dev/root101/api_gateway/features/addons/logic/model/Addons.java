package dev.root101.api_gateway.features.addons.logic.model;

import dev.root101.api_gateway.features.health_check.logic.model.HealthCheckResponse;
import dev.root101.api_gateway.features.maintenance.logic.model.MaintenanceResponse;
import dev.root101.api_gateway.features.rate_limit.logic.model.RateLimit;

/**
 * The add-ons of a route, as answered: every type this version knows, `null` when not configured. A new type is a new
 * field here (and in {@link GatewayAddons} if the gateway can have it).
 */
public record Addons(MaintenanceResponse maintenance, HealthCheckResponse healthCheck, RateLimit rateLimit) {
}
