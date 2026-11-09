package dev.root101.api_gateway.features.routes.utils;

import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import org.junit.jupiter.api.Test;
import org.springframework.cloud.gateway.route.RouteDefinition;

import java.net.URI;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class RouteDefinitionMapperTest {

    private static RouteEntity entity(String from, String to) {
        return new RouteEntity(UUID.fromString("6ac5e18a-8ec4-4ac1-9ff3-169a13cb54dc"), "name", "/svc/**", "http://host:8081", from, to, null, OffsetDateTime.now());
    }

    @Test
    void withoutRewrite() {
        RouteDefinition def = RouteDefinitionMapper.buildDefinition(entity(null, null));

        assertThat(def.getId()).isEqualTo("6ac5e18a-8ec4-4ac1-9ff3-169a13cb54dc");
        assertThat(def.getUri()).isEqualTo(URI.create("http://host:8081"));
        assertThat(def.getPredicates()).hasSize(1);
        assertThat(def.getPredicates().getFirst().getName()).isEqualTo("Path");
        assertThat(def.getPredicates().getFirst().getArgs()).isEqualTo(Map.of("_genkey_0", "/svc/**"));
        assertThat(def.getFilters()).isEmpty();
    }

    @Test
    void halfRewriteIsIgnored() {
        assertThat(RouteDefinitionMapper.buildDefinition(entity("/svc/", null)).getFilters()).isEmpty();
        assertThat(RouteDefinitionMapper.buildDefinition(entity(null, "/")).getFilters()).isEmpty();
    }

    @Test
    void withRewriteArgsInOrder() {
        RouteDefinition def = RouteDefinitionMapper.buildDefinition(entity("/svc/(?<segment>.*)", "/${segment}"));

        assertThat(def.getFilters()).hasSize(1);
        assertThat(def.getFilters().getFirst().getName()).isEqualTo("RewritePath");
        //the RewritePath filter takes the args by position: regexp first, replacement second
        assertThat(List.copyOf(def.getFilters().getFirst().getArgs().values())).containsExactly("/svc/(?<segment>.*)", "/${segment}");
    }
}
