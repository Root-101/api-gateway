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

        // Predicado de la ruta
        PredicateDefinition predicateDefinition = new PredicateDefinition();
        predicateDefinition.setName("Path");
        predicateDefinition.setArgs(Map.of("_genkey_0", routeDefinition.getPath()));
        route.setPredicates(List.of(predicateDefinition));

        // Filtro de reescritura de ruta
        FilterDefinition rewritePathFilter = new FilterDefinition();
        rewritePathFilter.setName("RewritePath");
        rewritePathFilter.setArgs(
                Map.of(
                        "_genkey_0", routeDefinition.getReplaceFrom(),
                        "_genkey_1", routeDefinition.getReplaceTo()
                )
        );

        // Añadir los filtros a la ruta
        route.setFilters(List.of(rewritePathFilter));

        // Guardar y refrescar la ruta
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
