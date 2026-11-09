package dev.root101.api_gateway.features.routes.logic.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.validator.constraints.URL;

import java.util.List;

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
    @Size(max = 255)
    private String name;

    /**
     * The path of the route, the one which the gateway will math the request to know where to redirect
     */
    @NotBlank
    @Size(max = 255)
    private String path;

    /**
     * The base path of the external service, to whom calls will be redirected
     */
    @NotBlank
    @URL
    @Size(max = 255)
    private String uri;

    /**
     * Object if the path needs to be rewritten.
     */
    private RewritePathModel rewritePath;

    /**
     * Additional description of route. </br>
     * Can be null.
     */
    private String description;

    /**
     * Routes with a lower order are evaluated first. </br>
     * Null means 0.
     */
    private Integer order;

    /**
     * Http methods the route accepts. Null or empty means all.
     */
    private List<@Pattern(regexp = "GET|HEAD|POST|PUT|PATCH|DELETE|OPTIONS|TRACE") String> methods;

    /**
     * Host patterns (ant style) the route accepts. Null or empty means all.
     */
    private List<@NotBlank @Size(max = 255) String> hosts;

    /**
     * Headers the request must have.
     */
    private List<RouteHeaderModel> headers;

    /**
     * Extra filters, applied in order after the rewrite.
     */
    private List<RouteFilterModel> filters;

    /**
     * A route with only the basic fields.
     */
    public RouteConfigRequest(String name, String path, String uri, RewritePathModel rewritePath, String description) {
        this(name, path, uri, rewritePath, description, null, null, null, null, null);
    }
}
