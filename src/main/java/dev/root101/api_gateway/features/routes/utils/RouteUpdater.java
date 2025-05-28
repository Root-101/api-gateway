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
     * @param <T> to avoid warnings, it's not used
     * @return Mono.empty()
     */
    public <T> Mono<T> updateRoutes() {
        publisher.publishEvent(new RefreshRoutesEvent(this));
        return Mono.empty();
    }
}
