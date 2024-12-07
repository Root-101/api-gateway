package dev.root101.api_gateway.feature.data.repo;

import dev.root101.api_gateway.feature.data.entity.RouteEntity;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

@Repository
public interface RouteRepo extends ReactiveCrudRepository<RouteEntity, Integer> {

    Mono<RouteEntity> findByName(String name);
}
