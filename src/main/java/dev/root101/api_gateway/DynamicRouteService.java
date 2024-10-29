package dev.root101.api_gateway;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.gateway.event.RefreshRoutesEvent;
import org.springframework.cloud.gateway.filter.FilterDefinition;
import org.springframework.cloud.gateway.handler.predicate.PredicateDefinition;
import org.springframework.cloud.gateway.route.RouteDefinition;
import org.springframework.cloud.gateway.route.RouteDefinitionLocator;
import org.springframework.cloud.gateway.route.RouteDefinitionWriter;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.net.URI;
import java.util.List;
import java.util.Map;

@Service
public class DynamicRouteService {

    private final RouteDefinitionWriter routeDefinitionWriter;

    private final RouteDefinitionLocator routeDefinitionLocator;

    private final ApplicationEventPublisher publisher;

    @Autowired
    public DynamicRouteService(RouteDefinitionWriter routeDefinitionWriter, RouteDefinitionLocator routeDefinitionLocator, ApplicationEventPublisher publisher) {
        this.routeDefinitionWriter = routeDefinitionWriter;
        this.routeDefinitionLocator = routeDefinitionLocator;
        this.publisher = publisher;
    }

    public Mono<Void> addRoute(RouteConfigModel routeDefinition) {
        RouteDefinition route = new RouteDefinition();
        route.setId(routeDefinition.getId());
        route.setUri(URI.create(routeDefinition.getUri()));

        PredicateDefinition predicateDefinition = new PredicateDefinition();
        predicateDefinition.setName("Path");
        predicateDefinition.setArgs(Map.of("_genkey_0", routeDefinition.getPath()));
        route.setPredicates(List.of(predicateDefinition));

        FilterDefinition filterDefinition = new FilterDefinition();
        filterDefinition.setName("RewritePath");
        filterDefinition.setArgs(
                Map.of(
                        "_genkey_0", routeDefinition.getReplaceFrom(),
                        "_genkey_1", routeDefinition.getReplaceTo()
                )
        );
        route.setFilters(List.of(filterDefinition));

        return routeDefinitionWriter.save(Mono.just(route)).then(Mono.defer(() -> {
            publisher.publishEvent(new RefreshRoutesEvent(this));
            return Mono.empty();
        }));
    }

    public Mono<Void> deleteRoute(String routeId) {
        return routeDefinitionWriter.delete(Mono.just(routeId)).then(Mono.defer(() -> {
            publisher.publishEvent(new RefreshRoutesEvent(this));
            return Mono.empty();
        }));
    }

    public Flux<RouteDefinition> getRoutes() {
        return routeDefinitionLocator.getRouteDefinitions();
    }
}
