package dev.root101.api_gateway.feature.service;

import dev.root101.api_gateway.feature.model.RouteConfigModel;
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
     * Add a new route to config
     *
     * @param routeModel The route to add
     * @return void
     */
    public Mono<Void> addRoute(RouteConfigModel routeModel) {
        //parse model to route-definition
        RouteDefinition route = fromModel(routeModel);

        //add route into the list (in order to return it after as model)
        routeConfigModels.add(routeModel);

        //write in route-definition and update routes
        return routeDefinitionWriter.save(Mono.just(route)).then(Mono.defer(this::updateRoutes));
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
        //load old route
        RouteConfigModel oldById = findById(routeId);

        //if route dont exist throw exception
        if (oldById == null) {
            throw new IllegalArgumentException("Route does not exist");//TODO: poner ruta que es
        }

        //if route exist:
        //delete it from local list
        routeConfigModels.removeIf(e -> routeId.equals(e.getId()));

        //after deletion, update:

        //parse model to route-definition
        RouteDefinition route = fromModel(routeModel);

        //add route into the list (in order to return it after as model)
        routeConfigModels.add(routeModel);

        //delete it from route-definition
        return routeDefinitionWriter.delete(Mono.just(routeId)).then(
                //write in route-definition and update routes
                routeDefinitionWriter.save(Mono.just(route)).then(Mono.defer(this::updateRoutes))
        );
    }

    /**
     * Find a route by its id, or null if it's not found
     *
     * @param routeId The id of the route to find
     */
    public RouteConfigModel findById(String routeId) {
        for (RouteConfigModel routeConfigModel : routeConfigModels) {
            if (routeConfigModel.getId().equals(routeId)) {
                return routeConfigModel;
            }
        }
        return null;
    }

    /**
     * Delete a route from the gateway
     *
     * @param routeId The id of the route to delete
     */
    public Mono<Void> deleteRoute(String routeId) {
        routeConfigModels.removeIf(e -> routeId.equals(e.getId()));

        return routeDefinitionWriter.delete(Mono.just(routeId)).then(Mono.defer(this::updateRoutes));
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
            FilterDefinition rewritePathFilter = new FilterDefinition();
            rewritePathFilter.setName("RewritePath");
            rewritePathFilter.setArgs(Map.of("_genkey_0", routeModel.getRewritePath().replaceFrom(), "_genkey_1", routeModel.getRewritePath().replaceTo()));

            // Añadir los filtros a la ruta
            route.setFilters(List.of(rewritePathFilter));
        }

        return route;
    }
}
