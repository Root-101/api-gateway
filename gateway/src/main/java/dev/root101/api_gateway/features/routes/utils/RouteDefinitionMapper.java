package dev.root101.api_gateway.features.routes.utils;

import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import dev.root101.api_gateway.features.routes.logic.model.RouteHeaderModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteRules;
import org.springframework.cloud.gateway.filter.FilterDefinition;
import org.springframework.cloud.gateway.handler.predicate.PredicateDefinition;
import org.springframework.cloud.gateway.route.RouteDefinition;

import java.net.URI;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class RouteDefinitionMapper {

    /**
     * Convert the `RouteEntity` into a `RouteDefinition`
     *
     * @param routeEntity The model to convert into `RouteDefinition`
     * @return The parsed `RouteDefinition`
     */
    public static RouteDefinition buildDefinition(RouteEntity routeEntity) {
        RouteRules rules = RouteRulesJson.fromJson(routeEntity.getRules());

        //create the route definition, the model to parse in order to config the gateway
        RouteDefinition route = new RouteDefinition();

        //set the route-id
        route.setId(routeEntity.getRouteId().toString());
        //set the route uri
        route.setUri(URI.create(routeEntity.getUri()));
        route.setOrder(routeEntity.getRouteOrder());

        //the path predicate, plus the optional ones
        List<PredicateDefinition> predicates = new ArrayList<>();
        predicates.add(predicate("Path", List.of(routeEntity.getPath())));
        if (!rules.methods().isEmpty()) {
            predicates.add(predicate("Method", rules.methods()));
        }
        if (!rules.hosts().isEmpty()) {
            predicates.add(predicate("Host", rules.hosts()));
        }
        for (RouteHeaderModel header : rules.headers()) {
            predicates.add(predicate(
                    "Header",
                    header.getRegexp() == null ? List.of(header.getName()) : List.of(header.getName(), header.getRegexp())
            ));
        }
        route.setPredicates(predicates);

        //add, if provided, the rewrite path filter, then the extra ones
        List<FilterDefinition> filters = new ArrayList<>();
        if (routeEntity.getRewritePathFrom() != null && routeEntity.getRewritePathTo() != null) {
            filters.add(filter("RewritePath", List.of(routeEntity.getRewritePathFrom(), routeEntity.getRewritePathTo())));
        }
        rules.filters().forEach(extra -> filters.add(filter(extra.getName(), extra.getArgs())));
        route.setFilters(filters);

        return route;
    }

    private static PredicateDefinition predicate(String name, List<String> args) {
        PredicateDefinition predicate = new PredicateDefinition();
        predicate.setName(name);
        predicate.setArgs(positionalArgs(args));
        return predicate;
    }

    private static FilterDefinition filter(String name, List<String> args) {
        FilterDefinition filter = new FilterDefinition();
        filter.setName(name);
        filter.setArgs(positionalArgs(args));
        return filter;
    }

    //the gateway takes these args by position: keep the insertion order
    private static Map<String, String> positionalArgs(List<String> args) {
        Map<String, String> positional = new LinkedHashMap<>();
        for (int i = 0; i < args.size(); i++) {
            positional.put("_genkey_" + i, args.get(i));
        }
        return positional;
    }
}
