package dev.root101.api_gateway.features.routes.logic.usecase;

import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import dev.root101.api_gateway.features.routes.data.repo.RouteRepo;
import dev.root101.api_gateway.features.routes.logic.model.RewritePathModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigResponse;
import dev.root101.api_gateway.features.routes.logic.model.RouteRules;
import dev.root101.api_gateway.features.routes.utils.RouteDefinitionMapper;
import dev.root101.api_gateway.features.routes.utils.RouteRulesJson;
import dev.root101.api_gateway.features.routes.utils.RouteUpdater;
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
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

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
     * @return Void
     */
    public Mono<Void> addRoute(RouteConfigRequest request) {
        //find any route with same name
        return routeRepo.findByName(request.getName())
                //if a route is found, throw error (can't have two routes with same name)
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
                                                    //if route is saved ok in db, save it to cache (for faster http logs access)
                                                    .doOnNext(
                                                            routeEntity -> cache.put(
                                                                    routeEntity.getRouteId().toString(),
                                                                    entity
                                                            )
                                                    )
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
                                        //all or nothing: a failure in the middle must not leave half the routes in db
                                        routeRepo.saveAll(entities).collectList().as(tx::transactional)
                                                //if routes are saved ok in db, save it to cache (for faster http logs access)
                                                .doOnNext(
                                                        savedEntities -> cache.putAll(
                                                                savedEntities.stream()
                                                                        .collect(Collectors.toMap(
                                                                                routeEntity -> routeEntity.getRouteId().toString(),
                                                                                routeEntity -> routeEntity
                                                                        ))
                                                        )
                                                )
                                )
                )
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
                            .then(
                                    routeRepo.save(entityToEdit)
                                            //if route is edited ok in db, updated it to cache (for faster http logs access)
                                            .doOnNext(
                                                    routeEntity -> cache.put(
                                                            routeEntity.getRouteId().toString(),
                                                            entityToEdit
                                                    )
                                            ).flatMap(
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
     * Find a route by its id, or null if it's not found.
     *
     * @param routeId The id of the route to find.
     */
    public Mono<RouteConfigResponse> findById(String routeId) {
        return routeRepo.findByRawId(routeId)
                .switchIfEmpty(
                        Mono.error(
                                new NotFoundException("Route does not exist: %s".formatted(routeId))
                        )
                )
                .map(this::buildResponse);
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
        return routeRepo.findByRawId(routeId)
                .switchIfEmpty(Mono.error(new NotFoundException("Route does not exist: %s".formatted(routeId))))
                .flatMap(route -> {
                    //use the normalized id, not the raw one (could be in uppercase and not match the cache/writer keys)
                    String id = route.getRouteId().toString();
                    return routeRepo.delete(route) // Delete route from db
                            //if route is deleted ok in db, delete it in cache (for faster http logs access)
                            .then(Mono.fromRunnable(() -> cache.remove(id)))
                            .then(
                                    routeDefinitionWriter.delete( // Delete route from writer
                                            Mono.just(id)
                                    )
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
                OffsetDateTime.now(),
                routeModel.getOrder() != null ? routeModel.getOrder() : 0,
                RouteRulesJson.toJson(new RouteRules(routeModel.getMethods(), routeModel.getHosts(), routeModel.getHeaders(), routeModel.getFilters()))
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
        RouteRules rules = RouteRulesJson.fromJson(entity.getRules());
        return new RouteConfigResponse(
                entity.getRouteId().toString(),
                entity.getName(),
                entity.getPath(),
                entity.getUri(),
                entity.getRewritePathFrom() != null && entity.getRewritePathTo() != null ? new RewritePathModel(entity.getRewritePathFrom(), entity.getRewritePathTo()) : null,
                entity.getDescription(),
                entity.getCreatedAt(),
                entity.getRouteOrder(),
                rules.methods(),
                rules.hosts(),
                rules.headers(),
                rules.filters()
        );
    }
}
