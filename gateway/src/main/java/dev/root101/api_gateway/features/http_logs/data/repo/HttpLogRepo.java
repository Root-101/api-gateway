package dev.root101.api_gateway.features.http_logs.data.repo;

import dev.root101.api_gateway.features.http_logs.data.entity.HttpLogEntity;
import org.springframework.data.r2dbc.repository.Modifying;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.time.OffsetDateTime;
import java.util.UUID;

@Repository
public interface HttpLogRepo extends ReactiveCrudRepository<HttpLogEntity, UUID> {

    /**
     * Deletes up to `limit` logs older than `date`, returns how many were deleted.
     */
    @Modifying
    @Query("DELETE FROM http_log WHERE http_log_id IN (SELECT http_log_id FROM http_log WHERE requested_at < :date LIMIT :limit)")
    Mono<Long> deleteBatchByRequestedAtBefore(OffsetDateTime date, int limit);
}
