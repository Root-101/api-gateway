package dev.root101.api_gateway;
/*
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GatewayConfig {

    @Value("${ROUTE_CONFIG}")
    private String rawRouteConfig;

    @Autowired
    private ObjectMapper objectMapper;

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) throws JsonProcessingException {
        List<RouteConfigModel> routesToConfig = objectMapper.readValue(rawRouteConfig, new TypeReference<List<RouteConfigModel>>() {
        });

        RouteLocatorBuilder.Builder routeBuilder = builder.routes();

        for (RouteConfigModel singleRoute : routesToConfig) {
            routeBuilder = routeBuilder.route(singleRoute.getId(), r -> r.path(singleRoute.getPath())
                    .filters(f
                            -> f.rewritePath("%s(?<segment>.*)".formatted(singleRoute.getReplaceFrom()),
                            "%s${segment}".formatted(singleRoute.getReplaceTo())))
                    .uri(singleRoute.getUri()));
        }

        return routeBuilder.build();
    }

}
*/