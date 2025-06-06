package dev.root101.api_gateway.features.routes.logic.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

/**
 * Model with the config of any route
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RouteConfigResponse {

    /**
     * Unique identified of the route.
     */
    private String id;

    /**
     * Unique 'human-readable' identified of the route.
     */
    private String name;


    /**
     * The path of the route, the one which the gateway will math the request to know where to redirect
     */
    private String path;

    /**
     * The base path of the external service, to whom calls will be redirected
     */
    private String uri;

    /**
     * Object if the path needs to be rewritten. </br>
     * Can be null.
     */
    private RewritePathModel rewritePath;

    /**
     * Additional description of route. </br>
     * Can be null.
     */
    private String description;

    /**
     * When the route was created.
     */
    private OffsetDateTime createdAt;
}
