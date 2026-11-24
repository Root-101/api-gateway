package dev.root101.api_gateway.core.feature.addons.base.rest;

import dev.root101.api_gateway.core.i18n.I18n;
import dev.root101.api_gateway.core.feature.addons.base.logic.model.GatewayAddons;
import dev.root101.api_gateway.core.feature.addons.base.logic.usecase.AddonsUseCase;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

/**
 * The add-ons of the whole gateway. Each type is written through its own endpoints (`/addons/maintenance`...); the
 * ones of a route come with the route.
 */
@RestController
@RequestMapping("/${app.admin.base-path}/addons")
public class AddonsController {

    private final AddonsUseCase addonsUseCase;

    public AddonsController(AddonsUseCase addonsUseCase) {
        this.addonsUseCase = addonsUseCase;
    }

    /**
     * @return Every add-on type of the gateway, `null` when not configured
     */
    @GetMapping
    public Mono<GatewayAddons> getAddons(ServerWebExchange exchange) {
        return Mono.fromSupplier(() -> addonsUseCase.ofGateway(I18n.locale(exchange)));
    }
}
