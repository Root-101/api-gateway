package dev.root101.api_gateway.core.feature.routes.logic.usecase;

import lombok.extern.slf4j.Slf4j;
import dev.root101.api_gateway.core.feature.addons.base.logic.model.AddonsRequest;
import dev.root101.api_gateway.core.feature.addons.base.logic.usecase.AddonsUseCase;
import dev.root101.api_gateway.core.feature.routes.data.entity.RouteEntity;
import dev.root101.api_gateway.core.feature.routes.data.repo.RouteRepo;
import dev.root101.api_gateway.core.feature.routes.logic.model.RouteRequest;
import dev.root101.api_gateway.core.feature.routes.logic.model.RouteResponse;
import dev.root101.api_gateway.core.feature.routes.logic.usecase.RouteDefinitionMapper;
import dev.root101.api_gateway.core.feature.routes.logic.usecase.RouteUpdater;
import dev.root101.api_gateway.core.error.Errors;
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
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * This is the class who really make the modifications in the routes.
 * At the end of every action the context is updated and the change is ready to use.
 */
@Slf4j
@Service
class RouteUseCase_Impl implements RouteUseCase, SmartInitializingSingleton {

    private final RouteDefinitionWriter routeDefinitionWriter;

    private final RouteUpdater routeUpdater;

    private final RouteRepo routeRepo;


    private final TransactionalOperator tx;

    private final AddonsUseCase addonsUseCase;

    private final Map<String, RouteEntity> cache = new ConcurrentHashMap<>();

    public RouteUseCase_Impl(
            RouteDefinitionWriter routeDefinitionWriter,
            RouteUpdater routeUpdater,
            RouteRepo routeRepo,
            TransactionalOperator tx,
            AddonsUseCase addonsUseCase
    ) {
        this.routeDefinitionWriter = routeDefinitionWriter;
        this.routeUpdater = routeUpdater;
        this.routeRepo = routeRepo;
        this.tx = tx;
        this.addonsUseCase = addonsUseCase;
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
        //no refresh needed: the gateway reads the routes on its first request
        log.info("{} routes loaded", count);
    }

    /**
     * Add a single route
     *
     * @param request The route to add
     * @return The created route
     */
    public Mono<RouteResponse> addRoute(RouteRequest request, Locale locale) {
        return addAllRoutes(List.of(request), locale).map(List::getFirst);
    }

    /**
     * Create multiple routes at the same time, all or nothing
     *
     * @param requests List of routes to create
     * @return The created routes
     */
    public Mono<List<RouteResponse>> addAllRoutes(List<RouteRequest> requests, Locale locale) {
        return withoutDuplicatedNames(requests)
                // Check for duplicates in the database
                .concatMap(
                        request -> routeRepo.findByName(request.getName())
                                .flatMap(existing -> Mono.<RouteRequest>error(Errors.conflict("route.exists", request.getName())))
                                .switchIfEmpty(Mono.just(request))
                )
                .map(this::buildEntity)
                .collectList()
                .flatMap(
                        //all or nothing: a failure in the middle must not leave half the routes in db
                        entities -> routeRepo.saveAll(entities).collectList().as(tx::transactional)
                )
                .flatMap(saved -> apply(saved, List.of()))
                .map(saved -> responses(saved, locale));
    }

