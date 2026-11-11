package dev.root101.api_gateway.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;
import java.util.Base64;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Opaque tokens given by the login, valid for `token-minutes` since they are issued.
 * <br/>
 * shortcut: in memory and per instance (a restart invalidates them), move to a shared store if the gateway runs with several replicas.
 */
@Component
public class AdminTokens {

    private final SecureRandom random = new SecureRandom();

    private final Map<String, Long> expirations = new ConcurrentHashMap<>();

    private final long ttlMillis;

    public AdminTokens(@Value("${app.admin.token-minutes}") long tokenMinutes) {
        this.ttlMillis = tokenMinutes * 60_000;
    }

    public String issue() {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        expirations.put(token, System.currentTimeMillis() + ttlMillis);
        return token;
    }

    public boolean isValid(String token) {
        Long expiration = expirations.get(token);
        return expiration != null && System.currentTimeMillis() < expiration;
    }

    public long ttlMillis() {
        return ttlMillis;
    }

    /**
     * When the token expires, as epoch milliseconds (0 if unknown)
     */
    public long expireAt(String token) {
        return expirations.getOrDefault(token, 0L);
    }

    @Scheduled(fixedDelay = 60_000)
    void purgeExpired() {
        long now = System.currentTimeMillis();
        expirations.values().removeIf(expiration -> now >= expiration);
    }
}
