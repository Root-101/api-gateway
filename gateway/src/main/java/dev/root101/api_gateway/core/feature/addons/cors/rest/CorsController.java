package dev.root101.api_gateway.core.feature.addons.cors.rest;

import dev.root101.api_gateway.core.feature.addons.cors.logic.model.Cors;
import dev.root101.api_gateway.core.feature.addons.cors.logic.model.CorsResponse;
import dev.root101.api_gateway.core.feature.addons.cors.logic.usecase.CorsUseCase;
import jakarta.validation.Valid;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

/**
 * The CORS add-on: of the whole gateway (`/addons/cors`, only replaced: it always exists and is always on) and of a
 * route (`/routes/{id}/addons/cors`). Every change is in use right away.
 */
@RestController
@RequestMapping("/${app.admin.base-path}")
public class CorsController {

    private final CorsUseCase corsUseCase;

    public CorsController(CorsUseCase corsUseCase) {
        this.corsUseCase = corsUseCase;
    }

    //--------- GATEWAY ---------\\

    /**
     * Replaces the CORS of the gateway: `400` if it would lock out the browser that sends it
     */
    @PutMapping("/addons/cors")
    public Mono<CorsResponse> setGateway(@Valid @RequestBody Cors cors, @RequestHeader(value = HttpHeaders.ORIGIN, required = false) String origin) {
        return corsUseCase.setGateway(cors, origin);
    }

    //--------- ROUTE ---------\\

    /**
     * Creates or replaces the CORS of a route
     */
    @PutMapping("/routes/{route-id}/addons/cors")
    public Mono<Cors> setRoute(@PathVariable("route-id") String routeId, @Valid @RequestBody Cors cors) {
        return corsUseCase.setRoute(routeId, cors);
    }

    /**
     * Removes the CORS of a route: back to `null`, the gateway's
     */
    @DeleteMapping("/routes/{route-id}/addons/cors")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteRoute(@PathVariable("route-id") String routeId) {
        return corsUseCase.deleteRoute(routeId);
    }

    /**
     * Turns the CORS of a route on: `404` if it isn't configured
     */
    @PostMapping("/routes/{route-id}/addons/cors/enable")
    public Mono<Cors> enableRoute(@PathVariable("route-id") String routeId) {
        return corsUseCase.enableRoute(routeId, true);
    }

    /**
     * Turns the CORS of a route off (it gets the gateway's), keeping the rest: `404` if it isn't configured
     */
    @PostMapping("/routes/{route-id}/addons/cors/disable")
    public Mono<Cors> disableRoute(@PathVariable("route-id") String routeId) {
        return corsUseCase.enableRoute(routeId, false);
    }
}
