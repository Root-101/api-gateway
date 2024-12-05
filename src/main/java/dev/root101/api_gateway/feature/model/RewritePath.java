package dev.root101.api_gateway.feature.model;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class RewritePath {
    @NotBlank
    private String replaceFrom;

    @NotBlank
    private String replaceTo;
}
