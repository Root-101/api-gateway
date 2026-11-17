package dev.root101.api_gateway.features.maintenance.rest;

import dev.root101.api_gateway.features.maintenance.logic.model.Maintenance;
import dev.root101.api_gateway.features.maintenance.logic.usecase.MaintenanceUseCase;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.util.Optional;

/**
 * The maintenance of the whole gateway. The one of a route is in the routes controller.
 */
@RestController
@RequestMapping("/${app.admin.base-path}/maintenance")
public class MaintenanceController {

    private final MaintenanceUseCase maintenanceUseCase;

    public MaintenanceController(MaintenanceUseCase maintenanceUseCase) {
        this.maintenanceUseCase = maintenanceUseCase;
    }

    /**
     * @return The maintenance of the gateway, or `null` if it was never set
     */
    @GetMapping
    public Mono<Optional<Maintenance>> getMaintenance() {
        return Mono.fromSupplier(() -> Optional.ofNullable(maintenanceUseCase.global()));
    }

    /**
     * Puts the whole gateway in maintenance (`enabled: true`) or takes it out (`enabled: false`), right away
     *
     * @return The saved maintenance
     */
    @PutMapping
    public Mono<Maintenance> setMaintenance(@Valid @RequestBody Maintenance maintenance) {
        return maintenanceUseCase.setGlobal(maintenance);
    }
}
