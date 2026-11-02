package dev.root101.api_gateway.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Brute force protection for the admin credentials (login and Basic auth).
 * After `max-failed-attempts` wrong credentials from the same client ip, that ip is locked
 * until `lockout-minutes` after its first failure.
 * <br/>
 * shortcut: in memory and per instance, and the client ip comes from `X-Forwarded-For` (see README), move to a shared store if the gateway runs with several replicas.
 */
@Component
public class LoginAttemptsGuard {

    private record Failures(int count, long firstAtMillis) {
    }

    private final int maxFailedAttempts;

    private final long windowMillis;

    private final Map<String, Failures> failures = new ConcurrentHashMap<>();

    public LoginAttemptsGuard(
            @Value("${app.admin.max-failed-attempts}") int maxFailedAttempts,
            @Value("${app.admin.lockout-minutes}") long lockoutMinutes
    ) {
        this.maxFailedAttempts = maxFailedAttempts;
        this.windowMillis = lockoutMinutes * 60_000;
    }

    public boolean isLocked(String clientIp) {
        if (maxFailedAttempts <= 0) return false;//disabled
        Failures f = failures.get(key(clientIp));
        return f != null && !expired(f, System.currentTimeMillis()) && f.count() >= maxFailedAttempts;
    }

    public void failed(String clientIp) {
        if (maxFailedAttempts <= 0) return;
        long now = System.currentTimeMillis();
        failures.compute(key(clientIp), (k, f) ->
                f == null || expired(f, now) ? new Failures(1, now) : new Failures(f.count() + 1, f.firstAtMillis())
        );
    }

    public void succeeded(String clientIp) {
        failures.remove(key(clientIp));
    }

    @Scheduled(fixedDelay = 60_000)
    void purgeExpired() {
        long now = System.currentTimeMillis();
        failures.values().removeIf(f -> expired(f, now));
    }

    private boolean expired(Failures f, long now) {
        return now - f.firstAtMillis() >= windowMillis;
    }

    private static String key(String clientIp) {
        return clientIp == null ? "" : clientIp;
    }
}
