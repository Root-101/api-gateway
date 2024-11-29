package dev.root101.api_gateway.feature.service;

import dev.root101.api_gateway.feature.model.RouteConfigModel;
import dev.root101.commons.exceptions.ConflictException;
import dev.root101.commons.exceptions.NotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.gateway.event.RefreshRoutesEvent;
import org.springframework.cloud.gateway.filter.FilterDefinition;
import org.springframework.cloud.gateway.handler.predicate.PredicateDefinition;
import org.springframework.cloud.gateway.route.RouteDefinition;
import org.springframework.cloud.gateway.route.RouteDefinitionWriter;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.net.URI;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.stream.Collectors;

/**
 * This is the class who really make the modifications in the routes.
 * At the end of every action the context is updated and the change is ready to use.
 */
@Service
public class DynamicRouteService {

    private final RouteDefinitionWriter routeDefinitionWriter;

    private final ApplicationEventPublisher publisher;

    private final List<RouteConfigModel> routeConfigModels;

    @Autowired
    public DynamicRouteService(RouteDefinitionWriter routeDefinitionWriter, ApplicationEventPublisher publisher) {
        this.routeDefinitionWriter = routeDefinitionWriter;
        this.publisher = publisher;
        this.routeConfigModels = new ArrayList<>();
    }

    /**
     * Add a single route
     *
     * @param routeModel The route to add
     * @return Void
     */
    public Mono<Void> addRoute(RouteConfigModel routeModel) {
        //load route if exist
        RouteConfigModel oldById = findById(routeModel.getId());
        //if exist throw exception, can't have two routes with same id
        if (oldById != null) {
            throw new ConflictException("Route already exists: %s".formatted(routeModel.getId()));
        }

        //parse model to route-definition
        RouteDefinition route = fromModel(routeModel);

        //add route into the list (in order to return it after as model)
        routeConfigModels.add(routeModel);

        //write in route-definition and update routes
        return routeDefinitionWriter.save(Mono.just(route)).then(Mono.defer(this::updateRoutes));
    }

    /**
     * Create multiple routes at the same time
     *
     * @param routeDefinition List of routes to create
     * @return Void
     */
    public Mono<Void> addAllRoutes(List<RouteConfigModel> routeDefinition) {
        //check for duplicated values in same list
        Map<String, Long> frequencyMap = routeDefinition.stream()
                .collect(Collectors.groupingBy(RouteConfigModel::getId, Collectors.counting()));
        for (Map.Entry<String, Long> entry : frequencyMap.entrySet()) {
            if (entry.getValue() > 1) {
                throw new ConflictException("Duplicated route: %s".formatted(entry.getKey()));
            }
        }
        //check for duplicated values with already inserted ones
        for (RouteConfigModel routeConfigModel : routeDefinition) {
            RouteConfigModel oldById = findById(routeConfigModel.getId());
            if (oldById != null) {
                throw new ConflictException("Route already exists: %s".formatted(routeConfigModel.getId()));
            }
        }

        //Add routes to storage list
        routeConfigModels.addAll(routeDefinition);

        //Create a flux with all routes
        return Flux.fromIterable(routeDefinition)
                .map(this::fromModel) // Parse RouteConfigModel => RouteDefinition
                .concatMap(route -> routeDefinitionWriter.save(Mono.just(route))) // Procesa secuencialmente
                .then(Mono.defer(this::updateRoutes));
    }

    /**
     * Edit a route. Since the edit is not allowed in `RouteDefinitionWriter` this logic
     * delete the old route, create a new one and update the context.
     *
     * @param routeId    The id of the old route
     * @param routeModel The new config of route
     * @return void
     */
    public Mono<Void> editRoute(String routeId, RouteConfigModel routeModel) {
        //Search and delete old route (if existed, if not: exception)
        return Mono.justOrEmpty(findById(routeId))
                .switchIfEmpty(Mono.error(new NotFoundException("Route does not exist: %s".formatted(routeId))))//If findBy is empty, throw exception
                .doOnNext(oldRoute -> routeConfigModels.removeIf(e -> routeId.equals(e.getId())))//if existed: delete it
                .flatMap(oldRoute -> {
                    //Add model to local list
                    routeConfigModels.add(routeModel);

                    //Parse RouteConfigModel => RouteDefinition
                    RouteDefinition newRoute = fromModel(routeModel);

                    //Delete old route and save new one
                    return routeDefinitionWriter.delete(Mono.just(routeId))
                            .then(routeDefinitionWriter.save(Mono.just(newRoute)));
                })
                .then(Mono.defer(this::updateRoutes)); //Update routes after all
    }

