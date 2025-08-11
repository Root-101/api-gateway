package dev.root101.api_gateway.features.http_logs.filter;

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

import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

@Component
public class HttpLogsWebFilter implements WebFilter {

    private static final DateTimeFormatter TIME_FORMATTER =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS").withZone(ZoneId.systemDefault());

    private final RouteUseCase routeUseCase;
    private final String adminBasePath;

    public HttpLogsWebFilter(
            final RouteUseCase routeUseCase,
            @Value("${app.admin.base-path}") String adminBasePath
    ) {
        this.routeUseCase = routeUseCase;
        this.adminBasePath = adminBasePath;
    }

    @Override
    public @NotNull Mono<Void> filter(ServerWebExchange exchange, @NotNull WebFilterChain chain) {
        long startTime = System.currentTimeMillis();

        // 📍 IP del cliente (puede venir de X-Forwarded-For si hay proxy)
        String tempClientIp = exchange.getRequest().getHeaders().getFirst("X-Forwarded-For");
        if (tempClientIp == null) {
            tempClientIp = exchange.getRequest().getRemoteAddress() != null
                    ? exchange.getRequest().getRemoteAddress().getAddress().getHostAddress()
                    : "Desconocida";
        }
        final String clientIp = tempClientIp;

        // 📍 Cliente HTTP (User-Agent)
        String userAgent = exchange.getRequest().getHeaders().getFirst("User-Agent");

        // 📌 Tiempo del servidor
        String serverTime = TIME_FORMATTER.format(Instant.now());

        // 📌 Método HTTP
        HttpMethod httpMethod = exchange.getRequest().getMethod();

        // 📌 Path solicitado
        String originalPath = exchange.getRequest().getPath().toString();
        return chain.filter(exchange)
                .doFinally(signalType -> {
                    long duration = System.currentTimeMillis() - startTime;

                    Route route = exchange.getAttribute(ServerWebExchangeUtils.GATEWAY_ROUTE_ATTR);
                    RouteEntity routeEntity = (route != null) ? routeUseCase.findCachedById(route.getId()) : null;

                    boolean isToAdminPath = originalPath.contains(adminBasePath);
                    String targetService = (route != null) ? route.getUri().toString() : isToAdminPath ? adminBasePath : "No determinado";
                    String targetServiceFull;
                    if (targetService != null && routeEntity != null) {
                        targetServiceFull = (targetService + originalPath).replaceAll(
                                routeEntity.getRewritePathFrom(),
                                routeEntity.getRewritePathTo()
                        );
                    } else if (isToAdminPath) {
                        targetServiceFull = originalPath.replaceAll("/" + adminBasePath, "");
                    } else {
                        targetServiceFull = originalPath;
                    }

                    HttpStatusCode statusCode = exchange.getResponse().getStatusCode();

                    System.out.println("==== 🌐 Petición interna interceptada ====");
                    System.out.println("🕒 Hora servidor: " + serverTime);
                    System.out.println("🌍 IP Cliente: " + clientIp);
                    System.out.println("📱 Cliente HTTP (User-Agent): " + userAgent);
                    System.out.println("🔹 Método HTTP: " + httpMethod);
                    System.out.println("📄 Path: " + originalPath);
                    System.out.println("📡 Ruta: " + route);
                    System.out.println("📡 Ruta Entity: " + routeEntity);
                    System.out.println("📡 Servicio destino: " + targetService);
                    System.out.println("📡 Servicio destino completo: " + targetServiceFull);
                    System.out.println("📥 Código de respuesta: " + (statusCode != null ? statusCode.value() : "Desconocido"));
                    System.out.println("⏱ Tiempo total: " + duration + " ms");
                    System.out.println("================================");
                });
    }
}
