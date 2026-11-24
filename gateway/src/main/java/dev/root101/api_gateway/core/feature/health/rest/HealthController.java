package dev.root101.api_gateway.core.feature.health.rest;

import dev.root101.api_gateway.core.feature.health.logic.usecase.HealthUseCase;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.util.Map;

/**
 * Health check for load balancers and orchestrators: no auth, not logged.
 * `up` when the gateway answers and so does its database, else `503` with `down`.
 */
@RestController
@RequestMapping("/${app.admin.base-path}/health")
public class HealthController {

    private final HealthUseCase healthUseCase;

    public HealthController(HealthUseCase healthUseCase) {
        this.healthUseCase = healthUseCase;
    }

    @GetMapping
    public Mono<ResponseEntity<Map<String, String>>> health() {
        return healthUseCase.isUp().map(up -> up
                ? ResponseEntity.ok(Map.of("status", "up"))
                : ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of("status", "down")));
    }
}
