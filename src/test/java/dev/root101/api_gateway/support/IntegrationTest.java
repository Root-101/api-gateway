package dev.root101.api_gateway.support;

import dev.root101.api_gateway.features.http_logs.data.entity.HttpLogEntity;
import dev.root101.api_gateway.features.http_logs.data.repo.HttpLogRepo;
import dev.root101.api_gateway.features.routes.data.repo.RouteRepo;
import dev.root101.api_gateway.features.routes.logic.model.RewritePathModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest;
import io.netty.handler.codec.http.HttpResponseStatus;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webtestclient.autoconfigure.AutoConfigureWebTestClient;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.reactive.server.WebTestClient;
import org.testcontainers.postgresql.PostgreSQLContainer;
import reactor.core.publisher.Mono;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

import java.time.Duration;
import java.util.Map;
import java.util.UUID;
import java.util.function.Predicate;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.awaitility.Awaitility.await;

/**
 * Base of the integration tests (`*IT`): one Postgres container and one fake upstream for the whole test run,
 * and the same Spring context for every class with the same config (Spring caches it).
 * <br/>
 * State is NOT cleaned between tests: each test uses its own unique names/paths ({@link #unique()}),
 * so tests are independent without having to reset the gateway routes.
 */
@AutoConfigureWebTestClient
@SpringBootTest(
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = {
                "app.logs.max-search-size=2",
                "app.admin.max-failed-attempts=5",
                "spring.cloud.gateway.server.webflux.httpclient.response-timeout=1s"
        }
)
public abstract class IntegrationTest {
    public static final String ADMIN_PATH = "_admin";
    public static final String ADMIN_USERNAME = "admin";
    public static final String ADMIN_PASSWORD = "admin123**";

    //singleton container: started once, stopped by testcontainers (ryuk) when the JVM ends
    protected static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:16");

    private static final Pattern STATUS = Pattern.compile("/status/(\\d{3})");

    /**
     * Fake upstream service, by default answers `<uri>|<authorization header>`. Paths containing:
     * <ul>
     *     <li>`/slow`: answers after 3s</li>
     *     <li>`/cors`: also sends its own CORS headers</li>
     *     <li>`/status/{code}`: answers with that status</li>
     *     <li>`/echo`: answers `<method>|<uri>|<X-Test header>|<body>`</li>
     * </ul>
     */
    protected static final DisposableServer UPSTREAM;

    static {
        POSTGRES.start();
        UPSTREAM = HttpServer.create()
                .port(0)
                .handle((req, res) -> {
                    String uri = req.uri();
                    if (uri.contains("/cors")) {
                        res.header(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "http://upstream.example.com");
                        res.header(HttpHeaders.ACCESS_CONTROL_ALLOW_CREDENTIALS, "true");
                    }
                    Matcher status = STATUS.matcher(uri);
                    if (status.find()) {
                        res.status(HttpResponseStatus.valueOf(Integer.parseInt(status.group(1))));
                    }
                    if (uri.contains("/echo")) {
                        return res.sendString(req.receive().aggregate().asString().defaultIfEmpty("")
                                .map(body -> req.method().name() + "|" + uri + "|" + req.requestHeaders().get("X-Test") + "|" + body));
                    }
                    Mono<String> body = Mono.just(uri + "|" + req.requestHeaders().get(HttpHeaders.AUTHORIZATION));
                    return res.sendString(uri.contains("/slow") ? body.delayElement(Duration.ofSeconds(3)) : body);
                })
                .bindNow();
    }

    @DynamicPropertySource
    static void dbProperties(DynamicPropertyRegistry registry) {
        registry.add("DB_HOST", POSTGRES::getHost);
        registry.add("DB_PORT", () -> POSTGRES.getMappedPort(PostgreSQLContainer.POSTGRESQL_PORT));
        registry.add("DB_NAME", POSTGRES::getDatabaseName);
        registry.add("DB_USERNAME", POSTGRES::getUsername);
        registry.add("DB_PASSWORD", POSTGRES::getPassword);
    }

    @Autowired
    protected WebTestClient webTestClient;

    @Autowired
    protected RouteRepo routeRepo;

    @Autowired
    protected HttpLogRepo httpLogRepo;

    protected static String upstreamUrl() {
        return "http://localhost:" + UPSTREAM.port();
    }

    protected static String adminAuth() {
        return "Basic " + HttpHeaders.encodeBasicAuth(ADMIN_USERNAME, ADMIN_PASSWORD, null);
    }

    protected static String unique() {
        return UUID.randomUUID().toString().substring(0, 8);
    }

    /**
     * Route `/{prefix}-{id}/**` → fake upstream, no rewrite
     */
    protected static RouteConfigRequest route(String name, String pathPrefix) {
        return new RouteConfigRequest(name, "/" + pathPrefix + "/**", upstreamUrl(), null, null);
    }

    /**
     * Route `/{prefix}/**` → fake upstream, removing the prefix
     */
    protected static RouteConfigRequest rewriteRoute(String name, String pathPrefix) {
        return new RouteConfigRequest(
                name, "/" + pathPrefix + "/**", upstreamUrl(),
                new RewritePathModel("/" + pathPrefix + "/(?<segment>.*)", "/${segment}"), null
        );
    }

    protected WebTestClient.RequestBodySpec admin(org.springframework.http.HttpMethod method, String path) {
        return webTestClient.method(method)
                .uri("/" + ADMIN_PATH + path)
                .header(HttpHeaders.AUTHORIZATION, adminAuth());
    }

    protected void createRoute(RouteConfigRequest request) {
        admin(org.springframework.http.HttpMethod.POST, "/routes")
                .bodyValue(request)
                .exchange()
                .expectStatus().isOk();
    }

    protected String routeId(String name) {
        return routeRepo.findByName(name).block().getRouteId().toString();
    }

    /**
     * Logs are saved async (in batches every second): wait for the first one matching
     */
    protected HttpLogEntity awaitLog(Predicate<HttpLogEntity> filter) {
        return await().atMost(Duration.ofSeconds(10)).until(
                () -> httpLogRepo.findAll().filter(filter::test).next().block(),
                log -> log != null
        );
    }

    protected HttpLogEntity awaitLog(String pathPart) {
        return awaitLog(log -> log.getPath().contains(pathPart));
    }

    @SuppressWarnings("unchecked")
    protected Map<String, Object> searchLogs(Map<String, Object> body) {
        return admin(org.springframework.http.HttpMethod.POST, "/http-log/search")
                .bodyValue(body)
                .exchange()
                .expectStatus().isOk()
                .expectBody(Map.class)
                .returnResult()
                .getResponseBody();
    }

    protected long totalLogs(Map<String, Object> body) {
        return ((Number) searchLogs(body).get("total_elements")).longValue();
    }
}
