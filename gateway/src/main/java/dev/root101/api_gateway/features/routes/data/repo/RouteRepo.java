package dev.root101.api_gateway.features.routes.data.repo;

import dev.root101.api_gateway.config.LocalizedException;
import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.http.HttpStatus;
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
            return Mono.error(new LocalizedException(HttpStatus.BAD_REQUEST, "route.id.invalid", routeId));
        }
        return findById(id)
                .switchIfEmpty(Mono.error(new LocalizedException(HttpStatus.NOT_FOUND, "route.not_found", routeId)));
    }
}
