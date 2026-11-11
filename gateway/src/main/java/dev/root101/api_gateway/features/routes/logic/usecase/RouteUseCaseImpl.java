package dev.root101.api_gateway.features.routes.logic.usecase;

import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import dev.root101.api_gateway.features.routes.data.repo.RouteRepo;
import dev.root101.api_gateway.features.routes.logic.model.RewritePathModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigResponse;
import dev.root101.api_gateway.features.routes.utils.RouteDefinitionMapper;
import dev.root101.api_gateway.features.routes.utils.RouteUpdater;
import dev.root101.commons.exceptions.BadRequestException;
import dev.root101.commons.exceptions.ConflictException;
import dev.root101.commons.exceptions.NotFoundException;
import dev.root101.commons.validation.ValidationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.SmartInitializingSingleton;
import org.springframework.cloud.gateway.route.RouteDefinition;
import org.springframework.cloud.gateway.route.RouteDefinitionWriter;
import org.springframework.stereotype.Service;
import org.springframework.transaction.reactive.TransactionalOperator;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * This is the class who really make the modifications in the routes.
 * At the end of every action the context is updated and the change is ready to use.
 */
@Service
class RouteUseCaseImpl implements RouteUseCase, SmartInitializingSingleton {

    private static final Logger log = LoggerFactory.getLogger(RouteUseCaseImpl.class);

    private final RouteDefinitionWriter routeDefinitionWriter;

    private final RouteUpdater routeUpdater;

    private final RouteRepo routeRepo;

    private final ValidationService vs;

    private final TransactionalOperator tx;

    private final Map<String, RouteEntity> cache = new ConcurrentHashMap<>();

    @Autowired
    public RouteUseCaseImpl(
            RouteDefinitionWriter routeDefinitionWriter,
            RouteUpdater routeUpdater,
            RouteRepo routeRepo,
            ValidationService validationService,
            TransactionalOperator tx
    ) {
        this.routeDefinitionWriter = routeDefinitionWriter;
        this.routeUpdater = routeUpdater;
        this.routeRepo = routeRepo;
        this.vs = validationService;
        this.tx = tx;
    }

    /**
     * Loads the db routes into the gateway before the web server starts (it starts after all the singletons are created),
     * so there is no window of 404s after each deploy. Fails the startup if the routes can't be loaded.
     */
    @Override
    public void afterSingletonsInstantiated() {
        log.info("Loading routes from db");
        Long count = routeRepo.findAll()
                .concatMap(
                        //save each definition in the RouteDefinitionWriter, then to cache (for faster http logs access)
                        route -> routeDefinitionWriter.save(Mono.just(buildDefinition(route)))
                                .then(Mono.fromRunnable(() -> cache.put(route.getRouteId().toString(), route)))
                                .thenReturn(route)
                )
                .count()
                .block(Duration.ofSeconds(60));
        //on this (main) thread: the gateway listeners block, not allowed in a netty thread
        routeUpdater.updateRoutes();
        log.info("{} routes loaded", count);
    }

    /**
     * Add a single route
     *
     * @param request The route to add
     * @return The created route
     */
    public Mono<RouteConfigResponse> addRoute(RouteConfigRequest request) {
        return addAllRoutes(List.of(request)).map(List::getFirst);
    }

    /**
     * Create multiple routes at the same time, all or nothing
     *
     * @param requests List of routes to create
     * @return The created routes
     */
    public Mono<List<RouteConfigResponse>> addAllRoutes(List<RouteConfigRequest> requests) {
        return withoutDuplicatedNames(requests)
                // Check for duplicates in the database
                .concatMap(
                        request -> routeRepo.findByName(request.getName())
                                .flatMap(existing -> Mono.<RouteConfigRequest>error(new ConflictException("Route already exists: %s".formatted(request.getName()))))
                                .switchIfEmpty(Mono.just(request))
                )
                .map(this::buildEntity)
                .collectList()
                .flatMap(
                        entities -> Mono.fromRunnable(() -> vs.validate(entities))
                                //all or nothing: a failure in the middle must not leave half the routes in db
                                .then(routeRepo.saveAll(entities).collectList().as(tx::transactional))
                )
                .flatMap(saved -> apply(saved, List.of()));
    }

    /**
     * Replace every route with the given ones, all or nothing. A route whose name already exists keeps its id
     * (and its creation date), so its logs still find it; the others get new ids.
     *
     * @param requests The routes that will exist after the call
     * @return The routes, as saved
     */
    public Mono<List<RouteConfigResponse>> replaceAllRoutes(List<RouteConfigRequest> requests) {
        return withoutDuplicatedNames(requests)
                .map(this::buildEntity)
                .collectList()
                .flatMap(
                        entities -> Mono.fromRunnable(() -> vs.validate(entities))
                                .then(routeRepo.findAll().collectMap(RouteEntity::getName))
                                .flatMap(current -> {
                                    for (RouteEntity entity : entities) {
                                        RouteEntity old = current.remove(entity.getName());
                                        if (old != null) {
                                            entity.setRouteId(old.getRouteId());
                                            entity.setCreatedAt(old.getCreatedAt());
                                        }
                                    }
                                    List<RouteEntity> removed = List.copyOf(current.values());
                                    //in one transaction: a failure leaves the current routes untouched
                                    return routeRepo.deleteAll(removed)
                                            .thenMany(routeRepo.saveAll(entities))
                                            .collectList()
                                            .as(tx::transactional)
                                            .flatMap(saved -> apply(saved, removed));
                                })
                );
    }

