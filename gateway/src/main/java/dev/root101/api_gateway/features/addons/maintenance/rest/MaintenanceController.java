package dev.root101.api_gateway.features.addons.maintenance.rest;

import dev.root101.api_gateway.config.I18n;
import dev.root101.api_gateway.features.addons.maintenance.logic.model.Maintenance;
import dev.root101.api_gateway.features.addons.maintenance.logic.model.MaintenanceResponse;
import dev.root101.api_gateway.features.addons.maintenance.logic.usecase.MaintenanceUseCase;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

/**
 * The maintenance add-on: of the whole gateway (`/addons/maintenance`) and of a route
 * (`/routes/{id}/addons/maintenance`). Every change is in use right away.
 */
@RestController
@RequestMapping("/${app.admin.base-path}")
public class MaintenanceController {

    private final MaintenanceUseCase maintenanceUseCase;

    public MaintenanceController(MaintenanceUseCase maintenanceUseCase) {
        this.maintenanceUseCase = maintenanceUseCase;
    }

    //--------- GATEWAY ---------\\

    /**
     * Creates or replaces the maintenance of the gateway
     */
    @PutMapping("/addons/maintenance")
    public Mono<MaintenanceResponse> setGateway(@Valid @RequestBody Maintenance maintenance, ServerWebExchange exchange) {
        return maintenanceUseCase.setGateway(maintenance, I18n.locale(exchange));
    }

    /**
     * Removes the maintenance of the gateway: back to `null`
     */
    @DeleteMapping("/addons/maintenance")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteGateway() {
        return maintenanceUseCase.deleteGateway();
    }

    /**
     * Turns the maintenance of the gateway on: `404` if it isn't configured
     */
    @PostMapping("/addons/maintenance/enable")
    public Mono<MaintenanceResponse> enableGateway(ServerWebExchange exchange) {
        return maintenanceUseCase.enableGateway(true, I18n.locale(exchange));
    }

    /**
     * Turns the maintenance of the gateway off, keeping its message and time: `404` if it isn't configured
     */
    @PostMapping("/addons/maintenance/disable")
    public Mono<MaintenanceResponse> disableGateway(ServerWebExchange exchange) {
        return maintenanceUseCase.enableGateway(false, I18n.locale(exchange));
    }

    //--------- ROUTE ---------\\

    /**
     * Creates or replaces the maintenance of a route
     */
    @PutMapping("/routes/{route-id}/addons/maintenance")
    public Mono<MaintenanceResponse> setRoute(@PathVariable("route-id") String routeId, @Valid @RequestBody Maintenance maintenance, ServerWebExchange exchange) {
        return maintenanceUseCase.setRoute(routeId, maintenance, I18n.locale(exchange));
    }

    /**
     * Removes the maintenance of a route: back to `null`
     */
    @DeleteMapping("/routes/{route-id}/addons/maintenance")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteRoute(@PathVariable("route-id") String routeId) {
        return maintenanceUseCase.deleteRoute(routeId);
    }

    /**
     * Turns the maintenance of a route on: `404` if it isn't configured
     */
    @PostMapping("/routes/{route-id}/addons/maintenance/enable")
    public Mono<MaintenanceResponse> enableRoute(@PathVariable("route-id") String routeId, ServerWebExchange exchange) {
        return maintenanceUseCase.enableRoute(routeId, true, I18n.locale(exchange));
    }

    /**
     * Turns the maintenance of a route off, keeping its message and time: `404` if it isn't configured
     */
    @PostMapping("/routes/{route-id}/addons/maintenance/disable")
    public Mono<MaintenanceResponse> disableRoute(@PathVariable("route-id") String routeId, ServerWebExchange exchange) {
        return maintenanceUseCase.enableRoute(routeId, false, I18n.locale(exchange));
    }
}
