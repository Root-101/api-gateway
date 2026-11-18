package dev.root101.api_gateway;

import dev.root101.api_gateway.support.IntegrationTest;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.test.web.reactive.server.WebTestClient;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * The CORS add-on: of a route (`/routes/{id}/addons/cors`) and of the gateway (`/addons/cors`). The gateway's is
 * always put back to `*` at the end: the other tests send any origin.
 */
class CorsIT extends IntegrationTest {

    private static final String APP = "https://app.example.com";
    private static final String OTHER = "https://other.example.com";

    private static Map<String, Object> cors(Boolean enabled, List<String> origins, Boolean credentials) {
        Map<String, Object> body = new HashMap<>();
        body.put("enabled", enabled);
        body.put("allowed_origins", origins);
        body.put("allow_credentials", credentials);
        return body;
    }

    private static String routePath(String routeId) {
        return "/routes/%s/addons/cors".formatted(routeId);
    }

    @AfterEach
    void gatewayBackToAny() {
        admin(HttpMethod.PUT, "/addons/cors").bodyValue(cors(true, List.of("*"), false)).exchange().expectStatus().isOk();
    }

    private WebTestClient.ResponseSpec preflight(String path, String origin) {
        return webTestClient.options().uri(path)
                .header(HttpHeaders.ORIGIN, origin)
                .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "POST")
                .header(HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS, "content-type")
                .exchange();
    }

    private WebTestClient.ResponseSpec get(String path, String origin) {
        return webTestClient.get().uri(path).header(HttpHeaders.ORIGIN, origin).exchange();
    }

    /**
     * Seeded on the first start with `*` (no `CORS_ALLOWED_ORIGINS` in the tests), so the gateway's is never `null`
     */
    @Test
    void gatewayCorsIsSeeded() {
        admin(HttpMethod.GET, "/addons").exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.cors.enabled").isEqualTo(true)
                .jsonPath("$.cors.allowed_origins[0]").isEqualTo("*")
                .jsonPath("$.cors.allow_credentials").isEqualTo(false)
                .jsonPath("$.cors.env_var").isEmpty();
    }

    /**
     * A route's own CORS wins over the gateway's: its origins only, with credentials. Off or deleted: the gateway's.
     * Every change is in use right away.
     */
    @Test
    void routeCors() {
        String id = unique();
        String routeId = createRoute(route("cors-r-" + id, "cors-r-" + id));
        String path = "/cors-r-%s/x".formatted(id);
        admin(HttpMethod.GET, "/routes/" + routeId).exchange().expectBody().jsonPath("$.addons.cors").isEmpty();

        admin(HttpMethod.PUT, routePath(routeId))
                .bodyValue(cors(true, List.of(APP, "https://*.example.org"), true))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.enabled").isEqualTo(true)
                .jsonPath("$.allowed_origins.length()").isEqualTo(2)
                .jsonPath("$.allow_credentials").isEqualTo(true);
        admin(HttpMethod.GET, "/routes/" + routeId).exchange().expectBody().jsonPath("$.addons.cors.enabled").isEqualTo(true);

        preflight(path, APP)
                .expectStatus().isOk()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, APP)
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_CREDENTIALS, "true");
        preflight(path, "https://api.example.org").expectStatus().isOk();
        preflight(path, OTHER).expectStatus().isForbidden();
        //the upstream's own CORS (`/cors`) is still replaced
        get("/cors-r-%s/cors".formatted(id), APP)
                .expectStatus().isOk()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, APP)
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_CREDENTIALS, "true");
        get(path, OTHER).expectStatus().isForbidden();

        //off: the gateway's (`*`, no credentials)
        admin(HttpMethod.POST, routePath(routeId) + "/disable").exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.enabled").isEqualTo(false)
                .jsonPath("$.allowed_origins.length()").isEqualTo(2);
        preflight(path, OTHER)
                .expectStatus().isOk()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, OTHER)
                .expectHeader().doesNotExist(HttpHeaders.ACCESS_CONTROL_ALLOW_CREDENTIALS);

        admin(HttpMethod.POST, routePath(routeId) + "/enable").exchange().expectStatus().isOk();
        preflight(path, OTHER).expectStatus().isForbidden();

        admin(HttpMethod.DELETE, routePath(routeId)).exchange().expectStatus().isNoContent();
        admin(HttpMethod.GET, "/routes/" + routeId).exchange().expectBody().jsonPath("$.addons.cors").isEmpty();
        preflight(path, OTHER).expectStatus().isOk();
        //nothing to delete is fine; nothing to enable isn't
        admin(HttpMethod.DELETE, routePath(routeId)).exchange().expectStatus().isNoContent();
        admin(HttpMethod.POST, routePath(routeId) + "/enable").exchange()
                .expectStatus().isNotFound()
                .expectBody().jsonPath("$.detail").isEqualTo("The route has no CORS configured: " + routeId);
    }

    /**
     * The gateway's covers the admin API (also its `401`) and every route without its own, without a restart
     */
    @Test
    void gatewayCors() {
        String id = unique();
        createRoute(route("cors-g-" + id, "cors-g-" + id));
        String routeWithOwn = createRoute(route("cors-o-" + id, "cors-o-" + id));
        admin(HttpMethod.PUT, routePath(routeWithOwn)).bodyValue(cors(true, List.of(OTHER), false)).exchange().expectStatus().isOk();

        admin(HttpMethod.PUT, "/addons/cors")
                .header(HttpHeaders.ORIGIN, APP)
                .bodyValue(cors(true, List.of(APP), null))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.allowed_origins[0]").isEqualTo(APP)
                .jsonPath("$.allow_credentials").isEmpty();

        preflight("/cors-g-%s/x".formatted(id), APP).expectStatus().isOk()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, APP);
        preflight("/cors-g-%s/x".formatted(id), OTHER).expectStatus().isForbidden();
        //a route with its own keeps it
        preflight("/cors-o-%s/x".formatted(id), OTHER).expectStatus().isOk();
        preflight("/cors-o-%s/x".formatted(id), APP).expectStatus().isForbidden();

        //the admin API: allowed, and the 401 carries the headers; another origin is rejected
        preflight("/%s/routes".formatted(ADMIN_PATH), APP).expectStatus().isOk()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, APP)
                .expectHeader().doesNotExist(HttpHeaders.ACCESS_CONTROL_ALLOW_CREDENTIALS);
        get("/%s/routes".formatted(ADMIN_PATH), APP).expectStatus().isUnauthorized()
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, APP);
        preflight("/%s/routes".formatted(ADMIN_PATH), OTHER).expectStatus().isForbidden();
    }

    /**
     * Maintenance's `503` and rate limit's `429` end the request after the route's CORS was applied
     */
    @Test
    void earlyAnswersCarryCors() {
        String id = unique();
        String routeId = createRoute(route("cors-e-" + id, "cors-e-" + id));
        admin(HttpMethod.PUT, routePath(routeId)).bodyValue(cors(true, List.of(APP), false)).exchange().expectStatus().isOk();

        admin(HttpMethod.PUT, "/routes/%s/addons/maintenance".formatted(routeId))
                .bodyValue(Map.of("enabled", true)).exchange().expectStatus().isOk();
        get("/cors-e-%s/x".formatted(id), APP)
                .expectStatus().isEqualTo(HttpStatus.SERVICE_UNAVAILABLE)
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, APP);
        admin(HttpMethod.DELETE, "/routes/%s/addons/maintenance".formatted(routeId)).exchange().expectStatus().isNoContent();

        admin(HttpMethod.PUT, "/routes/%s/addons/rate-limit".formatted(routeId))
                .bodyValue(Map.of("enabled", true, "limit", 1, "period", "hour")).exchange().expectStatus().isOk();
        String ip = "10.77.%d.%d".formatted((int) (Math.random() * 250), (int) (Math.random() * 250));
        webTestClient.get().uri("/cors-e-%s/1".formatted(id)).header(HttpHeaders.ORIGIN, APP).header("X-Forwarded-For", ip)
                .exchange().expectStatus().isOk();
        webTestClient.get().uri("/cors-e-%s/2".formatted(id)).header(HttpHeaders.ORIGIN, APP).header("X-Forwarded-For", ip)
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS)
                .expectHeader().valueEquals(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, APP);
    }

    /**
     * The rules: each one a `400` with its message, nothing saved. Bad shapes are the usual `422`.
     */
    @Test
    void invalidCors() {
        String routeId = createRoute(route("cors-i-" + unique(), "cors-i-" + unique()));

        admin(HttpMethod.PUT, routePath(routeId)).bodyValue(cors(true, List.of("*"), true)).exchange()
                .expectStatus().isBadRequest()
                .expectBody().jsonPath("$.detail").isEqualTo("Credentials can't be allowed with an origin that matches every origin (*)");
        admin(HttpMethod.PUT, routePath(routeId)).bodyValue(cors(true, List.of(APP, "https://*"), true)).exchange()
                .expectStatus().isBadRequest();
        admin(HttpMethod.GET, "/routes/" + routeId).exchange().expectBody().jsonPath("$.addons.cors").isEmpty();

        admin(HttpMethod.PUT, "/addons/cors").bodyValue(cors(false, List.of("*"), false)).exchange()
                .expectStatus().isBadRequest()
                .expectBody().jsonPath("$.detail").isEqualTo("The gateway's CORS can't be turned off: the console couldn't reach the admin API");
        admin(HttpMethod.PUT, "/addons/cors").bodyValue(cors(true, List.of(APP), true)).exchange()
                .expectStatus().isBadRequest()
                .expectBody().jsonPath("$.detail").isEqualTo("The gateway's CORS can't allow credentials: the admin API uses a token, not cookies");
        //the browser that sends it would be locked out; without a browser (no Origin) it is fine
        admin(HttpMethod.PUT, "/addons/cors").header(HttpHeaders.ORIGIN, OTHER).bodyValue(cors(true, List.of(APP), false)).exchange()
                .expectStatus().isBadRequest()
                .expectBody().jsonPath("$.detail").isEqualTo("These origins would lock out this console (%s): add it to the list".formatted(OTHER));
        admin(HttpMethod.DELETE, "/addons/cors").exchange().expectStatus().isEqualTo(HttpStatus.METHOD_NOT_ALLOWED);
        admin(HttpMethod.POST, "/addons/cors/disable").exchange().expectStatus().isNotFound();
        admin(HttpMethod.GET, "/addons").exchange().expectBody().jsonPath("$.cors.allowed_origins[0]").isEqualTo("*");

        admin(HttpMethod.PUT, routePath(routeId)).bodyValue(cors(null, List.of(), null)).exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody()
                .jsonPath("$.violations[?(@.fieldName == 'enabled')]").exists()
                .jsonPath("$.violations[?(@.fieldName == 'allowed_origins')]").exists();
        admin(HttpMethod.PUT, routePath(routeId)).bodyValue(cors(true, List.of(APP, "https://app.com/path"), false)).exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody()
                .jsonPath("$.violations[0].fieldName").isEqualTo("allowed_origins[1]")
                .jsonPath("$.violations[0].message").isEqualTo("Must be * or an origin like https://app.com or https://*.example.com, without a path");
    }
}
