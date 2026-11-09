package dev.root101.api_gateway.security;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class LoginAttemptsGuardTest {

    @Test
    void locksAfterMaxFailuresAndUnlocksOnSuccess() {
        LoginAttemptsGuard guard = new LoginAttemptsGuard(2, 15);
        guard.failed("1.1.1.1");
        assertThat(guard.isLocked("1.1.1.1")).isFalse();
        guard.failed("1.1.1.1");
        assertThat(guard.isLocked("1.1.1.1")).isTrue();
        assertThat(guard.isLocked("2.2.2.2")).isFalse();

        guard.succeeded("1.1.1.1");
        assertThat(guard.isLocked("1.1.1.1")).isFalse();
    }

    @Test
    void nullIpIsOneKey() {
        LoginAttemptsGuard guard = new LoginAttemptsGuard(1, 15);
        guard.failed(null);
        assertThat(guard.isLocked(null)).isTrue();
    }

    @Test
    void windowExpires() {
        //0 minutes window: every failure is already expired
        LoginAttemptsGuard guard = new LoginAttemptsGuard(1, 0);
        guard.failed("1.1.1.1");
        assertThat(guard.isLocked("1.1.1.1")).isFalse();
        guard.purgeExpired();
    }

    @Test
    void disabledWithZeroAttempts() {
        LoginAttemptsGuard guard = new LoginAttemptsGuard(0, 15);
        for (int i = 0; i < 100; i++) guard.failed("1.1.1.1");
        assertThat(guard.isLocked("1.1.1.1")).isFalse();
    }
}
