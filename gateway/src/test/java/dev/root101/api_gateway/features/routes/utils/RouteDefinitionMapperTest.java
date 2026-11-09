package dev.root101.api_gateway.features.routes.utils;

import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import dev.root101.api_gateway.features.routes.logic.model.RouteFilterModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteHeaderModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteRules;
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
        return new RouteEntity(UUID.fromString("6ac5e18a-8ec4-4ac1-9ff3-169a13cb54dc"), "name", "/svc/**", "http://host:8081", from, to, null, OffsetDateTime.now(), 0, "{}");
    }

    @Test
    void orderPredicatesAndFilters() {
        RouteEntity entity = entity("/a", "/b");
        entity.setRouteOrder(-5);
        entity.setRules(RouteRulesJson.toJson(new RouteRules(
                List.of("GET", "POST"),
                List.of("a.com"),
                List.of(new RouteHeaderModel("X-A", "\\d+"), new RouteHeaderModel("X-B", null)),
                List.of(new RouteFilterModel("AddRequestHeader", List.of("X-C", "v")))
        )));

        RouteDefinition def = RouteDefinitionMapper.buildDefinition(entity);

        assertThat(def.getOrder()).isEqualTo(-5);
        assertThat(def.getPredicates()).extracting("name").containsExactly("Path", "Method", "Host", "Header", "Header");
        assertThat(def.getPredicates().get(1).getArgs().values()).containsExactly("GET", "POST");
        assertThat(def.getPredicates().get(3).getArgs().values()).containsExactly("X-A", "\\d+");
        assertThat(def.getPredicates().get(4).getArgs().values()).containsExactly("X-B");
        assertThat(def.getFilters()).extracting("name").containsExactly("RewritePath", "AddRequestHeader");
        assertThat(def.getFilters().get(1).getArgs().values()).containsExactly("X-C", "v");
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
