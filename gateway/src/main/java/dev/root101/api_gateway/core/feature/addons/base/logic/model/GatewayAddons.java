package dev.root101.api_gateway.core.feature.addons.base.logic.model;

import dev.root101.api_gateway.core.feature.addons.cors.logic.model.CorsResponse;
import dev.root101.api_gateway.core.feature.addons.maintenance.logic.model.MaintenanceResponse;
import dev.root101.api_gateway.core.feature.addons.rate_limit.logic.model.RateLimit;

/**
 * The add-ons of the whole gateway, as answered: only the types the gateway can have (not the health check, a route's
 * own), `null` when not configured
 */
public record GatewayAddons(MaintenanceResponse maintenance, RateLimit rateLimit, CorsResponse cors) {
}
