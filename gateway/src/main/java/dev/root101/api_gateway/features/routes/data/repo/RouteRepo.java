package dev.root101.api_gateway.features.routes.data.repo;

import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Repository
public interface RouteRepo extends ReactiveCrudRepository<RouteEntity, UUID> {

    Mono<RouteEntity> findByName(String name);
}
