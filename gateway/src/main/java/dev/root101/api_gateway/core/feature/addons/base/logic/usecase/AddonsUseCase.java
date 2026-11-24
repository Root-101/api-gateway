package dev.root101.api_gateway.core.feature.addons.base.logic.usecase;

import dev.root101.api_gateway.core.feature.addons.base.logic.model.Addons;
import dev.root101.api_gateway.core.feature.addons.base.logic.model.AddonsRequest;
import dev.root101.api_gateway.core.feature.addons.base.logic.model.GatewayAddons;
import reactor.core.publisher.Mono;

import java.util.Locale;
import java.util.UUID;

/**
 * Every add-on type together, for what reads or restores them all at once: a new type is added here. Each type keeps
 * its own use case and endpoints.
 */
public interface AddonsUseCase {

    /**
     * The add-ons of the gateway. No db request.
     */
    GatewayAddons ofGateway(Locale locale);

    /**
     * The add-ons of a route. No db request.
     */
    Addons ofRoute(String routeId, Locale locale);

    /**
     * The add-ons of a restored route, in the transaction of the caller, who calls {@link #reload()} after it: a key
     * with a value is saved, a key `null` is deleted, a key not sent is kept
     */
    Mono<Void> restore(UUID routeId, AddonsRequest addons);

    /**
     * A route now points to another service: its health check, if it has one (on or off), is called again right
     * away, so it never shows the last result of the old service
     */
    Mono<Void> uriChanged(String routeId);

    /**
     * Reads every add-on from db into use
     */
    Mono<Void> reload();
}
