package dev.root101.api_gateway.features.addons.logic.usecase;

import dev.root101.api_gateway.features.addons.logic.model.Addons;
import dev.root101.api_gateway.features.addons.logic.model.AddonsRequest;
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

    public AddonsUseCase(MaintenanceUseCase maintenanceUseCase) {
        this.maintenanceUseCase = maintenanceUseCase;
    }

    /**
     * The add-ons of the gateway. No db request.
     */
    public Addons ofGateway(Locale locale) {
        return new Addons(maintenanceUseCase.ofGateway(locale));
    }

    /**
     * The add-ons of a route. No db request.
     */
    public Addons ofRoute(String routeId, Locale locale) {
        return new Addons(maintenanceUseCase.ofRoute(routeId, locale));
    }

    /**
     * The add-ons of a restored route, in the transaction of the caller, who calls {@link #reload()} after it: a key
     * with a value is saved, a key `null` is deleted, a key not sent is kept
     */
    public Mono<Void> restore(UUID routeId, AddonsRequest addons) {
        if (addons == null || !addons.sent(Maintenance.TYPE)) return Mono.empty();
        return maintenanceUseCase.save(routeId, addons.getMaintenance());
    }

    /**
     * Reads every add-on from db into use
     */
    public Mono<Void> reload() {
        return maintenanceUseCase.reload();
    }
}
