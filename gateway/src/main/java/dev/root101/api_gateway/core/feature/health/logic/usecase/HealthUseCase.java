package dev.root101.api_gateway.core.feature.health.logic.usecase;

import reactor.core.publisher.Mono;

public interface HealthUseCase {

    /**
     * Whether the database answers within 3 s; never an error
     */
    Mono<Boolean> isUp();
}
