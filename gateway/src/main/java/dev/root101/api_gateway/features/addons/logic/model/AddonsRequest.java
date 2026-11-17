package dev.root101.api_gateway.features.addons.logic.model;

import dev.root101.api_gateway.features.health_check.logic.model.HealthCheck;
import dev.root101.api_gateway.features.maintenance.logic.model.Maintenance;
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

    /**
     * Whether the key of this type came, with a value or `null`
     */
    public boolean sent(String type) {
        return sent.contains(type);
    }
}
