package dev.root101.api_gateway.features.http_logs.data.repo;

import dev.root101.api_gateway.features.http_logs.data.entity.HttpLogEntity;
import jakarta.annotation.PreDestroy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.transaction.reactive.TransactionalOperator;
import reactor.core.Disposable;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Writes the http logs out of the request path: requests only put the log in a bounded queue,
 * and a single background loop inserts them in batches (one db connection at most).
 * When the queue is full (db slow or down) new logs are dropped and counted, real traffic is never slowed down.
 */
@Component
public class HttpLogWriter {

    private static final Logger log = LoggerFactory.getLogger(HttpLogWriter.class);

    static final int QUEUE_CAPACITY = 10_000;
    static final int BATCH_SIZE = 500;
    static final Duration FLUSH_INTERVAL = Duration.ofSeconds(1);

    private final HttpLogRepo repo;
    private final TransactionalOperator tx;
    private final BlockingQueue<HttpLogEntity> queue;
    private final AtomicLong dropped = new AtomicLong();
    private final Disposable loop;

    @Autowired
    public HttpLogWriter(HttpLogRepo repo, TransactionalOperator tx) {
        this(repo, tx, QUEUE_CAPACITY, FLUSH_INTERVAL);
    }

    HttpLogWriter(HttpLogRepo repo, TransactionalOperator tx, int queueCapacity, Duration flushInterval) {
        this.repo = repo;
        this.tx = tx;
        this.queue = new ArrayBlockingQueue<>(queueCapacity);
        this.loop = Flux.interval(flushInterval)
                .onBackpressureDrop()
                .concatMap(tick -> flush(), 1)
                .subscribe();
    }

    /**
     * Never blocks: if the queue is full the log is dropped.
     */
    public void enqueue(HttpLogEntity entity) {
        if (!queue.offer(entity)) {
            dropped.incrementAndGet();
        }
    }

    public long droppedCount() {
        return dropped.get();
    }

    /**
     * Saves everything queued, in batches of {@link #BATCH_SIZE}, each batch in its own transaction.
     */
    Mono<Void> flush() {
        long lost = dropped.getAndSet(0);
        if (lost > 0) {
            log.warn("{} http logs dropped: queue full (db slow or down)", lost);
        }
        List<HttpLogEntity> batch = new ArrayList<>(BATCH_SIZE);
        queue.drainTo(batch, BATCH_SIZE);
        if (batch.isEmpty()) {
            return Mono.empty();
        }
        return repo.saveAll(batch)
                .then()
                .as(tx::transactional)
                .onErrorResume(e -> {
                    log.error("Error saving {} http logs, they are lost", batch.size(), e);
                    return Mono.empty();
                })
                .then(Mono.defer(() -> batch.size() == BATCH_SIZE ? flush() : Mono.empty()));
    }

    @PreDestroy
    void shutdown() {
        loop.dispose();
        try {
            flush().block(Duration.ofSeconds(10));
        } catch (Exception e) {
            log.error("Error saving the pending http logs on shutdown", e);
        }
    }
}
