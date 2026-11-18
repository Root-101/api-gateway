package dev.root101.api_gateway.features.rate_limit.logic.usecase;

import dev.root101.api_gateway.features.rate_limit.logic.model.RateLimit;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

class TokenBucketTest {

    private static final long SECOND = 1_000_000_000L;

    @Test
    void startsFullWithTheLimit() {
        TokenBucket bucket = new TokenBucket(new RateLimit(true, 3, "minute", null), 0);
        assertThat(bucket.take(0)).isZero();
        assertThat(bucket.take(0)).isZero();
        assertThat(bucket.take(0)).isZero();
        //3 per minute: one more every 20 s
        assertThat(bucket.take(0)).isCloseTo(20 * SECOND, within(10L));
    }

    @Test
    void burstIsTheSizeOfTheBucket() {
        TokenBucket bucket = new TokenBucket(new RateLimit(true, 1, "second", 5), 0);
        for (int i = 0; i < 5; i++) assertThat(bucket.take(0)).isZero();
        assertThat(bucket.take(0)).isCloseTo(SECOND, within(10L));
    }

    @Test
    void fillsBackWithTimeUpToItsSize() {
        TokenBucket bucket = new TokenBucket(new RateLimit(true, 2, "second", null), 0);
        bucket.take(0);
        bucket.take(0);
        assertThat(bucket.full(0)).isFalse();
        //0.6 s: one back (2 per second), and 0.2 of the next: 0.4 s to wait
        assertThat(bucket.take(SECOND * 6 / 10)).isZero();
        assertThat(bucket.take(SECOND * 6 / 10)).isCloseTo(SECOND * 4 / 10, within(10L));
        //long after: full, never more than its size
        assertThat(bucket.full(100 * SECOND)).isTrue();
        assertThat(bucket.take(100 * SECOND)).isZero();
        assertThat(bucket.take(100 * SECOND)).isZero();
        assertThat(bucket.take(100 * SECOND)).isPositive();
    }

    @Test
    void periods() {
        assertThat(new TokenBucket(new RateLimit(true, 1, "hour", null), 0).take(0)).isZero();
        TokenBucket hour = new TokenBucket(new RateLimit(true, 1, "hour", null), 0);
        hour.take(0);
        assertThat(hour.take(0)).isCloseTo(3600 * SECOND, within(10L));
    }
}
