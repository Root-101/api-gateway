package dev.root101.api_gateway.features.routes.tasks;

import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import dev.root101.api_gateway.features.routes.data.repo.RouteRepo;
import dev.root101.api_gateway.features.routes.utils.RouteDefinitionMapper;
import dev.root101.api_gateway.features.routes.utils.RouteUpdater;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.cloud.gateway.route.RouteDefinition;
import org.springframework.cloud.gateway.route.RouteDefinitionWriter;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

@Component
public class RouteInitializer {

    private final RouteRepo routeRepo;

    private final RouteDefinitionWriter routeDefinitionWriter;

    private final RouteUpdater routeUpdater;

    //TODO: clean-up
    public RouteInitializer(
            RouteRepo routeRepo,
            RouteDefinitionWriter routeDefinitionWriter,
            RouteUpdater routeUpdater
    ) {
        this.routeRepo = routeRepo;
        this.routeDefinitionWriter = routeDefinitionWriter;
        this.routeUpdater = routeUpdater;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void initRoutes() {
        routeRepo.findAll()
                .concatMap(route -> routeDefinitionWriter.save(
                        Mono.just(
                                buildDefinition(route)
                        )
                )) // Save each definition in the RouteDefinitionWriter
                .then(
                        //update routes
                        Mono.defer(routeUpdater::updateRoutes)
                ) // Trigger the updateRoutes logic
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

    /**
     * Convert the `RouteEntity` into a `RouteDefinition`
     *
     * @param routeEntity The model to convert into `RouteDefinition`
     * @return The parsed `RouteDefinition`
     */
    private RouteDefinition buildDefinition(RouteEntity routeEntity) {
        return RouteDefinitionMapper.buildDefinition(routeEntity);
    }
}
