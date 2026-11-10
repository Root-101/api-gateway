package dev.root101.api_gateway;

import dev.root101.api_gateway.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;

import java.util.Map;

class SecurityIT extends IntegrationTest {

    private static final String ORIGIN = "http://console.example.com";

    /**
     * Every admin endpoint (except login and health) requires auth. 401 without `WWW-Authenticate` (browser popup) and with CORS.
     */
    @ParameterizedTest
    @CsvSource({
            "GET, /routes",
            "GET, /routes/00000000-0000-0000-0000-000000000001",
            "POST, /routes",
            "POST, /routes/multi-add",
            "PUT, /routes",
            "PUT, /routes/00000000-0000-0000-0000-000000000001",
            "DELETE, /routes/00000000-0000-0000-0000-000000000001",
            "POST, /http-log/search",
            "GET, /unknown",
    })
    void adminEndpointsRequireAuth(String method, String path) {
        webTestClient.method(HttpMethod.valueOf(method))
                .uri("/" + ADMIN_PATH + path)
                .header(HttpHeaders.ORIGIN, ORIGIN)
                .header(HttpHeaders.CONTENT_TYPE, "application/json")
                .bodyValue("{}")
                .exchange()
                .expectStatus().isUnauthorized()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN)
                .expectHeader().doesNotExist(HttpHeaders.WWW_AUTHENTICATE);
    }

    /**
     * Malformed Basic → 401 (used to be a 500), wrong credentials → 403, both with CORS.
     */
    @Test
    void wrongCredentials() {
        webTestClient.get().uri("/%s/routes".formatted(ADMIN_PATH))
                .header(HttpHeaders.ORIGIN, ORIGIN)
                .header(HttpHeaders.AUTHORIZATION, "Basic %%%not-base64%%%")
                .exchange()
                .expectStatus().isUnauthorized()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN);

        webTestClient.get().uri("/%s/routes".formatted(ADMIN_PATH))
                .header(HttpHeaders.ORIGIN, ORIGIN)
                .header("X-Forwarded-For", "192.0.2." + (int) (Math.random() * 200))
                .header(HttpHeaders.AUTHORIZATION, "Basic " + HttpHeaders.encodeBasicAuth("admin", "wrong", null))
                .exchange()
                .expectStatus().isForbidden()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN);

        webTestClient.get().uri("/%s/routes".formatted(ADMIN_PATH))
                .header(HttpHeaders.ORIGIN, ORIGIN)
                .header(HttpHeaders.AUTHORIZATION, adminAuth())
                .exchange()
                .expectStatus().isOk()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN);
    }

    @Test
    void login() {
        webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                .header(HttpHeaders.ORIGIN, ORIGIN)
                .bodyValue(Map.of("username", ADMIN_USERNAME, "password", ADMIN_PASSWORD))
                .exchange()
                .expectStatus().isOk()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN);

        webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                .header(HttpHeaders.ORIGIN, ORIGIN)
                .header("X-Forwarded-For", "192.0.2." + (int) (Math.random() * 200))
                .bodyValue(Map.of("username", "admin", "password", "wrong"))
                .exchange()
                .expectStatus().isUnauthorized()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN);

        webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                .bodyValue(Map.of("username", "", "password", ""))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody().jsonPath("$.length()").isEqualTo(2);
    }

    private String loginToken(String clientIp) {
        return (String) webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                .header("X-Forwarded-For", clientIp)
                .bodyValue(Map.of("username", ADMIN_USERNAME, "password", ADMIN_PASSWORD))
                .exchange()
                .expectStatus().isOk()
                .expectBody(Map.class).returnResult().getResponseBody().get("token");
    }

    @Test
    void loginReturnsAToken() {
        webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                .bodyValue(Map.of("username", ADMIN_USERNAME, "password", ADMIN_PASSWORD))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.token").isNotEmpty()
                .jsonPath("$.expires_in").isEqualTo(28800);
    }

    /**
     * The token works on the admin endpoints. A wrong one is a 401 with CORS, doesn't count for the lockout,
     * and doesn't break the endpoints without auth.
     */
    @Test
    void bearerToken() {
        String ip = "203.0.113." + (int) (Math.random() * 200);
        String token = loginToken(ip);

        webTestClient.get().uri("/%s/routes".formatted(ADMIN_PATH))
                .header("X-Forwarded-For", ip)
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .exchange()
                .expectStatus().isOk();

        for (int i = 0; i < 6; i++) {
            webTestClient.get().uri("/%s/routes".formatted(ADMIN_PATH))
                    .header("X-Forwarded-For", ip)
                    .header(HttpHeaders.ORIGIN, ORIGIN)
                    .header(HttpHeaders.AUTHORIZATION, "Bearer wrong-" + i)
                    .exchange()
                    .expectStatus().isUnauthorized()
                    .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN);
        }

        webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                .header("X-Forwarded-For", ip)
                .header(HttpHeaders.AUTHORIZATION, "Bearer expired")
                .bodyValue(Map.of("username", ADMIN_USERNAME, "password", ADMIN_PASSWORD))
                .exchange()
                .expectStatus().isOk();
        webTestClient.get().uri("/%s/health".formatted(ADMIN_PATH))
                .header("X-Forwarded-For", ip)
                .header(HttpHeaders.AUTHORIZATION, "Bearer expired")
                .exchange()
                .expectStatus().isOk();
    }

    /**
     * A successful login resets the failed attempts: a client using only tokens never sends Basic, which also resets them.
     */
    @Test
    void successfulLoginResetsFailedAttempts() {
        String ip = "203.0.113." + (int) (Math.random() * 200);
        for (int round = 0; round < 2; round++) {
            for (int i = 0; i < 4; i++) {
                webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                        .header("X-Forwarded-For", ip)
                        .bodyValue(Map.of("username", "admin", "password", "wrong-" + i))
                        .exchange()
                        .expectStatus().isUnauthorized();
            }
            loginToken(ip);
        }
    }

    /**
     * Preflight requests answer with CORS and no auth, for the admin and for proxied routes.
     */
    @ParameterizedTest
    @CsvSource({"/" + ADMIN_PATH + "/routes", "/any-proxied/path"})
    void preflightWithoutAuth(String path) {
        webTestClient.options().uri(path)
                .header(HttpHeaders.ORIGIN, ORIGIN)
                .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "POST")
                .header(HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS, "authorization,content-type")
                .exchange()
                .expectStatus().isOk()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN)
                .expectHeader().exists(HttpHeaders.ACCESS_CONTROL_ALLOW_METHODS);
    }

    /**
     * A proxied path that contains `_admin` and sends its own Basic auth must reach the upstream untouched.
     */
    @Test
    void proxiedPathContainingAdminIsNotIntercepted() {
        String id = unique();
        createRoute(route("contains-admin-" + id, "svc-" + id));

        String upstreamAuth = "Basic " + HttpHeaders.encodeBasicAuth("other-user", "other-pass", null);
        webTestClient.get()
                .uri("/svc-%s/%s/x".formatted(id, ADMIN_PATH))
                .header(HttpHeaders.AUTHORIZATION, upstreamAuth)
                .exchange()
                .expectStatus().isOk()
                .expectBody(String.class).isEqualTo("/svc-%s/%s/x|%s".formatted(id, ADMIN_PATH, upstreamAuth));
    }

    /**
     * After max-failed-attempts (5 in the tests) wrong credentials from the same ip, that ip gets 429,
     * even with the right credentials. Other ips are not affected.
     */
    @Test
    void lockoutAfterFailedAttempts() {
        String attackerIp = "198.51.100." + (int) (Math.random() * 200);
        for (int i = 0; i < 5; i++) {
            webTestClient.post()
                    .uri("/%s/auth/login".formatted(ADMIN_PATH))
                    .header("X-Forwarded-For", attackerIp)
                    .bodyValue(Map.of("username", "admin", "password", "wrong-" + i))
                    .exchange()
                    .expectStatus().isUnauthorized();
        }

        webTestClient.get()
                .uri("/%s/routes".formatted(ADMIN_PATH))
                .header("X-Forwarded-For", attackerIp)
                .header(HttpHeaders.AUTHORIZATION, adminAuth())
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS)
                .expectBody().jsonPath("$.detail").exists();

        admin(HttpMethod.GET, "/routes").exchange().expectStatus().isOk();
    }

    /**
     * Health check: no auth, under the admin path. The actuator index is not exposed.
     */
    @Test
    void healthCheck() {
        webTestClient.get().uri("/%s/health".formatted(ADMIN_PATH)).exchange()
                .expectStatus().isOk()
                .expectBody().jsonPath("$.status").isEqualTo("UP");

        webTestClient.get().uri("/%s".formatted(ADMIN_PATH)).exchange().expectStatus().isUnauthorized();
        admin(HttpMethod.GET, "/env").exchange().expectStatus().isNotFound();
    }
}
