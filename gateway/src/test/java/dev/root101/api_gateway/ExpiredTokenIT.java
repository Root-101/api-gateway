package dev.root101.api_gateway;

import dev.root101.api_gateway.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.TestPropertySource;

import java.util.Map;

/**
 * A token past its `ADMIN_TOKEN_MINUTES` is rejected like a wrong one. With `0` minutes every token is born
 * expired, so the test doesn't wait. Its own Spring context (different config).
 */
@TestPropertySource(properties = "ADMIN_TOKEN_MINUTES=0")
class ExpiredTokenIT extends IntegrationTest {

    @Test
    void expiredTokenIs401() {
        String token = (String) webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                .bodyValue(Map.of("username", ADMIN_USERNAME, "password", ADMIN_PASSWORD))
                .exchange()
                .expectStatus().isOk()
                .expectBody(Map.class).returnResult().getResponseBody().get("access_token");

        webTestClient.get().uri("/%s/routes".formatted(ADMIN_PATH))
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .exchange()
                .expectStatus().isUnauthorized()
                .expectBody().jsonPath("$.detail").isEqualTo("Authentication required");
    }
}
