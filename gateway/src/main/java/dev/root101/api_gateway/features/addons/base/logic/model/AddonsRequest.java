package dev.root101.api_gateway.features.addons.base.logic.model;

import dev.root101.api_gateway.features.addons.health_check.logic.model.HealthCheck;
import dev.root101.api_gateway.features.addons.maintenance.logic.model.Maintenance;
import dev.root101.api_gateway.features.addons.rate_limit.logic.model.RateLimit;
import jakarta.validation.Valid;

import java.util.HashSet;
import java.util.Set;

/**
 * The add-ons of a route in a restore (`PUT /routes`). Tells a key sent as `null` (delete it) from a key not sent
 * (keep it): jackson calls the setter for an explicit `null` too. Unknown keys (a backup of a newer gateway) are
 * ignored, as any unknown property.
 */
public class AddonsRequest {

    @Valid
    private Maintenance maintenance;

    @Valid
    private HealthCheck healthCheck;

    @Valid
    private RateLimit rateLimit;

    private final Set<String> sent = new HashSet<>();

    public Maintenance getMaintenance() {
        return maintenance;
    }

    public void setMaintenance(Maintenance maintenance) {
        this.maintenance = maintenance;
        sent.add(Maintenance.TYPE);
    }

    public HealthCheck getHealthCheck() {
        return healthCheck;
    }

    public void setHealthCheck(HealthCheck healthCheck) {
        this.healthCheck = healthCheck;
        sent.add(HealthCheck.TYPE);
    }

    public RateLimit getRateLimit() {
        return rateLimit;
    }

    public void setRateLimit(RateLimit rateLimit) {
        this.rateLimit = rateLimit;
        sent.add(RateLimit.TYPE);
    }

    /**
     * Whether the key of this type came, with a value or `null`
     */
    public boolean sent(String type) {
        return sent.contains(type);
    }
}
