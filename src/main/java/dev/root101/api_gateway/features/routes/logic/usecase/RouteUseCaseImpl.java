package dev.root101.api_gateway.features.routes.logic.usecase;

import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import dev.root101.api_gateway.features.routes.data.repo.RouteRepo;
import dev.root101.api_gateway.features.routes.logic.model.RewritePathModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigResponse;
import dev.root101.api_gateway.features.routes.utils.RouteDefinitionMapper;
import dev.root101.api_gateway.features.routes.utils.RouteUpdater;
import dev.root101.commons.exceptions.ConflictException;
import dev.root101.commons.exceptions.NotFoundException;
import dev.root101.commons.validation.ValidationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.gateway.route.RouteDefinition;
import org.springframework.cloud.gateway.route.RouteDefinitionWriter;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.OffsetDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Map;

/**
 * This is the class who really make the modifications in the routes.
 * At the end of every action the context is updated and the change is ready to use.
 */
@Service
class RouteUseCaseImpl implements RouteUseCase {

    private final RouteDefinitionWriter routeDefinitionWriter;

    private final RouteUpdater routeUpdater;

    private final RouteRepo routeRepo;

    private final ValidationService vs;

    @Autowired
    public RouteUseCaseImpl(
            RouteDefinitionWriter routeDefinitionWriter,
            RouteUpdater routeUpdater,
            RouteRepo routeRepo,
            ValidationService validationService
    ) {
        this.routeDefinitionWriter = routeDefinitionWriter;
        this.routeUpdater = routeUpdater;
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
                //if a route is found, throw error (cant have two routes with same name)
                .flatMap(
                        existingRoute -> Mono.error(
                                new ConflictException("Route already exists: %s".formatted(request.getName()))
                        )
                )
                //if no route is found, then process request
                .switchIfEmpty(
                        Mono.defer(() -> {
                            //parse request to entity
                            RouteEntity entity = buildEntity(request);

                            //validate request
                            return Mono.fromRunnable(() -> vs.validate(entity))//if any error, exception is thrown
                                    .then(
                                            //if all validations oka, save route to DB
                                            routeRepo.save(entity)
                                                    .flatMap(
                                                            //save route to gateway
                                                            savedEntity -> routeDefinitionWriter.save(
                                                                    Mono.just(
                                                                            buildDefinition(savedEntity)
                                                                    )
                                                            ).then(
                                                                    //update routes
                                                                    Mono.defer(routeUpdater::updateRoutes)
                                                            )
                                                    )
                                    );
                        })
                )
                .then();
    }

    /**
     * Create multiple routes at the same time
     *
     * @param requests List of routes to create
     * @return Void
     */
    public Mono<Void> addAllRoutes(List<RouteConfigRequest> requests) {
        // Convert list into flux
        return Flux.fromIterable(requests)
                // Check for duplicated values within the input list
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
                .flatMap(
                        request -> routeRepo.findByName(request.getName())
                                .flatMap(existing -> Mono.error(new ConflictException("Route already exists: %s".formatted(request.getName()))))
                                .switchIfEmpty(Mono.just(request))
                )
                // Parse input list into entities
                .map(request -> buildEntity((RouteConfigRequest) request)) // Manual parse of type (up we lose the type)
                .collectList()
                .flatMap(
                        entities -> Mono.fromRunnable(() -> vs.validate(entities))
                                .then(
                                        routeRepo.saveAll(entities).collectList()
                                )
                )
                // Process all saved entities and update routes
                .flatMapMany(
                        savedEntities -> Flux.fromIterable(savedEntities)
                                .map(this::buildDefinition)
                                .concatMap(route -> routeDefinitionWriter.save(Mono.just(route)))
                )
                .then(Mono.defer(routeUpdater::updateRoutes));
    }


