package dev.root101.api_gateway.features.addons.data.repo;

import dev.root101.api_gateway.features.addons.data.entity.AddonEntity;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Repository
public interface AddonRepo extends ReactiveCrudRepository<AddonEntity, UUID> {

    /**
     * Every add-on of a type: the gateway's one and each route's
     */
    Flux<AddonEntity> findByType(String type);

    Mono<AddonEntity> findByRouteIdAndType(UUID routeId, String type);

    Mono<AddonEntity> findByRouteIdIsNullAndType(String type);
}
