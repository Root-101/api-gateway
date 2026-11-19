package dev.root101.api_gateway.features.addons.maintenance.filter;

import dev.root101.api_gateway.config.GlobalExceptionHandler;
import dev.root101.api_gateway.features.addons.maintenance.logic.model.Maintenance;
import dev.root101.api_gateway.features.addons.maintenance.logic.usecase.MaintenanceUseCase;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.cloud.gateway.route.Route;
import org.springframework.cloud.gateway.support.ServerWebExchangeUtils;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.time.OffsetDateTime;

/**
 * A request to a route in maintenance (its own, or the gateway's) gets a `503` and never reaches the service. Only
 * proxied requests go through here: the admin API, the console and the health check are never stopped, and a path
 * with no route stays a `404`.
 */
@Component
public class MaintenanceFilter implements GlobalFilter, Ordered {

    private final MaintenanceUseCase maintenanceUseCase;
    private final GlobalExceptionHandler errors;

    public MaintenanceFilter(MaintenanceUseCase maintenanceUseCase, GlobalExceptionHandler errors) {
        this.maintenanceUseCase = maintenanceUseCase;
        this.errors = errors;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        Route route = exchange.getAttribute(ServerWebExchangeUtils.GATEWAY_ROUTE_ATTR);
        Maintenance maintenance = route != null ? maintenanceUseCase.active(route.getId()) : null;
        if (maintenance == null) {
            return chain.filter(exchange);
        }
        if (maintenance.retryAfter() != null) {
            long millis = Duration.between(OffsetDateTime.now(), maintenance.retryAfter()).toMillis();
            if (millis > 0) {
                //rounded up: never tells to come back before the time
                exchange.getResponse().getHeaders().set(HttpHeaders.RETRY_AFTER, String.valueOf((millis + 999) / 1000));
            }
        }
        if (maintenance.message() != null && !maintenance.message().isBlank()) {
            return errors.writeDetail(exchange, HttpStatus.SERVICE_UNAVAILABLE, maintenance.message());
        }
        return errors.writeProblem(exchange, HttpStatus.SERVICE_UNAVAILABLE, "maintenance.default");
    }

    //before every other filter: nothing of the request is done for a route in maintenance
    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;
    }
}
