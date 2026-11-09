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
     * @param routeId The id of the old route
     * @param request The new config of route
     * @return void
     */
    Mono<Void> editRoute(String routeId, RouteConfigRequest request);

    /**
     * Find a route by its id, or null if it's not found
     *
     * @param routeId The id the route to find
     */
    Mono<RouteEntity> findById(String routeId);

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

    /**
     * Get the routes as saved in cache... in theory this should have the same result as `getRoutes`.
     * We still provide both methods... maybe a change was made direct to db....
     * <p>
     * This method DON'T make a DB request.
     */
    List<RouteEntity> getCacheRoutes();
}
