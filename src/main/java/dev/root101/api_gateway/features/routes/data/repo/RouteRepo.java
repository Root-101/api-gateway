package dev.root101.api_gateway.features.routes.data.repo;

import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Repository
public interface RouteRepo extends ReactiveCrudRepository<RouteEntity, UUID> {

    Mono<RouteEntity> findByName(String name);

    /**
     * Since the ID is of UUID type, it is necessary to validate beforehand whether it is valid. </br>
     * In addition to parsing a String to a UUID type Object. </br>
     *
     * @param id The raw uuid
     * @return Found RouteEntity, or empty in any other case
     */
    default Mono<RouteEntity> findByRawId(String id) {
        try {
            return findById(UUID.fromString(id));
        } catch (IllegalArgumentException e) {
            return Mono.empty();
        }
    }
}
