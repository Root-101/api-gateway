package dev.root101.api_gateway.features.http_logs.logic.usecase;

import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.time.OffsetDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class HttpLogUseCaseImplTest {

    @ParameterizedTest
    @CsvSource(nullValues = "null", value = {
            //uri, from, to, requested path, expected
            "http://host, null, null, /svc/a/b, http://host/svc/a/b",
            "http://host, /svc/, null, /svc/a/b, http://host/svc/a/b",
            "http://host, /svc/(?<segment>.*), /${segment}, /svc/a/b, http://host/a/b",
            "http://host, /svc/(?<segment>.*), /$\\{segment}, /svc/a/b, http://host/a/b",
            "http://host/, /svc/(?<segment>.*), ${segment}, /svc/a/b, http://host/a/b",
            "http://host:8080, /svc, /api, /svc/x, http://host:8080/api/x",
            "http://host, /other/(?<segment>.*), /${segment}, /svc/a, http://host/svc/a",
    })
    void buildFinalRoute(String uri, String from, String to, String path, String expected) {
        RouteEntity route = new RouteEntity(UUID.randomUUID(), "n", "/svc/**", uri, from, to, null, OffsetDateTime.now());

        assertThat(HttpLogUseCaseImpl.buildFinalRoute(route, path)).isEqualTo(expected);
    }
}
