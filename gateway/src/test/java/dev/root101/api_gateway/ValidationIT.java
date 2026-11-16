package dev.root101.api_gateway;

import dev.root101.api_gateway.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Stream;

/**
 * Every validation of every request object, one broken field per row, on every endpoint that takes it.
 * Each row pins the `fieldName` and the message a client gets (the output of the annotations and of the route
 * rules), and that it is the only violation. These rows are not mutated (see CONTRIBUTING, mutation testing).
 */
class ValidationIT extends IntegrationTest {

    private static final String BLANK = "Must not be blank";
    private static final String SIZE = "Size must be between 0 and 255";

    private static final String LONG = "x".repeat(256);

    /**
     * A valid route as JSON, so a field can be removed (null) or set to anything
     */
    private static Map<String, Object> validRoute() {
        Map<String, Object> route = new LinkedHashMap<>();
        route.put("name", "valid-" + unique());
        route.put("path", "/valid/**");
        route.put("uri", "http://localhost:8080");
        route.put("rewrite_path", new LinkedHashMap<>(Map.of("replace_from", "/valid/(?<s>.*)", "replace_to", "/${s}")));
        route.put("description", "d");
        return route;
    }

    /**
     * `field` (`rewrite_path.x` for the nested one) set to `value`, `null` = removed
     */
    @SuppressWarnings("unchecked")
    private static Map<String, Object> routeWith(String field, Object value) {
        Map<String, Object> route = validRoute();
        Map<String, Object> target = field.startsWith("rewrite_path.") ? (Map<String, Object>) route.get("rewrite_path") : route;
        String key = field.substring(field.indexOf('.') + 1);
        if (value == null) target.remove(key);
        else target.put(key, value);
        return route;
    }

    static Stream<Arguments> invalidRouteFields() {
        return Stream.of(
                //bean validation
                Arguments.of("name", null, BLANK),
                Arguments.of("name", "", BLANK),
                Arguments.of("name", "   ", BLANK),
                Arguments.of("name", LONG, SIZE),
                Arguments.of("path", null, BLANK),
                Arguments.of("path", "", BLANK),
                Arguments.of("path", "   ", BLANK),
                Arguments.of("path", "/" + LONG, SIZE),
                Arguments.of("uri", null, BLANK),
                Arguments.of("uri", "", BLANK),
                Arguments.of("uri", "not a url", "Must be a valid URL"),
                Arguments.of("uri", "http://" + LONG + ".com", SIZE),
                Arguments.of("rewrite_path.replace_from", null, BLANK),
                Arguments.of("rewrite_path.replace_from", "", BLANK),
                Arguments.of("rewrite_path.replace_from", "/" + LONG, SIZE),
                Arguments.of("rewrite_path.replace_to", null, BLANK),
                Arguments.of("rewrite_path.replace_to", " ", BLANK),
                Arguments.of("rewrite_path.replace_to", "/" + LONG, SIZE),
                //route rules (checked once the fields are valid)
                Arguments.of("path", "valid/**", "Must start with /"),
                Arguments.of("path", "/valid/{x", "Must be a valid path pattern"),
                Arguments.of("uri", "http://localhost:8080/api", "Must not have a path, use rewrite_path to add a prefix"),
                Arguments.of("rewrite_path.replace_from", "/a/(?<x.*)", "Must be a valid regular expression")
        );
    }

    private static final List<String> ROUTE_ENDPOINTS = List.of(
            "POST /routes", "POST /routes/validate", "PUT /routes/{id}", "POST /routes/batch", "PUT /routes"
    );

    static Stream<Arguments> invalidRouteOnEveryEndpoint() {
        return invalidRouteFields().flatMap(row -> ROUTE_ENDPOINTS.stream().map(endpoint -> {
            Object[] values = row.get();
            return Arguments.of(endpoint, values[0], values[1], values[2]);
        }));
    }

