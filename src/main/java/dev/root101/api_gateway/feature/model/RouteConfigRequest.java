package dev.root101.api_gateway.feature.model;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.validator.constraints.URL;

/**
 * Model with the config of any route
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RouteConfigRequest {

    /**
     * Unique 'human-readable' identified of the route.
     */
    @NotBlank
    private String name;

    /**
     * The path of the route, the one which the gateway will math the request to know where to redirect
     */
    @NotBlank
    private String path;

    /**
     * The base path of the external service, to whom calls will be redirected
     */
    @NotBlank
    @URL
    private String uri;

    /**
     * Object if the path needs to be rewritten.
     */
    private RewritePath rewritePath;

    /**
     * Additional description of route. </br>
     * Can be null.
     */
    private String description;
}
