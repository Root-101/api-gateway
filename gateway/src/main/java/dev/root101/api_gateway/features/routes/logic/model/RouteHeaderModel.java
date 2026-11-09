package dev.root101.api_gateway.features.routes.logic.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

/**
 * A header the request must have to match the route.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RouteHeaderModel {

    @NotBlank
    @Size(max = 255)
    private String name;

    /**
     * What the value must match. </br>
     * Can be null: the header only has to be present.
     */
    @Size(max = 255)
    private String regexp;

    //a route the gateway can't build breaks the refresh of all the routes
    @JsonIgnore
    @AssertTrue(message = "regexp must be a valid regular expression")
    public boolean isValidRegexp() {
        if (regexp == null) return true;
        try {
            Pattern.compile(regexp);
            return true;
        } catch (PatternSyntaxException e) {
            return false;
        }
    }
}
