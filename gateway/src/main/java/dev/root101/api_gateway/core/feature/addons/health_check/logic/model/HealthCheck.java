package dev.root101.api_gateway.core.feature.addons.health_check.logic.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * The health check add-on of a route, as the admin sets it (the `config` of its row): the gateway calls `GET
 * {uri of the route}{path}` every `intervalSeconds` while `enabled`. Routes only: the gateway has its own `/health`.
 *
 * @param enabled         called on its own only when true; a manual run works either way
 * @param path            added to the uri of the route (never another host), with its query if any
 * @param intervalSeconds from 10 s to 1 h
 */
public record HealthCheck(
        @NotNull Boolean enabled,
        @NotNull @Size(max = 2000) @Pattern(regexp = "/\\S*", message = "{health_check.path.invalid}") String path,
        @NotNull @Min(10) @Max(3600) Integer intervalSeconds
) {

    /**
     * Its `type` in the `addon` table and its key in `addons`
     */
    public static final String TYPE = "health_check";

    /**
     * Whether the scheduler calls it
     */
    public boolean on() {
        return Boolean.TRUE.equals(enabled);
    }
}
