package dev.root101.api_gateway.features.http_logs.data.repo;

import dev.root101.api_gateway.features.http_logs.data.entity.HttpLogEntity;
import org.junit.jupiter.api.Test;
import org.springframework.transaction.reactive.TransactionalOperator;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class HttpLogWriterTest {

    private final List<Integer> savedBatches = new ArrayList<>();

    @SuppressWarnings("unchecked")
    private HttpLogWriter writer(int capacity) {
        HttpLogRepo repo = mock(HttpLogRepo.class);
        when(repo.saveAll(any(Iterable.class))).thenAnswer(inv -> {
            List<HttpLogEntity> batch = new ArrayList<>();
            ((Iterable<HttpLogEntity>) inv.getArgument(0)).forEach(batch::add);
            savedBatches.add(batch.size());
            return Flux.fromIterable(batch);
        });
        TransactionalOperator tx = mock(TransactionalOperator.class);
        when(tx.transactional(any(Mono.class))).thenAnswer(inv -> inv.getArgument(0));
        //long interval: the test calls flush() itself
        return new HttpLogWriter(repo, tx, capacity, Duration.ofHours(1));
    }

    private static HttpLogEntity entity() {
        return new HttpLogEntity(null, "127.0.0.1", OffsetDateTime.now(), null, "GET", "/x", 200, 1, null);
    }

    @Test
    void dropsWhenQueueIsFull() {
        HttpLogWriter writer = writer(2);
        writer.enqueue(entity());
        writer.enqueue(entity());
        writer.enqueue(entity());

        assertThat(writer.droppedCount()).isEqualTo(1);
        writer.flush().block();
        assertThat(savedBatches).containsExactly(2);
        assertThat(writer.droppedCount()).isZero();
    }

    @Test
    void flushSavesEverythingInBatches() {
        HttpLogWriter writer = writer(HttpLogWriter.BATCH_SIZE * 3);
        for (int i = 0; i < HttpLogWriter.BATCH_SIZE * 2 + 3; i++) {
            writer.enqueue(entity());
        }

        writer.flush().block();

        assertThat(savedBatches).containsExactly(HttpLogWriter.BATCH_SIZE, HttpLogWriter.BATCH_SIZE, 3);
    }
}
