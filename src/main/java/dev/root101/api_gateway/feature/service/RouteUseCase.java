package dev.root101.api_gateway.feature.service;

import dev.root101.api_gateway.feature.data.entity.RouteEntity;
import dev.root101.api_gateway.feature.model.RouteConfigRequest;
import dev.root101.api_gateway.feature.model.RouteConfigResponse;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;

public interface RouteUseCase {

    /**
     * Add a single route
     *
     * @param request The route to add
     * @return Void
     */
    Mono<Void> addRoute(RouteConfigRequest request);

    /**
     * Create multiple routes at the same time
     *
     * @param requests List of routes to create
     * @return Void
     */
    Mono<Void> addAllRoutes(List<RouteConfigRequest> requests);


    /**
     * Edit a route. Since the edit is not allowed in `RouteDefinitionWriter` this logic
     * delete the old route, create a new one and update the context.
     *
     * @param routeName The name of the old route
     * @param request   The new config of route
     * @return void
     */
    Mono<Void> editRoute(String routeName, RouteConfigRequest request);

    /**
     * Find a route by its name, or null if it's not found
     *
     * @param routeName The name of the route to find
     */
    Mono<RouteEntity> findByName(String routeName);

    /**
     * Delete a route from the gateway
     *
     * @param routeName The name of the route to delete
     */
    Mono<Void> deleteRoute(String routeName);

    /**
     * This can also be achieved with:
     * 1 - Receiving in constructor: `RouteDefinitionLocator routeDefinitionLocator;`
     * 2 - Calling `routeDefinitionLocator.getRouteDefinitions();`
     * 3 - This will return `Flux<RouteConfigModel>`
     */
    Flux<RouteConfigResponse> getRoutes();
}
