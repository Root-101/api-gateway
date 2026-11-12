package dev.root101.api_gateway.features.http_logs.data.entity;

import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;

/**
 * Mapper of the `route` column json.
 * Own mapper on purpose (not the snake_case bean): the column already stores camelCase json (`routeId`...),
 * changing it would break reading the old rows and the `route_id` column generated from that json (migration V4).
 * Outside {@link HttpLogEntity} on purpose: spring data AOT walks the types declared in the entity (nested ones too) and fails on the jackson internals.
 */
final class RouteLogJson {
    static final ObjectMapper MAPPER = JsonMapper.builderWithJackson2Defaults().build();

    private RouteLogJson() {
    }
}
