package dev.root101.api_gateway.features.http_logs.filter;

import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogRequest;
import dev.root101.api_gateway.features.http_logs.logic.usecase.HttpLogUseCase;
import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import dev.root101.api_gateway.features.routes.logic.usecase.RouteUseCase;
import org.jetbrains.annotations.NotNull;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.route.Route;
import org.springframework.cloud.gateway.support.ServerWebExchangeUtils;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;

import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

@Component
public class HttpLogsWebFilter implements WebFilter {

    private static final DateTimeFormatter TIME_FORMATTER =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS").withZone(ZoneId.systemDefault());

    private final HttpLogUseCase httpLogUseCase;

    public HttpLogsWebFilter(
            HttpLogUseCase httpLogUseCase
    ) {
        this.httpLogUseCase = httpLogUseCase;
    }

    @Override
    public @NotNull Mono<Void> filter(@NotNull ServerWebExchange exchange, @NotNull WebFilterChain chain) {
        // 📍 IP del cliente (puede venir de X-Forwarded-For si hay proxy)
        final String clientIp = getClientIp(exchange);

        // 📍 Cliente HTTP (User-Agent)
        final String userAgent = exchange.getRequest().getHeaders().getFirst("User-Agent");

        // 📌 Tiempo del servidor
        final OffsetDateTime serverTime = OffsetDateTime.now();

        // 📌 Método HTTP
        final HttpMethod httpMethod = exchange.getRequest().getMethod();

        // 📌 Path solicitado
        final String requestedPath = exchange.getRequest().getPath().toString();

        long startTime = System.currentTimeMillis();
        return chain.filter(exchange)
                .doFinally(
                        signalType -> {
                            int duration = (int) (System.currentTimeMillis() - startTime);

                            Route route = exchange.getAttribute(ServerWebExchangeUtils.GATEWAY_ROUTE_ATTR);

                            HttpStatusCode statusCode = exchange.getResponse().getStatusCode();

                            // 📍 IP del server (puede venir de X-Forwarded-Proto/X-Forwarded-Host si hay proxy)
                            final String serverIp = getServerIp(exchange);

                            HttpLogRequest request = new HttpLogRequest(
                                    clientIp,
                                    serverIp,
                                    serverTime,
                                    userAgent,
                                    httpMethod,
                                    requestedPath,
                                    statusCode,
                                    duration,
                                    route
                            );
                            httpLogUseCase.saveHttpLog(request);
                        }
                );
    }

    private String getServerIp(ServerWebExchange exchange) {
        String forwardedProto = exchange.getRequest().getHeaders().getFirst("X-Forwarded-Proto");
        String forwardedHost = exchange.getRequest().getHeaders().getFirst("X-Forwarded-Host");
        String forwardedPort = exchange.getRequest().getHeaders().getFirst("X-Forwarded-Port");

        final String thisIp;

        if (forwardedProto != null && forwardedHost != null) {
            // Si viene detrás de proxy o balanceador, usamos los headers
            if (forwardedPort != null && !forwardedHost.contains(":")) {
                thisIp = forwardedProto + "://" + forwardedHost + ":" + forwardedPort;
            } else {
                thisIp = forwardedProto + "://" + forwardedHost;
            }
        } else {
            // Si no hay proxy, usamos directamente la URI local
            int port = exchange.getRequest().getURI().getPort();
            String scheme = exchange.getRequest().getURI().getScheme();
            String host = exchange.getRequest().getURI().getHost();

            // Si el puerto es estándar (80 o 443), no lo incluimos
            if ((scheme.equals("http") && port == 80) || (scheme.equals("https") && port == 443)) {
                thisIp = scheme + "://" + host;
            } else {
                thisIp = scheme + "://" + host + ":" + port;
            }
        }
        return thisIp;
    }

    private String getClientIp(ServerWebExchange exchange) {
        String tempClientIp = exchange.getRequest().getHeaders().getFirst("X-Forwarded-For");
        if (tempClientIp == null) {
            tempClientIp = exchange.getRequest().getRemoteAddress() != null
                    ? exchange.getRequest().getRemoteAddress().getAddress().getHostAddress()
                    : null;
        }
        return tempClientIp;
    }
}
