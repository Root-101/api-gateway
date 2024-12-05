package dev.root101.api_gateway.feature.service;

import dev.root101.api_gateway.feature.data.entity.RouteEntity;
import dev.root101.api_gateway.feature.data.jpa.RouteJpaRepo;
import dev.root101.api_gateway.feature.model.RewritePath;
import dev.root101.api_gateway.feature.model.RouteConfigRequest;
import dev.root101.api_gateway.feature.model.RouteConfigResponse;
import dev.root101.commons.exceptions.ConflictException;
import dev.root101.commons.exceptions.NotFoundException;
import dev.root101.commons.validation.ValidationService;
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
import java.time.Instant;
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

    private final RouteJpaRepo routeJpaRepo;

    private final ValidationService vs;

    @Autowired
    public DynamicRouteService(
            RouteDefinitionWriter routeDefinitionWriter,
            ApplicationEventPublisher publisher,
            RouteJpaRepo routeJpaRepo,
            ValidationService validationService
    ) {
        this.routeDefinitionWriter = routeDefinitionWriter;
        this.publisher = publisher;
        this.routeJpaRepo = routeJpaRepo;
        this.vs = validationService;
    }

    /**
     * Add a single route
     *
     * @param request The route to add
     * @return Void
     */
    public Mono<Void> addRoute(RouteConfigRequest request) {
        //load route if exist
        RouteEntity oldById = findByName(request.getName());

        //if exist throw exception, can't have two routes with same name
        if (oldById != null) {
            throw new ConflictException("Route already exists: %s".formatted(request.getName()));
        }

        RouteEntity entity = buildEntity(request);

        vs.validateRecursiveAndThrow(entity);

        //persist route in db
        RouteEntity parsedEntity = routeJpaRepo.save(entity);//TODO: https://chatgpt.com/c/67510e08-ae28-8010-899e-5f1d3e89c4c6

        //write in route-definition and update routes
        return routeDefinitionWriter.save(
                Mono.just(
                        buildDefinition(parsedEntity)
                )
        ).then(Mono.defer(this::updateRoutes));
    }

    /**
     * Create multiple routes at the same time
     *
     * @param requests List of routes to create
     * @return Void
     */
    public Mono<Void> addAllRoutes(List<RouteConfigRequest> requests) {
        //check for duplicated values in same list
        Map<String, Long> frequencyMap = requests.stream()
                .collect(Collectors.groupingBy(RouteConfigRequest::getName, Collectors.counting()));
        for (Map.Entry<String, Long> entry : frequencyMap.entrySet()) {
            if (entry.getValue() > 1) {
                throw new ConflictException("Duplicated route: %s".formatted(entry.getKey()));
            }
        }
        //check for duplicated values with already inserted ones
        for (RouteConfigRequest routeConfigModel : requests) {
            RouteEntity oldById = findByName(routeConfigModel.getName());
            if (oldById != null) {
                throw new ConflictException("Route already exists: %s".formatted(routeConfigModel.getName()));
            }
        }

        //parse input list into entities
        List<RouteEntity> entities = requests.stream().map(this::buildEntity).toList();

        //validate all entities
        vs.validateRecursiveAndThrow(entities);

        //Add routes to storage list
        List<RouteEntity> parsedEntities = routeJpaRepo.saveAll(entities); //TODO: same as save

        //Create a flux with all routes
        return Flux.fromIterable(parsedEntities)
                .map(this::buildDefinition) // Parse RouteConfigModel => RouteDefinition
                .concatMap(route -> routeDefinitionWriter.save(Mono.just(route))) // Procesa secuencialmente
                .then(Mono.defer(this::updateRoutes));
    }

    /**
     * Edit a route. Since the edit is not allowed in `RouteDefinitionWriter` this logic
     * delete the old route, create a new one and update the context.
     *
     * @param routeName The name of the old route
     * @param request   The new config of route
     * @return void
     */
    public Mono<Void> editRoute(String routeName, RouteConfigRequest request) {
        //Search and delete old route (if existed, if not: exception)
        return Mono.justOrEmpty(findByName(routeName))
                .switchIfEmpty(Mono.error(new NotFoundException("Route does not exist: %s".formatted(routeName))))//If findBy is empty, throw exception
                .doOnNext(routeJpaRepo::delete)//if existed: delete it
                .flatMap(oldRoute -> {
                    RouteEntity entity = buildEntity(request);

                    vs.validateRecursiveAndThrow(entity);

                    //persist route in db
                    RouteEntity parsedEntity = routeJpaRepo.save(entity);//TODO

                    //Parse RouteConfigModel => RouteDefinition
                    RouteDefinition newRoute = buildDefinition(parsedEntity);

                    //Delete old route and save new one
                    return routeDefinitionWriter.delete(
                                    Mono.just(oldRoute.getName())
                            )
                            .then(routeDefinitionWriter.save(Mono.just(newRoute)));
                })
                .then(Mono.defer(this::updateRoutes)); //Update routes after all
    }

    /**
     * Find a route by its id, or null if it's not found
     *
     * @param routeId The id of the route to find
     */
    public RouteEntity findById(Integer routeId) {
        return routeJpaRepo.findById(routeId)
                .orElse(null);
    }

    /**
     * Find a route by its name, or null if it's not found
     *
     * @param routeName The name of the route to find
     */
    public RouteEntity findByName(String routeName) {
        return routeJpaRepo.findByName(routeName)
                .orElse(null);
    }

    /**
     * Delete a route from the gateway
     *
     * @param routeName The name of the route to delete
     */
    public Mono<Void> deleteRoute(String routeName) {
        //Search and delete old route (if existed, if not: exception)
        return Mono.justOrEmpty(findByName(routeName))
                .switchIfEmpty(Mono.error(new NotFoundException("Route does not exist: %s".formatted(routeName))))//If findBy is empty, throw exception
                .doOnNext(routeJpaRepo::delete)//if existed: delete it
                .flatMap(oldRoute -> {
                    //Delete old route and save new one
                    return routeDefinitionWriter.delete(Mono.just(routeName));
                })
                .then(Mono.defer(this::updateRoutes)); //Update routes after all
    }

    /**
     * This can also be achieved with:
     * 1 - Receiving in constructor: `RouteDefinitionLocator routeDefinitionLocator;`
     * 2 - Calling `routeDefinitionLocator.getRouteDefinitions();`
     * 3 - This will return `Flux<RouteConfigModel>`
     */
    public Flux<RouteConfigResponse> getRoutes() {
        return Flux.fromIterable(
                routeJpaRepo.findAll().stream().map(
                        this::buildResponse
                ).toList()
        );
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
     * Convert the `RouteConfigModel` into a `RouteEntity`
     *
     * @param routeModel The model to convert into `RouteEntity`
     * @return The parsed `RouteEntity`
     */
    private RouteEntity buildEntity(RouteConfigRequest routeModel) {
        return new RouteEntity(
                null,
                routeModel.getName(),
                routeModel.getPath(),
                routeModel.getUri(),
                routeModel.getRewritePath() != null ? routeModel.getRewritePath().getReplaceFrom() : null,
                routeModel.getRewritePath() != null ? routeModel.getRewritePath().getReplaceTo() : null,
                routeModel.getDescription(),
                Instant.now()
        );
    }

    /**
     * Convert the `RouteEntity` into a `RouteDefinition`
     *
     * @param routeEntity The model to convert into `RouteDefinition`
     * @return The parsed `RouteDefinition`
     */
    private RouteDefinition buildDefinition(RouteEntity routeEntity) {
        //create the route definition, the model to parse in order to config the gateway
        RouteDefinition route = new RouteDefinition();

        //set the route-id
        route.setId(routeEntity.getName());
        //set the route uri
        route.setUri(URI.create(routeEntity.getUri()));

        //add the path predicate
        PredicateDefinition predicateDefinition = new PredicateDefinition();
        predicateDefinition.setName("Path");
        predicateDefinition.setArgs(Map.of("_genkey_0", routeEntity.getPath()));
        route.setPredicates(List.of(predicateDefinition));

        //add, if provided, the rewrite path filter
        if (routeEntity.getRewritePathFrom() != null && routeEntity.getRewritePathTo() != null) {
            //create empty filter
            FilterDefinition rewritePathFilter = new FilterDefinition();
            //set-up name
            rewritePathFilter.setName("RewritePath");

            //prepare filter args. always use a tree-map to always have the values sorted
            Map<String, String> sortedFilter = new TreeMap<>(
                    Map.of(
                            "_genkey_0", routeEntity.getRewritePathFrom(),
                            "_genkey_1", routeEntity.getRewritePathTo()
                    )
            );

            //set arguments to filter
            rewritePathFilter.setArgs(sortedFilter);

            //set filter to list
            route.setFilters(List.of(rewritePathFilter));
        }

        return route;
    }

    /**
     * Convert the `RouteEntity` into a `RouteConfigResponse`
     *
     * @param entity The entity to convert into `RouteConfigResponse`
     * @return The parsed `RouteConfigResponse`
     */
    private RouteConfigResponse buildResponse(RouteEntity entity) {
        return new RouteConfigResponse(
                entity.getRouteId(),
                entity.getName(),
                entity.getPath(),
                entity.getUri(),
                entity.getRewritePathFrom() != null && entity.getRewritePathTo() != null ? new RewritePath(entity.getRewritePathFrom(), entity.getRewritePathTo()) : null,
                entity.getDescription(),
                entity.getCreatedAt()
        );
    }
}
