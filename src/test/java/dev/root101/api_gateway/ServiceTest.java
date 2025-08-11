package dev.root101.api_gateway;

import dev.root101.api_gateway.features.routes.data.repo.RouteRepo;
import dev.root101.api_gateway.features.routes.logic.model.RewritePathModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.web.reactive.server.WebTestClient;
import reactor.test.StepVerifier;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class ServiceTest {
    public static final String ADMIN_PATH = "_admin";
    public static final String ADMIN_USERNAME = "admin";
    public static final String ADMIN_PASSWORD = "admin123**";

    @Autowired
    private WebTestClient webTestClient;

    @Autowired
    private RouteRepo routeRepo;

    @BeforeAll
    public static void startContainer() {
        System.setProperty("DB_HOST", "localhost");
        System.setProperty("DB_PORT", "5432");
        System.setProperty("DB_NAME", "api-gateway");
        System.setProperty("DB_USERNAME", "postgres");
        System.setProperty("DB_PASSWORD", "a123b456**");
    }

    //TODO: validate if the db is clean before test or not
    @BeforeEach
    public void cleanUpBeforeTest() {
        routeRepo.deleteAll().block();
    }

    @AfterEach
    public void cleanUp() {
        routeRepo.deleteAll().block();
    }

    /**
     * Test the save a single route
     */
    @Test
    public void testSaveSingleRoute() {
        // create 'mock' request model
        RouteConfigRequest request = new RouteConfigRequest(
                "abc-name",
                "/abc-service/**",
                "http://localhost:8080",
                new RewritePathModel(
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
                        "Basic " + HttpHeaders.encodeBasicAuth(
                                ADMIN_USERNAME,
                                ADMIN_PASSWORD,
                                null
                        )
                )
                .bodyValue(request)
                .exchange();

        // validate response: 200
        response.expectStatus().isOk();

        // validate if model save oka in db
        StepVerifier.create(routeRepo.findByName(request.getName()))
                .assertNext(routeEntity -> {
                    assertThat(routeEntity).isNotNull();
                    assertThat(routeEntity.getRouteId()).isNotNull();

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
