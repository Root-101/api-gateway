package dev.root101.api_gateway.feature.utils;

import dev.root101.api_gateway.feature.data.entity.RouteEntity;
import org.springframework.cloud.gateway.filter.FilterDefinition;
import org.springframework.cloud.gateway.handler.predicate.PredicateDefinition;
import org.springframework.cloud.gateway.route.RouteDefinition;

import java.net.URI;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

public class RouteDefinitionMapper {

    /**
     * Convert the `RouteEntity` into a `RouteDefinition`
     *
     * @param routeEntity The model to convert into `RouteDefinition`
     * @return The parsed `RouteDefinition`
     */
    public static RouteDefinition buildDefinition(RouteEntity routeEntity) {
        //create the route definition, the model to parse in order to config the gateway
        RouteDefinition route = new RouteDefinition();

        //set the route-id
        route.setId(routeEntity.getRouteId().toString());
        //set the route uri
        route.setUri(URI.create(routeEntity.getUri()));

        //add the path predicate
        PredicateDefinition predicateDefinition = new PredicateDefinition();
        predicateDefinition.setName("Path");
        predicateDefinition.setArgs(Map.of("_genkey_0", routeEntity.getPath()));
        route.setPredicates(List.of(predicateDefinition));

        //add, if provided, the rewrite path filter
        if (routeEntity.getRewritePathFrom() != null && routeEntity.getRewritePathTo() != null) {
            //create empty filter
            FilterDefinition rewritePathFilter = new FilterDefinition();
            //set-up name
            rewritePathFilter.setName("RewritePath");

            //prepare filter args. always use a tree-map to always have the values sorted
            Map<String, String> sortedFilter = new TreeMap<>(
                    Map.of(
                            "_genkey_0", routeEntity.getRewritePathFrom(),
                            "_genkey_1", routeEntity.getRewritePathTo()
                    )
            );

            //set arguments to filter
            rewritePathFilter.setArgs(sortedFilter);

            //set filter to list
            route.setFilters(List.of(rewritePathFilter));
        }

        return route;
    }
}
