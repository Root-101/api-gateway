package dev.root101.api_gateway.features.routes.logic.model;

import java.util.List;

/**
 * Extra predicates and filters of a route, saved as json in the `rules` column.
 */
public record RouteRules(
        List<String> methods,
        List<String> hosts,
        List<RouteHeaderModel> headers,
        List<RouteFilterModel> filters
) {
    public RouteRules {
        methods = methods == null ? List.of() : methods;
        hosts = hosts == null ? List.of() : hosts;
        headers = headers == null ? List.of() : headers;
        filters = filters == null ? List.of() : filters;
    }
}
