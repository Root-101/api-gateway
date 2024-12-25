package dev.root101.api_gateway.feature.tasks;

import dev.root101.api_gateway.feature.data.entity.RouteEntity;
import dev.root101.api_gateway.feature.data.repo.RouteRepo;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.cloud.gateway.event.RefreshRoutesEvent;
import org.springframework.cloud.gateway.filter.FilterDefinition;
import org.springframework.cloud.gateway.handler.predicate.PredicateDefinition;
import org.springframework.cloud.gateway.route.RouteDefinition;
import org.springframework.cloud.gateway.route.RouteDefinitionWriter;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.net.URI;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

@Component
public class RouteInitializer {

    private final RouteRepo routeRepo;

    private final RouteDefinitionWriter routeDefinitionWriter;

    private final ApplicationEventPublisher publisher;

    //TODO: clean-up
    public RouteInitializer(RouteRepo routeRepo, RouteDefinitionWriter routeDefinitionWriter, ApplicationEventPublisher publisher) {
        this.routeRepo = routeRepo;
        this.routeDefinitionWriter = routeDefinitionWriter;
        this.publisher = publisher;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void initRoutes() {
        routeRepo.findAll()
                .map(this::buildDefinition) // Convert each entity to a RouteDefinition
                .concatMap(route -> routeDefinitionWriter.save(Mono.just(route))) // Save each definition in the RouteDefinitionWriter
                .then(updateRoutes()) // Trigger the updateRoutes logic
                .subscribe(
                        null, // No action needed for onNext since we're working with a Mono<Void>
                        error -> {
                            // Log errors without blocking
                            System.err.println("Error initializing routes: " + error.getMessage());
                        },
                        () -> {
                            // Log successful initialization
                            System.out.println("All routes initialized successfully.");
                        }
                );
    }

    private <T> Mono<T> updateRoutes() {
        publisher.publishEvent(new RefreshRoutesEvent(this));
        return Mono.empty();
    }

    /**
     * Convert the `RouteEntity` into a `RouteDefinition`
     *
     * @param routeEntity The model to convert into `RouteDefinition`
     * @return The parsed `RouteDefinition`
     */
    private RouteDefinition buildDefinition(RouteEntity routeEntity) {
        //create the route definition, the model to parse in order to config the gateway
        RouteDefinition route = new RouteDefinition();

        //set the route-id
        route.setId(routeEntity.getName());
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
