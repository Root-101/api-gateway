package dev.root101.api_gateway.features.http_logs.task;

import dev.root101.api_gateway.features.http_logs.data.repo.HttpLogRepo;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import reactor.core.publisher.Mono;

import java.time.OffsetDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CleanUpOldLogsTest {

    @Test
    void deletesInBatchesUntilAPartialOne() {
        HttpLogRepo repo = mock(HttpLogRepo.class);
        when(repo.deleteBatchByRequestedAtBefore(any(OffsetDateTime.class), eq(CleanUpOldLogs.BATCH_SIZE)))
                .thenReturn(Mono.just((long) CleanUpOldLogs.BATCH_SIZE), Mono.just((long) CleanUpOldLogs.BATCH_SIZE), Mono.just(7L));
        CleanUpOldLogs task = new CleanUpOldLogs(repo);
        ReflectionTestUtils.setField(task, "maintainLogsFor", 14);

        assertThat(task.cleanUpLogs().block()).isEqualTo(CleanUpOldLogs.BATCH_SIZE * 2L + 7);
        verify(repo, times(3)).deleteBatchByRequestedAtBefore(any(OffsetDateTime.class), eq(CleanUpOldLogs.BATCH_SIZE));
    }

    @Test
    void limitIsNowMinusTheDays() {
        HttpLogRepo repo = mock(HttpLogRepo.class);
        when(repo.deleteBatchByRequestedAtBefore(any(OffsetDateTime.class), anyInt())).thenReturn(Mono.just(0L));
        CleanUpOldLogs task = new CleanUpOldLogs(repo);
        ReflectionTestUtils.setField(task, "maintainLogsFor", 3);

        OffsetDateTime before = OffsetDateTime.now().minusDays(3);
        task.cleanUpLogs().block();
        OffsetDateTime after = OffsetDateTime.now().minusDays(3);

        verify(repo).deleteBatchByRequestedAtBefore(argThat(d -> !d.isBefore(before) && !d.isAfter(after)), anyInt());
    }
}
