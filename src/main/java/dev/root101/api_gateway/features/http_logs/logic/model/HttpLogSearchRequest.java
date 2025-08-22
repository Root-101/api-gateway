package dev.root101.api_gateway.features.http_logs.logic.model;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class HttpLogSearchRequest {

    @NotNull
    @PositiveOrZero
    private int page;

    @NotNull
    @Positive
    private int size;

    private String query;

    private String method;

    private String responseCode;

    private String routeId;
}
