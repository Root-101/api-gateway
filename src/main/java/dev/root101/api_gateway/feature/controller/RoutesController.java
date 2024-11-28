package dev.root101.api_gateway.feature.controller;

import dev.root101.api_gateway.feature.model.RouteConfigModel;
import dev.root101.api_gateway.feature.service.DynamicRouteService;
import dev.root101.commons.validation.ValidationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;

@RestController
@RequestMapping("/routes")
public class RoutesController {

    private final DynamicRouteService dynamicRouteService;
    private final ValidationService validationService;

    @Autowired
    public RoutesController(DynamicRouteService dynamicRouteService, ValidationService validationService) {
        this.dynamicRouteService = dynamicRouteService;
        this.validationService = validationService;
    }

    @GetMapping
    public Flux<RouteConfigModel> getRoutes() {
        return dynamicRouteService.getRoutes();
    }

    @PostMapping("/multi-add")
    public Mono<Void> addAllRoutes(@RequestBody List<RouteConfigModel> routeDefinition) {
        this.validationService.validateRecursiveAndThrow(routeDefinition);

        return dynamicRouteService.addAllRoutes(routeDefinition);
    }

    @PostMapping
    public Mono<Void> addRoute(@RequestBody RouteConfigModel routeDefinition) {
        this.validationService.validateRecursiveAndThrow(routeDefinition);

        return dynamicRouteService.addRoute(routeDefinition);
    }

    @PutMapping("/{route-id}")
    public Mono<Void> editRoute(@PathVariable("route-id") String routeId, @RequestBody RouteConfigModel routeDefinition) {
        this.validationService.validateRecursiveAndThrow(routeDefinition);

        return dynamicRouteService.editRoute(routeId, routeDefinition);
    }

    @DeleteMapping("/{route-id}")
    public Mono<Void> deleteRoute(@PathVariable("route-id") String routeId) {
        return dynamicRouteService.deleteRoute(routeId);
    }
}
