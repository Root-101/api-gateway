package dev.root101.api_gateway;

import dev.root101.api_gateway.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.TestPropertySource;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * The gateway reached without a trusted proxy (`TRUSTED_PROXIES` doesn't match the test client): an `X-Forwarded-For`
 * sent by the client is never believed. Its own Spring context (different config).
 */
@TestPropertySource(properties = "TRUSTED_PROXIES=10\\.255\\.255\\.255")
class UntrustedProxyIT extends IntegrationTest {

    /**
     * One test: the lockout at the end blocks the test client's ip, also for the admin calls of any other test.
     */
    @Test
    void spoofedForwardedForIsIgnored() {
        String id = unique();
        String spoofed = "203.0.113.9";
        createRoute(rewriteRoute("untrusted-" + id, "untrusted-" + id));

        //the service gets the real client ip, not the spoofed one
        webTestClient.get().uri("/untrusted-%s/forwarded".formatted(id))
                .header("X-Forwarded-For", spoofed)
                .exchange()
                .expectStatus().isOk()
                .expectBody(String.class).value(body -> assertThat(body).doesNotContain(spoofed).contains("|http|"));
        //the log too
        assertThat(awaitLog("/untrusted-" + id).getSourceIp()).isNotEqualTo(spoofed).isNotNull();

        //a new spoofed ip on every try doesn't dodge the lockout (max-failed-attempts=5)
        for (int i = 0; i < 5; i++) {
            webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                    .header("X-Forwarded-For", "198.51.100." + i)
                    .bodyValue(Map.of("username", ADMIN_USERNAME, "password", "wrong-" + i))
                    .exchange()
                    .expectStatus().isUnauthorized();
        }
        webTestClient.post().uri("/%s/auth/login".formatted(ADMIN_PATH))
                .header("X-Forwarded-For", "198.51.100.99")
                .bodyValue(Map.of("username", ADMIN_USERNAME, "password", ADMIN_PASSWORD))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS);
    }
}
