package dev.root101.api_gateway.features.settings.data.repo;

import dev.root101.api_gateway.features.settings.data.entity.SettingEntity;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Repository
public interface SettingRepo extends ReactiveCrudRepository<SettingEntity, UUID> {

    /**
     * Every value of a key: the gateway's one and each route's
     */
    Flux<SettingEntity> findByKey(String key);

    Mono<SettingEntity> findByRouteIdAndKey(UUID routeId, String key);

    Mono<SettingEntity> findByRouteIdIsNullAndKey(String key);
}
