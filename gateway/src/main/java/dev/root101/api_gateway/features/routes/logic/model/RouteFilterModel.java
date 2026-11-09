package dev.root101.api_gateway.features.routes.logic.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

/**
 * An extra gateway filter of the route.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RouteFilterModel {

    //filter name -> number of args. Only header filters: one changing the path would make the final route saved in the http logs wrong
    private static final Map<String, Integer> SUPPORTED = Map.of(
            "AddRequestHeader", 2,
            "AddResponseHeader", 2,
            "SetRequestHeader", 2,
            "SetResponseHeader", 2,
            "RemoveRequestHeader", 1,
            "RemoveResponseHeader", 1
    );

    @NotBlank
    private String name;

    private List<@NotBlank @Size(max = 255) String> args;

    //a route the gateway can't build breaks the refresh of all the routes
    @JsonIgnore
    @AssertTrue(message = "must be a supported filter with the right number of args")
    public boolean isSupported() {
        return name != null && args != null && SUPPORTED.containsKey(name) && SUPPORTED.get(name) == args.size();
    }
}
