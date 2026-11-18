package dev.root101.api_gateway.features.addons.logic.model;

import dev.root101.api_gateway.features.maintenance.logic.model.MaintenanceResponse;
import dev.root101.api_gateway.features.rate_limit.logic.model.RateLimit;

/**
 * The add-ons of the whole gateway, as answered: only the types the gateway can have (not the health check, a route's
 * own), `null` when not configured
 */
public record GatewayAddons(MaintenanceResponse maintenance, RateLimit rateLimit) {
}
