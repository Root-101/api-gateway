package dev.root101.api_gateway.feature.model;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.validator.constraints.URL;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RouteConfigModel {

    @NotBlank
    private String id;

    @NotBlank
    @URL
    private String path;

    @NotBlank
    private String uri;

    private RewritePath rewritePath;

    public record RewritePath(
            @NotBlank
            String replaceFrom,
            @NotBlank
            String replaceTo) {
    }
}
