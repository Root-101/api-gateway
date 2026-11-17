package dev.root101.api_gateway.features.addons.data.repo;

import dev.root101.api_gateway.features.addons.data.entity.AddonEntity;
import org.springframework.data.r2dbc.repository.Modifying;
import org.springframework.data.r2dbc.repository.Query;
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

    /**
     * Writes only the `state` of a route's add-on, never its `config` or `updated_at`: a job never overwrites an edit
     * of the admin. Nothing when it was deleted meanwhile.
     */
    @Modifying
    @Query("UPDATE addon SET state = CAST(:state AS jsonb) WHERE route_id = :routeId AND type = :type")
    Mono<Long> updateState(UUID routeId, String type, String state);
}
