package dev.root101.api_gateway.core.feature.health.logic.usecase;

import org.springframework.r2dbc.core.DatabaseClient;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.time.Duration;

@Service
class HealthUseCase_Impl implements HealthUseCase {

    private final DatabaseClient db;

    HealthUseCase_Impl(DatabaseClient db) {
        this.db = db;
    }

    @Override
    public Mono<Boolean> isUp() {
        return db.sql("SELECT 1").fetch().rowsUpdated()
                .timeout(Duration.ofSeconds(3))
                .map(ok -> true)
                .onErrorReturn(false);
    }
}
