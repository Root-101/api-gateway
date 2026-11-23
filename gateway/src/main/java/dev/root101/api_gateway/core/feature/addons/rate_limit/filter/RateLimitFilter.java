package dev.root101.api_gateway.core.feature.addons.rate_limit.filter;

import dev.root101.api_gateway.config.GlobalExceptionHandlerConfig;
import dev.root101.api_gateway.core.feature.http_logs.filter.HttpLogsWebFilter;
import dev.root101.api_gateway.core.feature.addons.rate_limit.logic.usecase.RateLimitUseCase;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.cloud.gateway.filter.headers.TrustedProxies;
import org.springframework.cloud.gateway.route.Route;
import org.springframework.cloud.gateway.support.ServerWebExchangeUtils;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

/**
 * A client ip over the rate limit of the gateway or of the route gets a `429` with `Retry-After`, and never reaches
 * the service. Only proxied requests go through here: the admin API has its own lockout.
 */
@Component
public class RateLimitFilter implements GlobalFilter, Ordered {

    private final RateLimitUseCase rateLimitUseCase;
    private final GlobalExceptionHandlerConfig errors;
    private final TrustedProxies trustedProxies;

    public RateLimitFilter(RateLimitUseCase rateLimitUseCase, GlobalExceptionHandlerConfig errors, TrustedProxies trustedProxies) {
        this.rateLimitUseCase = rateLimitUseCase;
        this.errors = errors;
        this.trustedProxies = trustedProxies;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        Route route = exchange.getAttribute(ServerWebExchangeUtils.GATEWAY_ROUTE_ATTR);
        if (route == null) {
            return chain.filter(exchange);
        }
        long seconds = rateLimitUseCase.acquire(route.getId(), HttpLogsWebFilter.getClientIp(exchange, trustedProxies));
        if (seconds == 0) {
            return chain.filter(exchange);
        }
        exchange.getResponse().getHeaders().set(HttpHeaders.RETRY_AFTER, String.valueOf(seconds));
        return errors.writeProblem(exchange, HttpStatus.TOO_MANY_REQUESTS, "rate_limit.exceeded", seconds);
    }

    //right after the maintenance: a request it stops never counts
    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE + 1;
    }
}