    /**
     * Edit a route. Since the edit is not allowed in `RouteDefinitionWriter` this logic
     * delete the old route, create a new one and update the context.
     *
     * @param routeId The name of the old route
     * @param request The new config of route
     * @return void
     */
    public Mono<Void> editRoute(String routeId, RouteConfigRequest request) {
        // Search old route
        return routeRepo.findByRawId(routeId)
                .switchIfEmpty(Mono.error(new NotFoundException("Route does not exist: %s".formatted(routeId))))
                .flatMap(oldRoute -> {
                    RouteEntity entityToEdit = buildEntity(request);
                    entityToEdit.setRouteId(oldRoute.getRouteId());//maintain same id
                    entityToEdit.setCreatedAt(oldRoute.getCreatedAt());//maintain same create_at

                    return Mono.fromRunnable(() -> vs.validate(entityToEdit))
                            .then(
                                    routeRepo.save(entityToEdit).flatMap(
                                            parsedEntity -> {
                                                // Build new route-definition
                                                RouteDefinition newRoute = buildDefinition(parsedEntity);

                                                // Update routes
                                                // 1 - delete
                                                // 2 - save
                                                return routeDefinitionWriter.delete(
                                                        Mono.just(oldRoute.getRouteId().toString())
                                                ).then(
                                                        routeDefinitionWriter.save(Mono.just(newRoute))
                                                );
                                            }
                                    )
                            );
                })
                // Update route after all changes
                .then(Mono.defer(routeUpdater::updateRoutes));
    }

    /**
     * Find a route by its name, or null if it's not found
     *
     * @param routeId The name of the route to find
     */
    public Mono<RouteEntity> findById(String routeId) {
        return routeRepo.findByRawId(routeId)
                .switchIfEmpty(
                        Mono.error(
                                new NotFoundException("Route does not exist: %s".formatted(routeId))
                        )
                );
    }

    /**
     * Delete a route from the gateway
     *
     * @param routeId The name of the route to delete
     */
    public Mono<Void> deleteRoute(String routeId) {
        // Search old route
        return routeRepo.findByRawId(routeId)
                .switchIfEmpty(Mono.error(new NotFoundException("Route does not exist: %s".formatted(routeId))))
                .flatMap(route ->
                        routeRepo.delete(route) // Delete route from db
                                .then(
                                        routeDefinitionWriter.delete( // Delete route from writer
                                                Mono.just(routeId)
                                        )
                                )
                )
                .then(Mono.defer(routeUpdater::updateRoutes)); // Update route after all changes
    }

    /**
     * This can also be achieved with:
     * 1 - Receiving in constructor: `RouteDefinitionLocator routeDefinition;`
     * 2 - Calling `routeDefinitionLocator.getRouteDefinitions();`
     * 3 - This will return `Flux<RouteConfigModel>`
     */
    public Flux<RouteConfigResponse> getRoutes() {
        return routeRepo.findAll().map(this::buildResponse);
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
                OffsetDateTime.now()
        );
    }

    /**
     * Convert the `RouteEntity` into a `RouteDefinition`
     *
     * @param routeEntity The model to convert into `RouteDefinition`
     * @return The parsed `RouteDefinition`
     */
    private RouteDefinition buildDefinition(RouteEntity routeEntity) {
        return RouteDefinitionMapper.buildDefinition(routeEntity);
    }

    /**
     * Convert the `RouteEntity` into a `RouteConfigResponse`
     *
     * @param entity The entity to convert into `RouteConfigResponse`
     * @return The parsed `RouteConfigResponse`
     */
    private RouteConfigResponse buildResponse(RouteEntity entity) {
        return new RouteConfigResponse(
                entity.getRouteId().toString(),
                entity.getName(),
                entity.getPath(),
                entity.getUri(),
                entity.getRewritePathFrom() != null && entity.getRewritePathTo() != null ? new RewritePathModel(entity.getRewritePathFrom(), entity.getRewritePathTo()) : null,
                entity.getDescription(),
                entity.getCreatedAt()
        );
    }
}
