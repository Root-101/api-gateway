package dev.root101.api_gateway.features.http_logs.task;

import dev.root101.api_gateway.features.http_logs.data.repo.HttpLogRepo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.time.OffsetDateTime;

@Service
public class CleanUpOldLogs {

    private static final Logger log = LoggerFactory.getLogger(CleanUpOldLogs.class);

    //small deletes, each in its own transaction: no long locks or huge transactions on a big table
    static final int BATCH_SIZE = 10_000;

    @Value("${app.logs.maintainForDays}")
    private int maintainLogsFor;

    private final HttpLogRepo logRepo;

    public CleanUpOldLogs(HttpLogRepo logRepo) {
        this.logRepo = logRepo;
    }

    //Run when service start
    @EventListener(ApplicationReadyEvent.class)
    public void onStartup() {
        cleanUpLogs().subscribe();
    }

    //execute task every day at 00:00:00
    //cron docs: https://reflectoring.io/spring-scheduler/
    @Scheduled(cron = "0 0 0 * * *")
    public void onSchedule() {
        cleanUpLogs().subscribe();
    }

    /**
     * Delete old logs, in batches
     */
    public Mono<Long> cleanUpLogs() {
        OffsetDateTime limitDate = OffsetDateTime.now().minusDays(maintainLogsFor);
        return deleteFrom(limitDate, 0)
                .doOnSuccess(total -> log.info("Old logs clean up done: {} logs deleted", total))
                .doOnError(err -> log.error("Error cleaning old logs", err));
    }

    private Mono<Long> deleteFrom(OffsetDateTime limitDate, long deletedSoFar) {
        return logRepo.deleteBatchByRequestedAtBefore(limitDate, BATCH_SIZE)
                .flatMap(deleted -> deleted < BATCH_SIZE
                        ? Mono.just(deletedSoFar + deleted)
                        : deleteFrom(limitDate, deletedSoFar + deleted));
    }
}
