package dev.root101.api_gateway;

import dev.root101.api_gateway.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

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
            "POST, /routes/batch",
            "PUT, /routes",
            "PUT, /routes/00000000-0000-0000-0000-000000000001",
            "DELETE, /routes/00000000-0000-0000-0000-000000000001",
            "GET, /http-logs",
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
                .expectHeader().doesNotExist(HttpHeaders.WWW_AUTHENTICATE)
                .expectHeader().contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .expectBody()
                .jsonPath("$.status").isEqualTo(401)
                .jsonPath("$.detail").isEqualTo("Authentication required")
                .jsonPath("$.instance").isEqualTo("/" + ADMIN_PATH + path);
    }

    /**
     * The security layer's errors follow `Accept-Language` too
     */
    @Test
    void unauthorizedInTheLanguageOfTheRequest() {
        webTestClient.get().uri("/%s/routes".formatted(ADMIN_PATH))
                .header(HttpHeaders.ACCEPT_LANGUAGE, "es")
                .exchange()
                .expectStatus().isUnauthorized()
                .expectBody()
                .jsonPath("$.title").isEqualTo("No autorizado")
                .jsonPath("$.detail").isEqualTo("Se requiere autenticación");
    }

    /**
     * Malformed Basic and wrong credentials → 401, both with CORS and a Problem Details body.
     */
    @Test
    void wrongCredentials() {
        webTestClient.get().uri("/%s/routes".formatted(ADMIN_PATH))
                .header(HttpHeaders.ORIGIN, ORIGIN)
                .header(HttpHeaders.AUTHORIZATION, "Basic %%%not-base64%%%")
                .exchange()
                .expectStatus().isUnauthorized()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN)
                .expectBody().jsonPath("$.detail").isEqualTo("Invalid Basic credentials");

        webTestClient.get().uri("/%s/routes".formatted(ADMIN_PATH))
                .header(HttpHeaders.ORIGIN, ORIGIN)
                .header("X-Forwarded-For", "192.0.2." + (int) (Math.random() * 200))
                .header(HttpHeaders.AUTHORIZATION, "Basic " + HttpHeaders.encodeBasicAuth("admin", "wrong", null))
                .exchange()
                .expectStatus().isUnauthorized()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN)
                .expectHeader().contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .expectBody().jsonPath("$.detail").isEqualTo("Wrong username or password");

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
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN)
                .expectBody().jsonPath("$.detail").isEqualTo("Wrong username or password");

        webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                .bodyValue(Map.of("username", "", "password", ""))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody().jsonPath("$.violations.length()").isEqualTo(2);
    }

    private String loginToken(String clientIp) {
        return (String) webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                .header("X-Forwarded-For", clientIp)
                .bodyValue(Map.of("username", ADMIN_USERNAME, "password", ADMIN_PASSWORD))
                .exchange()
                .expectStatus().isOk()
                .expectBody(Map.class).returnResult().getResponseBody().get("access_token");
    }

    @Test
    void loginReturnsAToken() {
        long before = System.currentTimeMillis();
        Map<?, ?> body = webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                .bodyValue(Map.of("username", ADMIN_USERNAME, "password", ADMIN_PASSWORD))
                .exchange()
                .expectStatus().isOk()
                .expectBody(Map.class).returnResult().getResponseBody();

        assertThat((String) body.get("access_token")).isNotEmpty();
        assertThat(body.containsKey("token")).isFalse();
        //8 h, in ms
        assertThat(((Number) body.get("expires_in")).longValue()).isEqualTo(28_800_000L);
        assertThat(((Number) body.get("expire_at")).longValue())
                .isBetween(before + 28_800_000L, System.currentTimeMillis() + 28_800_000L);
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
     * Preflight requests to the admin answer with CORS and no auth, without credentials (the console sends
     * a header, never a cookie). Proxied paths get no CORS from the gateway: that is each service's policy.
     */
    @Test
    void preflightWithoutAuth() {
        webTestClient.options().uri("/%s/routes".formatted(ADMIN_PATH))
                .header(HttpHeaders.ORIGIN, ORIGIN)
                .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "POST")
                .header(HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS, "authorization,content-type")
                .exchange()
                .expectStatus().isOk()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN)
                .expectHeader().exists(HttpHeaders.ACCESS_CONTROL_ALLOW_METHODS)
                .expectHeader().doesNotExist(HttpHeaders.ACCESS_CONTROL_ALLOW_CREDENTIALS);

        webTestClient.options().uri("/any-proxied/path")
                .header(HttpHeaders.ORIGIN, ORIGIN)
                .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "POST")
                .exchange()
                .expectHeader().doesNotExist(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN);
    }

    /**
     * Only a POST to the login is a try of the credentials: a plain OPTIONS (answered 200 by the framework)
     * used to clear the failed count, allowing unlimited guesses.
     */
    @Test
    void optionsToLoginDoesNotResetTheLockout() {
        String ip = "198.51.100." + (int) (Math.random() * 200);
        for (int round = 0; round < 2; round++) {
            for (int i = 0; i < (round == 0 ? 4 : 1); i++) {
                webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                        .header("X-Forwarded-For", ip)
                        .bodyValue(Map.of("username", "admin", "password", "wrong-" + i))
                        .exchange()
                        .expectStatus().isUnauthorized();
            }
            webTestClient.options().uri("/%s/auth/login".formatted(ADMIN_PATH))
                    .header("X-Forwarded-For", ip)
                    .exchange()
                    .expectStatus().isOk();
        }
        webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                .header("X-Forwarded-For", ip)
                .bodyValue(Map.of("username", "admin", "password", "wrong-again"))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS);
    }

    /**
     * A stray Authorization header on the public health check is ignored: it does not count as a try.
     */
    @Test
    void basicOnHealthDoesNotCount() {
        String ip = "198.51.100." + (int) (Math.random() * 200);
        for (int i = 0; i < 8; i++) {
            webTestClient.get().uri("/%s/health".formatted(ADMIN_PATH))
                    .header("X-Forwarded-For", ip)
                    .header(HttpHeaders.AUTHORIZATION, "Basic " + HttpHeaders.encodeBasicAuth("admin", "wrong", null))
                    .exchange()
                    .expectStatus().isOk();
        }
        loginToken(ip);
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
     * After max-failed-attempts (5 in the tests) wrong credentials from the same ip, that ip gets 429 with
     * `Retry-After` on every credentials try (login and Basic), even with the right ones. A valid token and the
     * health check keep working from that ip. Other ips are not affected.
     */
    @Test
    void lockoutAfterFailedAttempts() {
        String attackerIp = "198.51.100." + (int) (Math.random() * 200);
        String token = loginToken(attackerIp);
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
                .expectHeader().value(HttpHeaders.RETRY_AFTER, value -> assertThat(Long.parseLong(value)).isPositive())
                .expectHeader().contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .expectBody().jsonPath("$.detail").value(String.class,
                        detail -> assertThat(detail).matches("Too many failed attempts, try again in \\d+ s"));

        webTestClient.post()
                .uri("/%s/auth/login".formatted(ADMIN_PATH))
                .header("X-Forwarded-For", attackerIp)
                .bodyValue(Map.of("username", ADMIN_USERNAME, "password", ADMIN_PASSWORD))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS)
                .expectHeader().exists(HttpHeaders.RETRY_AFTER);

        //not blocked: a valid token and the health check
        webTestClient.get()
                .uri("/%s/routes".formatted(ADMIN_PATH))
                .header("X-Forwarded-For", attackerIp)
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .exchange()
                .expectStatus().isOk();
        webTestClient.get()
                .uri("/%s/health".formatted(ADMIN_PATH))
                .header("X-Forwarded-For", attackerIp)
                .exchange()
                .expectStatus().isOk();

        admin(HttpMethod.GET, "/routes").exchange().expectStatus().isOk();
    }

    /**
     * Health check: no auth, under the admin path. No actuator.
     */
    @Test
    void healthCheck() {
        webTestClient.get().uri("/%s/health".formatted(ADMIN_PATH)).exchange()
                .expectStatus().isOk()
                .expectBody().json("{\"status\":\"up\"}", org.springframework.test.json.JsonCompareMode.STRICT);

        webTestClient.get().uri("/%s".formatted(ADMIN_PATH)).exchange().expectStatus().isUnauthorized();
        admin(HttpMethod.GET, "/env").exchange().expectStatus().isNotFound();
    }
}
