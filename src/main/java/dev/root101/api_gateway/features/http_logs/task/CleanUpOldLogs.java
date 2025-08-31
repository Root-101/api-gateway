package dev.root101.api_gateway.features.http_logs.task;

import dev.root101.api_gateway.features.http_logs.data.repo.HttpLogRepo;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.reactive.TransactionalOperator;
import reactor.core.publisher.Mono;

import java.time.OffsetDateTime;

@Service
public class CleanUpOldLogs {

    @Value("${app.logs.maintainForDays}")
    private int maintainLogsFor;

    private final HttpLogRepo logRepo;
    private final TransactionalOperator operator;

    public CleanUpOldLogs(
            HttpLogRepo logRepo,
            TransactionalOperator operator
    ) {
        this.logRepo = logRepo;
        this.operator = operator;
    }

    //Run when service start
    @EventListener(ApplicationReadyEvent.class)
    public void onStartup() {
        System.out.println("---------- CleanUpOldLogs : onStartup ----------");
        cleanUpLogs().subscribe();
    }

    //execute task every day at 00:00:00
    //docs del crono: https://reflectoring.io/spring-scheduler/
    @Scheduled(cron = "0 0 0 * * *")
    public void onSchedule() {
        System.out.println("---------- CleanUpOldLogs : onSchedule----------");
        cleanUpLogs().subscribe();
    }

    /**
     * Delete old logs
     */
    public Mono<Void> cleanUpLogs() {
        try {
            OffsetDateTime limitDate = OffsetDateTime.now().minusDays(maintainLogsFor);

            return logRepo.deleteAllByRequestedAtBefore(limitDate)
                    .as(operator::transactional)
                    .doOnError(err -> System.err.println("Error cleaning logs: " + err.getMessage()))
                    .doOnSuccess(ignored -> System.out.println("Success clean of logs"));
        } catch (Exception ignored) {
        }
        return Mono.empty();
    }
}
