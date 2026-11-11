package dev.root101.api_gateway;

import dev.root101.api_gateway.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * With a custom `ADMIN_PATH` the admin moves, and `_admin` is just another path (proxied, no auth).
 * Its own Spring context (different config).
 */
@TestPropertySource(properties = "ADMIN_PATH=gw-admin")
class CustomAdminPathIT extends IntegrationTest {

    @Test
    void adminMovesToTheCustomPath() {
        webTestClient.get().uri("/gw-admin/routes").exchange().expectStatus().isUnauthorized();
        webTestClient.get().uri("/gw-admin/routes").header(HttpHeaders.AUTHORIZATION, adminAuth()).exchange().expectStatus().isOk();
        webTestClient.get().uri("/gw-admin/health").exchange().expectStatus().isOk();

        //no longer the admin: no auth, no route → 404
        webTestClient.get().uri("/_admin/routes").exchange().expectStatus().isNotFound();

        String id = unique();
        webTestClient.post().uri("/gw-admin/routes")
                .header(HttpHeaders.AUTHORIZATION, adminAuth())
                .bodyValue(route("old-admin-" + id, "_admin/" + id))
                .exchange()
                .expectStatus().isCreated();
        webTestClient.get().uri("/_admin/%s/x".formatted(id)).exchange()
                .expectStatus().isOk()
                .expectBody(String.class).value(body -> assertThat(body).startsWith("/_admin/%s/x|".formatted(id)));
    }
}
