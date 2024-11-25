package dev.root101.api_gateway.feature.controller;

import dev.root101.api_gateway.feature.model.RouteConfigModel;
import dev.root101.api_gateway.feature.service.DynamicRouteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/routes")
public class RoutesController {

    private final DynamicRouteService dynamicRouteService;

    @Autowired
    public RoutesController(DynamicRouteService dynamicRouteService) {
        this.dynamicRouteService = dynamicRouteService;
    }

    @GetMapping
    public Flux<RouteConfigModel> getRoutes() {
        return dynamicRouteService.getRoutes();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<Void> addRoute(@RequestBody RouteConfigModel routeDefinition) {
        return dynamicRouteService.addRoute(routeDefinition);
    }

    @PutMapping("/{route-id}")
    public Mono<Void> editRoute(@PathVariable("route-id") String routeId, @RequestBody RouteConfigModel routeDefinition) {
        return dynamicRouteService.editRoute(routeId, routeDefinition);
    }

    @DeleteMapping("/{route-id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteRoute(@PathVariable("route-id") String routeId) {
        return dynamicRouteService.deleteRoute(routeId);
    }
}