    /**
     * Puts the saved routes in the cache and the gateway (replacing the ones with the same id), removes the
     * deleted ones, and refreshes the routes in use
     */
    private Mono<List<RouteConfigResponse>> apply(List<RouteEntity> saved, List<RouteEntity> removed) {
        saved.forEach(entity -> cache.put(entity.getRouteId().toString(), entity));
        removed.forEach(entity -> cache.remove(entity.getRouteId().toString()));
        return Flux.fromIterable(removed)
                //a route saved in db by another instance isn't in this gateway: nothing to remove
                .concatMap(entity -> routeDefinitionWriter.delete(Mono.just(entity.getRouteId().toString()))
                        .onErrorResume(org.springframework.cloud.gateway.support.NotFoundException.class, e -> Mono.empty()))
                .thenMany(Flux.fromIterable(saved))
                .concatMap(entity -> routeDefinitionWriter.save(Mono.just(buildDefinition(entity))))
                .then(Mono.defer(routeUpdater::updateRoutes))
                .thenReturn(saved.stream().map(this::buildResponse).toList());
    }

    /**
     * The given routes, or a `ConflictException` if two of them have the same name
     */
    private Flux<RouteConfigRequest> withoutDuplicatedNames(List<RouteConfigRequest> requests) {
        return Flux.fromIterable(requests)
                .collectMultimap(RouteConfigRequest::getName)
                .flatMapMany(frequencyMap -> {
                    for (Map.Entry<String, Collection<RouteConfigRequest>> entry : frequencyMap.entrySet()) {
                        if (entry.getValue().size() > 1) {
                            return Mono.error(new ConflictException("Duplicated route: %s".formatted(entry.getKey())));
                        }
                    }
                    return Flux.fromIterable(requests);
                });
    }

    /**
     * Edit a route, keeping its id and creation date
     *
     * @param routeId The id of the route
     * @param request The new config of route
     * @return The edited route
     */
    public Mono<RouteConfigResponse> editRoute(String routeId, RouteConfigRequest request) {
        return findEntity(routeId)
                //the new name can't be used by another route
                .flatMap(oldRoute -> routeRepo.findByName(request.getName())
                        .filter(existing -> !existing.getRouteId().equals(oldRoute.getRouteId()))
                        .flatMap(existing -> Mono.<RouteEntity>error(new ConflictException("Route already exists: %s".formatted(request.getName()))))
                        .defaultIfEmpty(oldRoute)
                )
                .flatMap(oldRoute -> {
                    RouteEntity entityToEdit = buildEntity(request);
                    entityToEdit.setRouteId(oldRoute.getRouteId());//maintain same id
                    entityToEdit.setCreatedAt(oldRoute.getCreatedAt());//maintain same create_at

                    return Mono.fromRunnable(() -> vs.validate(entityToEdit))
                            .then(routeRepo.save(entityToEdit))
                            //same id: the writer replaces the old definition
                            .flatMap(saved -> apply(List.of(saved), List.of()))
                            .map(List::getFirst);
                });
    }

    /**
     * Find a route by its id, or null if it's not found.
     *
     * @param routeId The id of the route to find.
     */
    public Mono<RouteConfigResponse> findById(String routeId) {
        return findEntity(routeId).map(this::buildResponse);
    }

    /**
     * The route with this id: `400` if the id isn't a UUID, `404` if there is none
     */
    private Mono<RouteEntity> findEntity(String routeId) {
        UUID id;
        try {
            id = UUID.fromString(routeId);
        } catch (IllegalArgumentException e) {
            return Mono.error(new BadRequestException("Route id must be a UUID: %s".formatted(routeId)));
        }
        return routeRepo.findById(id)
                .switchIfEmpty(Mono.error(new NotFoundException("Route does not exist: %s".formatted(routeId))));
    }

    /**
     * Find a cached route by its id, or null if it's not found.
     * This method DON'T make a DB request.
     *
     * @param routeId The id of the route to find.
     */
    @Override
    public RouteEntity findCachedById(String routeId) {
        return cache.get(routeId);
    }

    /**
     * Delete a route from the gateway
     *
     * @param routeId The name of the route to delete
     */
    public Mono<Void> deleteRoute(String routeId) {
        // Search old route
        return findEntity(routeId)
                .flatMap(route -> {
                    //use the normalized id, not the raw one (could be in uppercase and not match the cache/writer keys)
                    String id = route.getRouteId().toString();
                    return routeRepo.delete(route) // Delete route from db
                            //if route is deleted ok in db, delete it in cache (for faster http logs access)
                            .then(Mono.fromRunnable(() -> cache.remove(id)))
                            .then(
                                    routeDefinitionWriter.delete( // Delete route from writer
                                            Mono.just(id)
                                    ).onErrorResume(org.springframework.cloud.gateway.support.NotFoundException.class, e -> Mono.empty())
                            );
                })
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
     * Get the routes as saved in cache... in theory this should have the same result as `getRoutes`.
     * We still provide both methods... maybe a change was made direct to db....
     * <p>
     * This method DON'T make a DB request.
     */
    @Override
    public List<RouteEntity> getCacheRoutes() {
        return cache.values().stream().toList();
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
                //to the microsecond, what postgres keeps: the answer of a save matches a later read
                OffsetDateTime.now().truncatedTo(ChronoUnit.MICROS)
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
