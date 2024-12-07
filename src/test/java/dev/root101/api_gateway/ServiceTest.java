package dev.root101.api_gateway;

import dev.root101.api_gateway.feature.data.repo.RouteRepo;
import dev.root101.api_gateway.feature.model.RewritePath;
import dev.root101.api_gateway.feature.model.RouteConfigRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.web.reactive.server.WebTestClient;
import reactor.test.StepVerifier;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class ServiceTest extends BaseTest {

    @Autowired
    private WebTestClient webTestClient;

    @Autowired
    private RouteRepo routeRepo;

    @Test
    void testSaveAndVerifyData() {
        RouteConfigRequest request = new RouteConfigRequest(
                "test-name",
                "/abc-service/**",
                "http://localhost:8081",
                new RewritePath(
                        "/abc-service/",
                        "/"
                ),
                "description"
        );

        // Send request to api
        WebTestClient.ResponseSpec response = webTestClient.post()
                .uri("/%s/routes".formatted(ADMIN_PATH))
                .header(
                        HttpHeaders.AUTHORIZATION,
                        HttpHeaders.encodeBasicAuth(
                                ADMIN_USERNAME,
                                ADMIN_PASSWORD,
                                null
                        )
                )
                .bodyValue(request)
                .exchange();

        // validate response: 200
        response.expectStatus().isOk();

        // Validate if model save oka in db
        StepVerifier.create(routeRepo.findByName(request.getName()))
                .assertNext(routeEntity -> {
                    assertThat(routeEntity).isNotNull();
                    assertThat(routeEntity.getRouteId()).isNotNull();
                    assertThat(routeEntity.getRouteId()).isGreaterThan(0);

                    assertThat(routeEntity.getName()).isEqualTo(request.getName());
                    assertThat(routeEntity.getPath()).isEqualTo(request.getPath());
                    assertThat(routeEntity.getUri()).isEqualTo(request.getUri());

                    assertThat(routeEntity.getRewritePathFrom()).isEqualTo(request.getRewritePath().getReplaceFrom());
                    assertThat(routeEntity.getRewritePathTo()).isEqualTo(request.getRewritePath().getReplaceTo());

                    assertThat(routeEntity.getDescription()).isEqualTo(request.getDescription());
                })
                .verifyComplete();
    }
}
