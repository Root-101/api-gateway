package dev.root101.api_gateway.features.routes.utils;

import org.springframework.cloud.gateway.event.RefreshRoutesEvent;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

@Component
public class RouteUpdater {

    private final ApplicationEventPublisher publisher;

    public RouteUpdater(ApplicationEventPublisher publisher) {
        this.publisher = publisher;
    }

    /**
     * Update all the routes in `routeDefinitionWriter`
     * This is the method to call for the route actually go into effect, if not, the gateway will not recognize the routes
     *
     * @return Mono.empty()
     */
    public Mono<Void> updateRoutes() {
        publisher.publishEvent(new RefreshRoutesEvent(this));
        return Mono.empty();
    }
}
