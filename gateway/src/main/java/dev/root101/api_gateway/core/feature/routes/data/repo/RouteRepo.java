package dev.root101.api_gateway.core.feature.routes.data.repo;

import dev.root101.api_gateway.core.error.Errors;
import dev.root101.api_gateway.core.feature.routes.data.entity.RouteEntity;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Repository
public interface RouteRepo extends ReactiveCrudRepository<RouteEntity, UUID> {

    Mono<RouteEntity> findByName(String name);

    /**
     * The route of an id as it comes in a path: `400` if it isn't a UUID, `404` if there is no such route
     */
    default Mono<RouteEntity> findExisting(String routeId) {
        UUID id;
        try {
            id = UUID.fromString(routeId);
        } catch (IllegalArgumentException e) {
            return Mono.error(Errors.badRequest("error.route.invalid-id", routeId));
        }
        return findById(id)
                .switchIfEmpty(Mono.error(Errors.notFound("error.route.not-found", routeId)));
    }
}
