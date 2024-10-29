package dev.root101.api_gateway;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.gateway.route.RouteDefinition;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/routes")
public class RoutesController {

    @Autowired
    private DynamicRouteService dynamicRouteService;

    @GetMapping
    public Flux<RouteDefinition> getRoutes() {
        return dynamicRouteService.getRoutes();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<Void> addRoute(@RequestBody RouteConfigModel routeDefinition) {
        return dynamicRouteService.addRoute(routeDefinition);
    }

    @DeleteMapping("/{routeId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteRoute(@PathVariable String routeId) {
        return dynamicRouteService.deleteRoute(routeId);
    }
}
