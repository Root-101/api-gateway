package dev.root101.api_gateway.features.addons.rate_limit.logic.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

import java.time.Duration;

/**
 * The rate limit add-on of the gateway or of a route, as the admin sets it (the `config` of its row): each client ip
 * can make `limit` requests per `period`, and up to `burst` at once. The gateway's counts every route together.
 *
 * @param enabled limits only when true: turned off, the rest is kept for the next time
 * @param limit   requests per period, per client ip
 * @param period  `second`, `minute` or `hour`
 * @param burst   the most requests at once (the size of the bucket); `limit` when missing
 */
public record RateLimit(
        @NotNull Boolean enabled,
        @NotNull @Min(1) @Max(1_000_000) Integer limit,
        @NotNull @Pattern(regexp = "second|minute|hour", message = "{rate_limit.period.invalid}") String period,
        @Min(1) @Max(1_000_000) Integer burst
) {

    /**
     * Its `type` in the `addon` table and its key in `addons`
     */
    public static final String TYPE = "rate_limit";

    /**
     * Whether the requests are limited
     */
    public boolean on() {
        return Boolean.TRUE.equals(enabled);
    }

    /**
     * The size of the bucket: `burst`, or `limit` when missing
     */
    public int capacity() {
        return burst != null ? burst : limit;
    }

    public Duration periodDuration() {
        return switch (period) {
            case "second" -> Duration.ofSeconds(1);
            case "minute" -> Duration.ofMinutes(1);
            default -> Duration.ofHours(1);
        };
    }
}