    /**
     * Replace every route with the given ones, all or nothing. A route whose name already exists keeps its id
     * (its creation date and its add-ons), so its logs still find it; the others get new ids. The add-ons of each
     * route: a key with a value is saved, a key `null` is deleted, a key or `addons` not sent is kept (see
     * {@link AddonsUseCase#restore}).
     *
     * @param requests The routes that will exist after the call
     * @return The routes, as saved
     */
    public Mono<List<RouteResponse>> replaceAllRoutes(List<RouteRequest> requests, Locale locale) {
        return withoutDuplicatedNames(requests)
                .map(this::buildEntity)
                .collectList()
                .flatMap(
                        entities -> routeRepo.findAll().collectMap(RouteEntity::getName)
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
                                            .flatMap(saved -> restoreAddons(saved, requests).thenReturn(saved))
                                            .as(tx::transactional)
                                            .flatMap(saved -> addonsUseCase.reload()
                                                    .then(Mono.defer(() -> apply(saved, removed))));
                                })
                )
                .map(saved -> responses(saved, locale));
    }

    /**
     * The add-ons that come with each route (by name), in the transaction of the caller
     */
    private Mono<Void> restoreAddons(List<RouteEntity> saved, List<RouteRequest> requests) {
        Map<String, AddonsRequest> byName = new HashMap<>();
        for (RouteRequest request : requests) {
            if (request.getAddons() != null) byName.put(request.getName(), request.getAddons());
        }
        return Flux.fromIterable(saved)
                .filter(entity -> byName.containsKey(entity.getName()))
                .concatMap(entity -> addonsUseCase.restore(entity.getRouteId(), byName.get(entity.getName())))
                .then();
    }

    /**
     * Puts the saved routes in the cache and the gateway (replacing the ones with the same id), removes the
     * deleted ones, and refreshes the routes in use
     */
    private Mono<List<RouteEntity>> apply(List<RouteEntity> saved, List<RouteEntity> removed) {
        saved.forEach(entity -> cache.put(entity.getRouteId().toString(), entity));
        removed.forEach(entity -> cache.remove(entity.getRouteId().toString()));
        return Flux.fromIterable(removed)
                //a route saved in db by another instance isn't in this gateway: nothing to remove
                .concatMap(entity -> routeDefinitionWriter.delete(Mono.just(entity.getRouteId().toString()))
                        .onErrorResume(org.springframework.cloud.gateway.support.NotFoundException.class, e -> Mono.empty()))
                .thenMany(Flux.fromIterable(saved))
                .concatMap(entity -> routeDefinitionWriter.save(Mono.just(buildDefinition(entity))))
                .then(Mono.defer(routeUpdater::updateRoutes))
                .thenReturn(saved);
    }

    /**
     * The given routes, or a `409` if two of them have the same name
     */
    private Flux<RouteRequest> withoutDuplicatedNames(List<RouteRequest> requests) {
        return Flux.fromIterable(requests)
                .collectMultimap(RouteRequest::getName)
                .flatMapMany(frequencyMap -> {
                    for (Map.Entry<String, Collection<RouteRequest>> entry : frequencyMap.entrySet()) {
                        if (entry.getValue().size() > 1) {
                            return Mono.error(Errors.conflict("route.duplicated", entry.getKey()));
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
    public Mono<RouteResponse> editRoute(String routeId, RouteRequest request, Locale locale) {
        return findEntity(routeId)
                //the new name can't be used by another route
                .flatMap(oldRoute -> routeRepo.findByName(request.getName())
                        .filter(existing -> !existing.getRouteId().equals(oldRoute.getRouteId()))
                        .flatMap(existing -> Mono.<RouteEntity>error(Errors.conflict("route.exists", request.getName())))
                        .defaultIfEmpty(oldRoute)
                )
                .flatMap(oldRoute -> {
                    RouteEntity entityToEdit = buildEntity(request);
                    entityToEdit.setRouteId(oldRoute.getRouteId());//maintain same id
                    entityToEdit.setCreatedAt(oldRoute.getCreatedAt());//maintain same create_at

                    boolean uriChanged = !entityToEdit.getUri().equals(oldRoute.getUri());
                    return routeRepo.save(entityToEdit)
                            //same id: the writer replaces the old definition
                            .flatMap(saved -> apply(List.of(saved), List.of()))
                            //before answering: the add-ons in the response already have the new service's result
                            .flatMap(edited -> (uriChanged ? addonsUseCase.uriChanged(routeId) : Mono.<Void>empty())
                                    .then(Mono.fromSupplier(() -> response(edited.getFirst(), locale))));
                });
    }

    /**
     * Find a route by its id: `400` if it is not a UUID, `404` if there is none.
     *
     * @param routeId The id of the route to find.
     */
    public Mono<RouteResponse> findById(String routeId, Locale locale) {
        return findEntity(routeId).map(route -> response(route, locale));
    }

    /**
     * The route with this id: `400` if the id isn't a UUID, `404` if there is none
     */
    private Mono<RouteEntity> findEntity(String routeId) {
        return routeRepo.findExisting(routeId);
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
                .then(Mono.defer(routeUpdater::updateRoutes)) // Update route after all changes
                //its add-ons were deleted with it in db (cascade)
                .then(addonsUseCase.reload());
    }

    /**
     * This can also be achieved with:
     * 1 - Receiving in constructor: `RouteDefinitionLocator routeDefinition;`
     * 2 - Calling `routeDefinitionLocator.getRouteDefinitions();`
     * 3 - This will return `Flux<RouteConfigModel>`
     */
    public Flux<RouteResponse> getRoutes(Locale locale) {
        return routeRepo.findAll().map(route -> response(route, locale));
    }

    /**
     * Convert the `RouteConfigModel` into a `RouteEntity`
     *
     * @param routeModel The model to convert into `RouteEntity`
     * @return The parsed `RouteEntity`
     */
    private RouteEntity buildEntity(RouteRequest routeModel) {
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
     * The route as answered, with its add-ons as they are now: their texts in the request's language
     */
    private RouteResponse response(RouteEntity entity, Locale locale) {
        return RouteResponse.build(entity, addonsUseCase.ofRoute(entity.getRouteId().toString(), locale));
    }

    private List<RouteResponse> responses(List<RouteEntity> entities, Locale locale) {
        return entities.stream().map(entity -> response(entity, locale)).toList();
    }
}
