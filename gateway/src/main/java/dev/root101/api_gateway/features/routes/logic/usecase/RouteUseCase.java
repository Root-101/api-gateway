package dev.root101.api_gateway.features.routes.logic.usecase;

import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigResponse;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;

public interface RouteUseCase {

    /**
     * Add a single route
     *
     * @param request The route to add
     * @return The created route
     */
    Mono<RouteConfigResponse> addRoute(RouteConfigRequest request);

    /**
     * Create multiple routes at the same time
     *
     * @param requests List of routes to create
     * @return The created routes
     */
    Mono<List<RouteConfigResponse>> addAllRoutes(List<RouteConfigRequest> requests);

    /**
     * Replace every route with the given ones, all or nothing. A route whose name already exists keeps its id.
     *
     * @param requests The routes that will exist after the call
     * @return The routes, as saved
     */
    Mono<List<RouteConfigResponse>> replaceAllRoutes(List<RouteConfigRequest> requests);

    /**
     * Edit a route, keeping its id
     *
     * @param routeId The id of the route
     * @param request The new config of route
     * @return The edited route
     */
    Mono<RouteConfigResponse> editRoute(String routeId, RouteConfigRequest request);

    /**
     * Find a route by its id: `400` if it is not a UUID, `404` if there is none
     *
     * @param routeId The id the route to find
     */
    Mono<RouteConfigResponse> findById(String routeId);

    /**
     * Delete a route from the gateway
     *
     * @param routeId The id of the route to delete
     */
    Mono<Void> deleteRoute(String routeId);

    /**
     * This can also be achieved with:
     * 1 - Receiving in constructor: `RouteDefinitionLocator routeDefinitionLocator;`
     * 2 - Calling `routeDefinitionLocator.getRouteDefinitions();`
     * 3 - This will return `Flux<RouteConfigModel>`
     */
    Flux<RouteConfigResponse> getRoutes();

    /**
     * Find a cached route by its id, or null if it's not found.
     * This method DON'T make a DB request.
     *
     * @param routeId The id of the route to find.
     */
    RouteEntity findCachedById(String routeId);
}
