package dev.root101.api_gateway.features.addons.logic.usecase;

import dev.root101.api_gateway.features.addons.logic.model.Addons;
import dev.root101.api_gateway.features.addons.logic.model.AddonsRequest;
import dev.root101.api_gateway.features.addons.logic.model.GatewayAddons;
import dev.root101.api_gateway.features.health_check.logic.model.HealthCheck;
import dev.root101.api_gateway.features.health_check.logic.usecase.HealthCheckUseCase;
import dev.root101.api_gateway.features.maintenance.logic.model.Maintenance;
import dev.root101.api_gateway.features.maintenance.logic.usecase.MaintenanceUseCase;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.Locale;
import java.util.UUID;

/**
 * Every add-on type together, for what reads or restores them all at once: a new type is added here. Each type keeps
 * its own use case and endpoints.
 */
@Service
public class AddonsUseCase {

    private final MaintenanceUseCase maintenanceUseCase;
    private final HealthCheckUseCase healthCheckUseCase;

    public AddonsUseCase(MaintenanceUseCase maintenanceUseCase, HealthCheckUseCase healthCheckUseCase) {
        this.maintenanceUseCase = maintenanceUseCase;
        this.healthCheckUseCase = healthCheckUseCase;
    }

    /**
     * The add-ons of the gateway. No db request.
     */
    public GatewayAddons ofGateway(Locale locale) {
        return new GatewayAddons(maintenanceUseCase.ofGateway(locale));
    }

    /**
     * The add-ons of a route. No db request.
     */
    public Addons ofRoute(String routeId, Locale locale) {
        return new Addons(maintenanceUseCase.ofRoute(routeId, locale), healthCheckUseCase.ofRoute(routeId));
    }

    /**
     * The add-ons of a restored route, in the transaction of the caller, who calls {@link #reload()} after it: a key
     * with a value is saved, a key `null` is deleted, a key not sent is kept
     */
    public Mono<Void> restore(UUID routeId, AddonsRequest addons) {
        if (addons == null) return Mono.empty();
        Mono<Void> maintenance = addons.sent(Maintenance.TYPE) ? maintenanceUseCase.save(routeId, addons.getMaintenance()) : Mono.empty();
        Mono<Void> healthCheck = addons.sent(HealthCheck.TYPE) ? healthCheckUseCase.save(routeId, addons.getHealthCheck()) : Mono.empty();
        return maintenance.then(healthCheck);
    }

    /**
     * Reads every add-on from db into use
     */
    public Mono<Void> reload() {
        return maintenanceUseCase.reload().then(healthCheckUseCase.reload());
    }
}
