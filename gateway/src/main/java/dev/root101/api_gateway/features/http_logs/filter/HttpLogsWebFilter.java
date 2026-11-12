package dev.root101.api_gateway.features.http_logs.filter;

import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogRequest;
import dev.root101.api_gateway.features.http_logs.logic.usecase.HttpLogUseCase;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.route.Route;
import org.springframework.cloud.gateway.support.ServerWebExchangeUtils;
import dev.root101.api_gateway.config.GlobalExceptionHandler;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.cors.reactive.CorsUtils;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;

import java.time.OffsetDateTime;

/**
 * Saves every request in the http logs. Runs before the security chain (order -100), so the admin
 * requests that security rejects (401, wrong Basic, the 429 of the lockout) are logged too.
 */
@Component
@Order(-101)
public class HttpLogsWebFilter implements WebFilter {

    private final HttpLogUseCase httpLogUseCase;

    private final String adminBasePath;

    private final GlobalExceptionHandler errorHandler;

    public HttpLogsWebFilter(
            HttpLogUseCase httpLogUseCase,
            @Value("${app.admin.base-path}")
            String adminBasePath,
            GlobalExceptionHandler errorHandler
    ) {
        this.httpLogUseCase = httpLogUseCase;
        this.adminBasePath = adminBasePath;
        this.errorHandler = errorHandler;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        final String requestedPath = exchange.getRequest().getPath().toString();

        final HttpMethod httpMethod = exchange.getRequest().getMethod();
        //ignored filters if:
        if (
            //logs endpoint
                requestedPath.startsWith("/%s/http-log".formatted(adminBasePath)) ||
                        //is admin and it's a get
                        (requestedPath.startsWith("/%s/routes".formatted(adminBasePath))
                                && httpMethod == HttpMethod.GET)
                        //a dry run of the route form, it changes nothing
                        || requestedPath.equals("/%s/routes/validate".formatted(adminBasePath))
                        //a CORS preflight (any other OPTIONS reaches a handler or an upstream: logged)
                        || CorsUtils.isPreFlightRequest(exchange.getRequest())
                        //health checks (would fill the table)
                        || requestedPath.equals("/%s/health".formatted(adminBasePath))
        ) {
            return chain.filter(exchange);
        }
        final String clientIp = getClientIp(exchange);

        final String userAgent = exchange.getRequest().getHeaders().getFirst("User-Agent");

        final OffsetDateTime serverTime = OffsetDateTime.now();

        long startTime = System.nanoTime();
        return chain.filter(exchange)
                //errors answered here, so their status is already set when the log is saved
                .onErrorResume(error -> errorHandler.handle(exchange, error))
                .doFinally(
                        signalType -> {
                            int duration = (int) ((System.nanoTime() - startTime) / 1_000_000);//millis, monotonic clock

                            Route route = exchange.getAttribute(ServerWebExchangeUtils.GATEWAY_ROUTE_ATTR);

                            HttpStatusCode statusCode = exchange.getResponse().getStatusCode();

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

    static String getServerIp(ServerWebExchange exchange) {
        String forwardedProto = exchange.getRequest().getHeaders().getFirst("X-Forwarded-Proto");
        String forwardedHost = exchange.getRequest().getHeaders().getFirst("X-Forwarded-Host");
        String forwardedPort = exchange.getRequest().getHeaders().getFirst("X-Forwarded-Port");

        final String thisIp;

        if (forwardedProto != null && forwardedHost != null) {
            // Behind a proxy or load balancer: use the forwarded headers
            if (forwardedPort != null && !forwardedHost.contains(":")) {
                thisIp = forwardedProto + "://" + forwardedHost + ":" + forwardedPort;
            } else {
                thisIp = forwardedProto + "://" + forwardedHost;
            }
        } else {
            // No proxy: use the local URI directly
            int port = exchange.getRequest().getURI().getPort();
            String scheme = exchange.getRequest().getURI().getScheme();
            String host = exchange.getRequest().getURI().getHost();

            // Standard port (80 or 443): leave it out
            if ((scheme.equals("http") && port == 80) || (scheme.equals("https") && port == 443)) {
                thisIp = scheme + "://" + host;
            } else {
                thisIp = scheme + "://" + host + ":" + port;
            }
        }
        return thisIp;
    }

    public static String getClientIp(ServerWebExchange exchange) {
        String tempClientIp = exchange.getRequest().getHeaders().getFirst("X-Forwarded-For");
        //X-Forwarded-For is "client, proxy1, proxy2": the first one is the client
        if (tempClientIp != null) {
            tempClientIp = tempClientIp.split(",")[0].trim();
            if (tempClientIp.isEmpty()) tempClientIp = null;
        }
        if (tempClientIp == null) {
            tempClientIp = exchange.getRequest().getRemoteAddress() != null
                    ? exchange.getRequest().getRemoteAddress().getAddress().getHostAddress()
                    : null;
        }
        //column is varchar(50) (IPv6 max is 45), never lose the log for a weird header
        return tempClientIp != null && tempClientIp.length() > 50 ? tempClientIp.substring(0, 50) : tempClientIp;
    }
}
