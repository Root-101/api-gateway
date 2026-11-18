package dev.root101.api_gateway.features.addons.rate_limit.logic.usecase;

import dev.root101.api_gateway.features.addons.rate_limit.logic.model.RateLimit;

/**
 * The requests one client ip has left under one rate limit: starts full (`capacity`), each request takes one, and
 * it fills back at `limit` per `period`. Times in nanos, given by the caller (testable without waiting).
 */
final class TokenBucket {

    private final double capacity;
    private final double perNano;
    private double tokens;
    private long last;

    TokenBucket(RateLimit config, long now) {
        this.capacity = config.capacity();
        this.perNano = config.limit() / (double) config.periodDuration().toNanos();
        this.tokens = capacity;
        this.last = now;
    }

    /**
     * Takes one request: 0 when it can go, else the nanos until it could
     */
    synchronized long take(long now) {
        refill(now);
        if (tokens >= 1) {
            tokens -= 1;
            return 0;
        }
        return (long) Math.ceil((1 - tokens) / perNano);
    }

    /**
     * Back to full: as if never used, so it can be forgotten
     */
    synchronized boolean full(long now) {
        refill(now);
        return tokens >= capacity;
    }

    private void refill(long now) {
        tokens = Math.min(capacity, tokens + Math.max(0, now - last) * perNano);
        last = now;
    }
}
