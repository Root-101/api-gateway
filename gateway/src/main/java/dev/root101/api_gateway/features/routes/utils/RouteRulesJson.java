package dev.root101.api_gateway.features.routes.utils;

import dev.root101.api_gateway.features.routes.logic.model.RouteRules;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;

/**
 * Json of the `rules` column. Text and not an object in {@link dev.root101.api_gateway.features.routes.data.entity.RouteEntity}
 * for the same reasons as the `route` column of the http logs: r2dbc doesn't encode complex types and spring data AOT fails on the jackson internals.
 */
public final class RouteRulesJson {
    private static final ObjectMapper MAPPER = JsonMapper.builderWithJackson2Defaults().build();

    private RouteRulesJson() {
    }

    public static String toJson(RouteRules rules) {
        return MAPPER.writeValueAsString(rules);
    }

    public static RouteRules fromJson(String json) {
        return MAPPER.readValue(json, RouteRules.class);
    }
}
