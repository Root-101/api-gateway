package dev.root101.api_gateway.features.health.rest;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.r2dbc.core.DatabaseClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.Map;

/**
 * Health check for load balancers and orchestrators: no auth, not logged.
 * `up` when the gateway answers and so does its database, else `503` with `down`.
 */
@RestController
@RequestMapping("/${app.admin.base-path}/health")
public class HealthController {

    private final DatabaseClient db;

    public HealthController(DatabaseClient db) {
        this.db = db;
    }

    @GetMapping
    public Mono<ResponseEntity<Map<String, String>>> health() {
        return db.sql("SELECT 1").fetch().rowsUpdated()
                .timeout(Duration.ofSeconds(3))
                .map(ok -> ResponseEntity.ok(Map.of("status", "up")))
                .onErrorReturn(ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of("status", "down")));
    }
}
