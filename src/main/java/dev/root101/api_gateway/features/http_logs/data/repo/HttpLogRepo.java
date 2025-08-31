package dev.root101.api_gateway.features.http_logs.data.repo;

import dev.root101.api_gateway.features.http_logs.data.entity.HttpLogEntity;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.time.OffsetDateTime;
import java.util.UUID;

@Repository
public interface HttpLogRepo extends ReactiveCrudRepository<HttpLogEntity, UUID> {
    @org.springframework.data.r2dbc.repository.Query(
            "DELETE FROM http_log WHERE requested_at < :date"
    )
    Mono<Void> deleteAllByRequestedAtBefore(OffsetDateTime date);
}
