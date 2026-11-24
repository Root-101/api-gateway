package dev.root101.api_gateway;

import dev.root101.api_gateway.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.web.reactive.result.method.RequestMappingInfo;
import org.springframework.web.reactive.result.method.annotation.RequestMappingHandlerMapping;
import org.springframework.web.util.pattern.PathPattern;

import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Reads every admin endpoint from Spring, so a new one is checked without adding it here. Path variables get a UUID
 * that matches no route: nothing that matters is changed.
 */
class AdminAccessIT extends IntegrationTest {

    //the only admin endpoints that answer without credentials
    private static final Set<String> PUBLIC = Set.of("POST /auth/login", "GET /health");

    @Autowired
    private RequestMappingHandlerMapping handlerMapping;

    /**
     * Every admin endpoint read from Spring.
     * Se espera: the known ones among them, and every one under the admin path.
     */
    @Test
    void scanFindsTheAdminEndpoints() {
        assertThat(endpoints()).contains("GET /routes", "POST /routes", "DELETE /routes/{route-id}", "GET /http-logs",
                "PUT /addons/maintenance", "POST /routes/{route-id}/addons/health-check/run", "POST /auth/login", "GET /health");
    }

    /**
     * Calls every admin endpoint without credentials.
     * Se espera: a `401` on all of them except login and health.
     */
    @Test
    void everyAdminEndpointRequiresAuth() {
        Set<String> open = new TreeSet<>();
        for (String endpoint : endpoints()) {
            String[] parts = endpoint.split(" ", 2);
            int status = webTestClient.method(HttpMethod.valueOf(parts[0]))
                    .uri("/" + ADMIN_PATH + withIds(parts[1]))
                    .header(HttpHeaders.CONTENT_TYPE, "application/json")
                    .header("X-Forwarded-For", uniqueIp())
                    .bodyValue(parts[0].equals("GET") || parts[0].equals("DELETE") ? "" : "{}")
                    .exchange()
                    .returnResult(Void.class).getStatus().value();
            if (status != 401) open.add(endpoint);
        }
        assertThat(open).isEqualTo(new TreeSet<>(PUBLIC));
    }

    /**
     * Calls every admin `GET` with the admin credentials.
     * Se espera: none answers `401` or `403`.
     */
    @Test
    void adminReachesEveryReadEndpoint() {
        List<String> reads = endpoints().stream().filter(endpoint -> endpoint.startsWith("GET ")).toList();
        assertThat(reads).isNotEmpty();
        for (String endpoint : reads) {
            int status = webTestClient.get()
                    .uri("/" + ADMIN_PATH + withIds(endpoint.substring("GET ".length())))
                    .header(HttpHeaders.AUTHORIZATION, adminAuth())
                    .header("X-Forwarded-For", uniqueIp())
                    .exchange()
                    .returnResult(Void.class).getStatus().value();
            assertThat(status).as(endpoint).isNotIn(401, 403);
        }
    }

    /**
     * `METHOD /path` of every endpoint under the admin path, the path without it
     */
    private Set<String> endpoints() {
        String prefix = "/" + ADMIN_PATH;
        Set<String> endpoints = new TreeSet<>();
        for (RequestMappingInfo info : handlerMapping.getHandlerMethods().keySet()) {
            for (PathPattern pattern : info.getPatternsCondition().getPatterns()) {
                String path = pattern.getPatternString();
                if (!path.startsWith(prefix + "/") && !path.equals(prefix)) continue;
                endpoints.addAll(info.getMethodsCondition().getMethods().stream()
                        .map(method -> method.name() + " " + path.substring(prefix.length()))
                        .collect(Collectors.toSet()));
            }
        }
        return endpoints;
    }

    private static String withIds(String path) {
        return path.replaceAll("\\{[^}]+}", "00000000-0000-0000-0000-000000000001");
    }
}
