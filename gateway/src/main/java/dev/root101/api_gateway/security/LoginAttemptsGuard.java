package dev.root101.api_gateway.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Brute force protection for the admin credentials (login and Basic auth).
 * After `max-failed-attempts` tries of the credentials from the same client ip without a correct one,
 * that ip is locked until `lockout-minutes` after its first try.
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

    /**
     * Takes one try of the credentials for this ip, atomically: `false` (locked) once
     * `max-failed-attempts` tries are taken in the window. Every try counts until a correct one
     * clears them (`succeeded`), so concurrent guesses can't all pass before any failure is counted.
     */
    public boolean tryAcquire(String clientIp) {
        if (maxFailedAttempts <= 0) return true;//disabled
        long now = System.currentTimeMillis();
        boolean[] taken = {false};
        failures.compute(key(clientIp), (k, f) -> {
            if (f == null || expired(f, now)) {
                taken[0] = true;
                return new Failures(1, now);
            }
            if (f.count() >= maxFailedAttempts) return f;
            taken[0] = true;
            return new Failures(f.count() + 1, f.firstAtMillis());
        });
        return taken[0];
    }

    /**
     * Seconds until the lockout of this ip ends (0 if it isn't locked)
     */
    public long retryAfterSeconds(String clientIp) {
        Failures f = failures.get(key(clientIp));
        long now = System.currentTimeMillis();
        if (maxFailedAttempts <= 0 || f == null || expired(f, now) || f.count() < maxFailedAttempts) return 0;
        long left = f.firstAtMillis() + windowMillis - now;
        return Math.max(1, (left + 999) / 1000);
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
