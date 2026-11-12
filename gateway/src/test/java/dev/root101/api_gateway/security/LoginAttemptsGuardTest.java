package dev.root101.api_gateway.security;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class LoginAttemptsGuardTest {

    @Test
    void locksAfterMaxTriesAndUnlocksOnSuccess() {
        LoginAttemptsGuard guard = new LoginAttemptsGuard(2, 15);
        assertThat(guard.tryAcquire("1.1.1.1")).isTrue();
        assertThat(guard.tryAcquire("1.1.1.1")).isTrue();
        assertThat(guard.tryAcquire("1.1.1.1")).isFalse();
        assertThat(guard.retryAfterSeconds("1.1.1.1")).isBetween(1L, 900L);
        assertThat(guard.tryAcquire("2.2.2.2")).isTrue();

        guard.succeeded("1.1.1.1");
        assertThat(guard.retryAfterSeconds("1.1.1.1")).isZero();
        assertThat(guard.tryAcquire("1.1.1.1")).isTrue();
    }

    @Test
    void concurrentTriesNeverExceedTheLimit() throws Exception {
        LoginAttemptsGuard guard = new LoginAttemptsGuard(5, 15);
        java.util.concurrent.atomic.AtomicInteger taken = new java.util.concurrent.atomic.AtomicInteger();
        try (var pool = java.util.concurrent.Executors.newFixedThreadPool(16)) {
            for (int i = 0; i < 200; i++) {
                pool.submit(() -> {
                    if (guard.tryAcquire("3.3.3.3")) taken.incrementAndGet();
                });
            }
        }
        assertThat(taken.get()).isEqualTo(5);
    }

    @Test
    void nullIpIsOneKey() {
        LoginAttemptsGuard guard = new LoginAttemptsGuard(1, 15);
        assertThat(guard.tryAcquire(null)).isTrue();
        assertThat(guard.tryAcquire(null)).isFalse();
    }

    @Test
    void windowExpires() {
        //0 minutes window: every try is already expired
        LoginAttemptsGuard guard = new LoginAttemptsGuard(1, 0);
        assertThat(guard.tryAcquire("1.1.1.1")).isTrue();
        assertThat(guard.tryAcquire("1.1.1.1")).isTrue();
        assertThat(guard.retryAfterSeconds("1.1.1.1")).isZero();
        guard.purgeExpired();
    }

    @Test
    void disabledWithZeroAttempts() {
        LoginAttemptsGuard guard = new LoginAttemptsGuard(0, 15);
        for (int i = 0; i < 100; i++) assertThat(guard.tryAcquire("1.1.1.1")).isTrue();
        assertThat(guard.retryAfterSeconds("1.1.1.1")).isZero();
    }
}
