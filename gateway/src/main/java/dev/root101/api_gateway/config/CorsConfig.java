package dev.root101.api_gateway.config;

import dev.root101.api_gateway.core.feature.addons.cors.logic.model.Cors;
import dev.root101.api_gateway.core.feature.addons.cors.logic.usecase.CorsUseCase;
import org.springframework.cloud.gateway.filter.headers.HttpHeadersFilter;
import org.springframework.cloud.gateway.handler.RoutePredicateHandlerMapping;
import org.springframework.cloud.gateway.route.Route;
import org.springframework.cloud.gateway.support.ServerWebExchangeUtils;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.web.cors.reactive.CorsWebFilter;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;

/**
 * CORS comes from the `cors` add-ons (see decision 20), read on each request, so a change applies without a restart.
 * The gateway answers the CORS preflights itself (they never reach a service), so without this a browser can't send a
 * JSON request to a proxied service.
 * <ul>
 *     <li>Admin API: the gateway's add-on, in Spring Security's chain ({@link #adminCorsFilter}), so its `401`/`403`
 *     get the CORS headers too</li>
 *     <li>Proxied routes: the route's add-on when on, else the gateway's, picked by the gateway's own handler mapping
 *     after it resolves the route (no path matching by hand)</li>
 * </ul>
 * `spring.cloud.gateway.server.webflux.globalcors.enabled=false` (application.yml): its listener would replace this
 * source on every route refresh.
 */
@Configuration
public class CorsConfig {

    /**
     * The CORS of the proxied routes, after the gateway resolved the route of the request
     */
    public CorsConfig(RoutePredicateHandlerMapping routePredicateHandlerMapping, CorsUseCase corsUseCase) {
        routePredicateHandlerMapping.setCorsConfigurationSource(exchange -> {
            Route route = exchange.getAttribute(ServerWebExchangeUtils.GATEWAY_ROUTE_ATTR);
            Cors cors = corsUseCase.active(route != null ? route.getId() : null);
            return cors != null ? cors.toConfiguration() : null;
        });
    }

    /**
     * The gateway's CORS on the admin API, for `ApplicationSecurityConfig`. Not a bean: WebFlux would also run it outside the
     * security chain. Only admin paths: Spring's `CorsWebFilter` ends every preflight, a proxied one would never get
     * its route's CORS.
     */
    public static WebFilter adminCorsFilter(CorsUseCase corsUseCase, String adminBasePath) {
        String prefix = "/" + adminBasePath + "/";
        CorsWebFilter cors = new CorsWebFilter(exchange -> {
            Cors gateway = corsUseCase.ofGateway();
            return gateway != null ? gateway.toConfiguration() : null;
        });
        return (exchange, chain) -> (exchange.getRequest().getPath().pathWithinApplication().value() + "/").startsWith(prefix)
                ? cors.filter(exchange, chain)
                : chain.filter(exchange);
    }

    /**
     * Drops the `Access-Control-*` headers of the upstream responses: the gateway's CORS headers are already
     * set, the upstream's would be added next to them (two `Access-Control-Allow-Origin` = blocked by the browser).
     */
    @Bean
    public HttpHeadersFilter upstreamCorsHeadersFilter() {
        return new HttpHeadersFilter() {
            @Override
            public HttpHeaders filter(HttpHeaders input, ServerWebExchange exchange) {
                HttpHeaders filtered = new HttpHeaders();
                input.forEach((name, values) -> {
                    if (!name.regionMatches(true, 0, "Access-Control-", 0, "Access-Control-".length())) {
                        filtered.addAll(name, values);
                    }
                });
                return filtered;
            }

            @Override
            public boolean supports(Type type) {
                return type == Type.RESPONSE;
            }
        };
    }
}