    /**
     * Find a route by its id, or null if it's not found
     *
     * @param routeId The id of the route to find
     */
    public RouteConfigModel findById(String routeId) {
        return routeConfigModels.stream()
                .filter(route -> routeId.equals(route.getId()))
                .findFirst()
                .orElse(null);
    }

    /**
     * Delete a route from the gateway
     *
     * @param routeId The id of the route to delete
     */
    public Mono<Void> deleteRoute(String routeId) {
        //Search and delete old route (if existed, if not: exception)
        return Mono.justOrEmpty(findById(routeId))
                .switchIfEmpty(Mono.error(new NotFoundException("Route does not exist: %s".formatted(routeId))))//If findBy is empty, throw exception
                .doOnNext(oldRoute -> routeConfigModels.removeIf(e -> routeId.equals(e.getId())))//if existed: delete it
                .flatMap(oldRoute -> {
                    //Delete old route and save new one
                    return routeDefinitionWriter.delete(Mono.just(routeId));
                })
                .then(Mono.defer(this::updateRoutes)); //Update routes after all
    }

    /**
     * This can also be achieved with:
     * 1 - Receiving in constructor: `RouteDefinitionLocator routeDefinitionLocator;`
     * 2 - Calling `routeDefinitionLocator.getRouteDefinitions();`
     * 3 - This will return `Flux<RouteConfigModel>`
     */
    public Flux<RouteConfigModel> getRoutes() {
        return Flux.fromIterable(routeConfigModels);
    }

    /**
     * Update all the routes in `routeDefinitionWriter`
     * This is the method to call for the route actually go into effect, if not, the gateway will not recognize the routes
     *
     * @param <T> to avoid warnings, it's not used
     * @return Mono.empty()
     */
    private <T> Mono<T> updateRoutes() {
        publisher.publishEvent(new RefreshRoutesEvent(this));
        return Mono.empty();
    }

    /**
     * Convert the `RouteConfigModel` into a `RouteDefinition`
     *
     * @param routeModel The model to convert into `RouteDefinition`
     * @return The parsed `RouteDefinition`
     */
    private RouteDefinition fromModel(RouteConfigModel routeModel) {
        //create the route definition, the model to parse in order to config the gateway
        RouteDefinition route = new RouteDefinition();

        //set the route-id
        route.setId(routeModel.getId());
        //set the route uri
        route.setUri(URI.create(routeModel.getUri()));

        //add the path predicate
        PredicateDefinition predicateDefinition = new PredicateDefinition();
        predicateDefinition.setName("Path");
        predicateDefinition.setArgs(Map.of("_genkey_0", routeModel.getPath()));
        route.setPredicates(List.of(predicateDefinition));

        //add, if provided, the rewrite path filter
        if (routeModel.getRewritePath() != null) {
            //create empty filter
            FilterDefinition rewritePathFilter = new FilterDefinition();
            //set-up name
            rewritePathFilter.setName("RewritePath");

            //prepare filter args. always use a tree-map to always have the values sorted
            Map<String, String> sortedFilter = new TreeMap<>(
                    Map.of(
                            "_genkey_0", routeModel.getRewritePath().replaceFrom(),
                            "_genkey_1", routeModel.getRewritePath().replaceTo()
                    )
            );

            //set arguments to filter
            rewritePathFilter.setArgs(sortedFilter);

            //set filter to list
            route.setFilters(List.of(rewritePathFilter));
        }

        return route;
    }

}
