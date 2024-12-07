package dev.root101.api_gateway.feature.service;

import dev.root101.api_gateway.feature.data.entity.RouteEntity;
import dev.root101.api_gateway.feature.data.repo.RouteRepo;
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
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * This is the class who really make the modifications in the routes.
 * At the end of every action the context is updated and the change is ready to use.
 */
@Service
public class DynamicRouteService {

    private final RouteDefinitionWriter routeDefinitionWriter;

    private final ApplicationEventPublisher publisher;

    private final RouteRepo routeRepo;

    private final ValidationService vs;

    @Autowired
    public DynamicRouteService(
            RouteDefinitionWriter routeDefinitionWriter,
            ApplicationEventPublisher publisher,
            RouteRepo routeRepo,
            ValidationService validationService
    ) {
        this.routeDefinitionWriter = routeDefinitionWriter;
        this.publisher = publisher;
        this.routeRepo = routeRepo;
        this.vs = validationService;
    }

    /**
     * Add a single route
     *
     * @param request The route to add
     * @return Void
     */
    public Mono<Void> addRoute(RouteConfigRequest request) {
        //find any route with same name
        return routeRepo.findByName(request.getName())
                .flatMap(existingRoute -> Mono.error(new ConflictException("Route already exists: %s".formatted(request.getName()))))
                .switchIfEmpty(Mono.defer(() -> {

                    RouteEntity entity = buildEntity(request);
                    return Mono.fromRunnable(() -> vs.validateRecursiveAndThrow(entity))
                            .then(
                                    routeRepo.save(entity)
                                            .flatMap(savedEntity -> routeDefinitionWriter.save(
                                                    Mono.just(buildDefinition(savedEntity))
                                            ).then(Mono.defer(this::updateRoutes)))
                            );
                }))
                .then();
    }

    /**
     * Create multiple routes at the same time
     *
     * @param requests List of routes to create
     * @return Void
     */
    public Mono<Void> addAllRoutes(List<RouteConfigRequest> requests) {
        // Check for duplicated values within the input list
        return Flux.fromIterable(requests)
                .collectMultimap(RouteConfigRequest::getName)
                .flatMapMany(frequencyMap -> {
                    for (Map.Entry<String, Collection<RouteConfigRequest>> entry : frequencyMap.entrySet()) {
                        if (entry.getValue().size() > 1) {
                            return Mono.error(new ConflictException("Duplicated route: %s".formatted(entry.getKey())));
                        }
                    }
                    return Flux.fromIterable(requests);
                })
                // Check for duplicates in the database
                .flatMap(request -> routeRepo.findByName(request.getName())
                        .flatMap(existing -> Mono.error(new ConflictException("Route already exists: %s".formatted(request.getName()))))
                        .switchIfEmpty(Mono.just(request)))
                // Parse input list into entities
                .map(request -> buildEntity((RouteConfigRequest) request)) // Aquí se asegura el tipo
                .collectList()
                .flatMap(
                        entities -> Mono.fromRunnable(() -> vs.validateRecursiveAndThrow(entities))
                                .then(
                                        routeRepo.saveAll(entities).collectList()
                                )
                )
                // Process all saved entities and update routes
                .flatMapMany(savedEntities -> Flux.fromIterable(savedEntities)
                        .map(this::buildDefinition)
                        .concatMap(route -> routeDefinitionWriter.save(Mono.just(route))))
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
        // Buscar la ruta antigua
        return routeRepo.findByName(routeName)
                .switchIfEmpty(Mono.error(new NotFoundException("Route does not exist: %s".formatted(routeName))))
                .flatMap(oldRoute -> {
                    // Eliminar la ruta antigua
                    return routeRepo.delete(oldRoute)
                            .then(Mono.defer(() -> {
                                // Crear la nueva entidad
                                RouteEntity entity = buildEntity(request);

                                // Validar la nueva entidad
                                return Mono.fromRunnable(() -> vs.validateRecursiveAndThrow(entity))
                                        .then(routeRepo.save(entity)) // Persistir en la base de datos
                                        .flatMap(parsedEntity -> {
                                            // Crear la nueva definición de ruta
                                            RouteDefinition newRoute = buildDefinition(parsedEntity);

                                            // Actualizar la definición de ruta
                                            return routeDefinitionWriter.delete(Mono.just(oldRoute.getName()))
                                                    .then(routeDefinitionWriter.save(Mono.just(newRoute)));
                                        });
                            }));
                })
                // Actualizar las rutas después de todos los cambios
                .then(Mono.defer(this::updateRoutes));
    }

    /**
     * Find a route by its name, or null if it's not found
     *
     * @param routeName The name of the route to find
     */
    public Mono<RouteEntity> findByName(String routeName) {
        //TODO: send 404 if no exist
        return routeRepo.findByName(routeName);
    }

    /**
     * Delete a route from the gateway
     *
     * @param routeName The name of the route to delete
     */
    public Mono<Void> deleteRoute(String routeName) {
        // Buscar la ruta y eliminarla
        return routeRepo.findByName(routeName)
                .switchIfEmpty(Mono.error(new NotFoundException("Route does not exist: %s".formatted(routeName))))
                .flatMap(route ->
                        routeRepo.delete(route) // Eliminar la ruta de la base de datos
                                .then(routeDefinitionWriter.delete(Mono.just(routeName))) // Eliminar la definición de la ruta
                )
                .then(Mono.defer(this::updateRoutes)); // Actualizar las rutas después de todos los cambios
    }

    /**
     * This can also be achieved with:
     * 1 - Receiving in constructor: `RouteDefinitionLocator routeDefinitionLocator;`
     * 2 - Calling `routeDefinitionLocator.getRouteDefinitions();`
     * 3 - This will return `Flux<RouteConfigModel>`
     */
    public Flux<RouteConfigResponse> getRoutes() {
        return routeRepo.findAll().map(this::buildResponse);
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
