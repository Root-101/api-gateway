package dev.root101.api_gateway;

import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpHeaders;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.time.Instant;

@Component
@Order(0) // Define la prioridad del filtro, si tienes más de uno
public class LoggingGlobalFilter implements GlobalFilter {

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        Instant startTime = Instant.now();

        return chain.filter(exchange)
                .doOnSuccess(unused -> {
                    Instant endTime = Instant.now();
                    long responseTime = Duration.between(startTime, endTime).toMillis();

                    logRequest(exchange, responseTime);
                    logResponse(exchange);
                })
                .doOnError(error -> logError(exchange, error));
    }

    private void logRequest(ServerWebExchange exchange, long responseTime) {
        String method = exchange.getRequest().getMethod().name();
        String url = exchange.getRequest().getURI().toString();
        HttpHeaders headers = exchange.getRequest().getHeaders();

        System.out.printf("Request: Method=%s, URL=%s, Headers=%s, ResponseTime=%dms%n",
                method, url, headers, responseTime);
    }

    private void logResponse(ServerWebExchange exchange) {
        ServerHttpResponse response = exchange.getResponse();
        int statusCode = response.getStatusCode() != null ? response.getStatusCode().value() : 0;

        System.out.printf("Response: StatusCode=%d, Headers=%s%n",
                statusCode, response.getHeaders());
    }

    private void logError(ServerWebExchange exchange, Throwable error) {
        String url = exchange.getRequest().getURI().toString();
        System.err.printf("Error: URL=%s, Message=%s%n", url, error.getMessage());
    }
}