    /**
     * The lists (`batch`, `PUT /routes`) name the field with its index: `[0].name`. The id of `PUT /routes/{id}`
     * doesn't exist: the body is checked first. Nothing is saved, so `PUT /routes` replaces nothing.
     */
    @ParameterizedTest(name = "{0} {1}={2}")
    @MethodSource("invalidRouteOnEveryEndpoint")
    void invalidRouteFieldIs422(String endpoint, String field, Object value, String message) {
        String[] parts = endpoint.split(" ");
        boolean list = endpoint.equals("POST /routes/batch") || endpoint.equals("PUT /routes");
        Map<String, Object> route = routeWith(field, value);

        admin(HttpMethod.valueOf(parts[0]), parts[1].replace("{id}", UUID.randomUUID().toString()))
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(list ? List.of(route) : route)
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectHeader().contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .expectBody()
                .jsonPath("$.violations.length()").isEqualTo(1)
                .jsonPath("$.violations[0].fieldName").isEqualTo((list ? "[0]." : "") + field)
                .jsonPath("$.violations[0].message").isEqualTo(message);

        assertNotSaved(route);
    }

    private void assertNotSaved(Map<String, Object> route) {
        Object name = route.get("name");
        if (name instanceof String n && !n.isBlank() && n.length() <= 255) {
            org.assertj.core.api.Assertions.assertThat(routeRepo.findByName(n).block()).isNull();
        }
    }

    /**
     * Every broken field of one route is reported at once
     */
    @Test
    void everyBrokenFieldIsReported() {
        Map<String, Object> route = new HashMap<>(Map.of("rewrite_path", Map.of()));
        admin(HttpMethod.POST, "/routes/validate")
                .bodyValue(route)
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody()
                .jsonPath("$.violations.length()").isEqualTo(5)
                .jsonPath("$.violations[?(@.fieldName == 'name')]").exists()
                .jsonPath("$.violations[?(@.fieldName == 'path')]").exists()
                .jsonPath("$.violations[?(@.fieldName == 'uri')]").exists()
                .jsonPath("$.violations[?(@.fieldName == 'rewrite_path.replace_from')]").exists()
                .jsonPath("$.violations[?(@.fieldName == 'rewrite_path.replace_to')]").exists();
    }

    /**
     * The limits are inclusive, and the optional fields are optional: all of these are valid
     */
    @Test
    void edgeValuesAreValid() {
        String max = "x".repeat(255);
        List<Map<String, Object>> valid = List.of(
                routeWith("name", max),
                routeWith("path", "/" + "x".repeat(254)),
                routeWith("uri", "http://" + "x".repeat(244) + ".com"),
                routeWith("uri", "http://localhost:8080/"),
                routeWith("uri", "https://example.com"),
                routeWith("rewrite_path.replace_from", "/" + "x".repeat(254)),
                routeWith("rewrite_path.replace_to", "/" + "x".repeat(254)),
                routeWith("rewrite_path", null),
                routeWith("description", null),
                routeWith("description", "d".repeat(5000))
        );
        for (Map<String, Object> route : valid) {
            admin(HttpMethod.POST, "/routes/validate").bodyValue(route).exchange().expectStatus().isNoContent();
        }
        //and they are saved as sent
        Map<String, Object> longest = routeWith("description", "d".repeat(5000));
        longest.put("name", max.substring(0, 247) + unique());
        admin(HttpMethod.POST, "/routes").bodyValue(longest).exchange()
                .expectStatus().isCreated()
                .expectBody().jsonPath("$.description").isEqualTo("d".repeat(5000));
    }

    static Stream<Arguments> invalidLogins() {
        return Stream.of(
                Arguments.of("username", null),
                Arguments.of("username", ""),
                Arguments.of("username", "   "),
                Arguments.of("password", null),
                Arguments.of("password", ""),
                Arguments.of("password", "   ")
        );
    }

    /**
     * A login with a blank field is a 422, not a 401. Each row from its own ip: it is still a try of the credentials
     * and the rows together would lock out the others tests' ip.
     */
    @ParameterizedTest(name = "{0}={1}")
    @MethodSource("invalidLogins")
    void invalidLoginFieldIs422(String field, String value) {
        Map<String, Object> login = new HashMap<>(Map.of("username", ADMIN_USERNAME, "password", ADMIN_PASSWORD));
        if (value == null) login.remove(field);
        else login.put(field, value);

        webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                .header("X-Forwarded-For", "validation-" + unique())
                .bodyValue(login)
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectHeader().contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .expectBody()
                .jsonPath("$.violations.length()").isEqualTo(1)
                .jsonPath("$.violations[0].fieldName").isEqualTo(field)
                .jsonPath("$.violations[0].message").isEqualTo(BLANK);
    }
}
